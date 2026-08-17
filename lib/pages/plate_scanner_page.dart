import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/domain/camera_image_converter.dart';
import 'package:sentinela/domain/web_ocr.dart';

/// Tela que escaneia placas.
///
/// Em dispositivos móveis escaneia em tempo real a partir do feed da câmera,
/// processando os quadros com debounce e aplicando recorte (ROI) como reforço
/// de precisão. Oferece também uma captura de foto como alternativa. No
/// navegador (web) tira/abre uma foto e executa o OCR, devolvendo o valor via
/// `Navigator.pop`.
class PlateScannerPage extends StatefulWidget {
  const PlateScannerPage({super.key});

  /// Intervalo mínimo entre dois processamentos de OCR (em milissegundos).
  static const processEveryMs = 400;

  /// Intervalo mínimo entre duas passadas de recorte (ROI) no streaming.
  static const roiEveryMs = 2000;

  @override
  State<PlateScannerPage> createState() => _PlateScannerPageState();
}

class _PlateScannerPageState extends State<PlateScannerPage> {
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _controller;
  TextRecognizer? _recognizer;
  bool _processing = false;
  bool _cameraReady = false;
  final bool _webMode = kIsWeb;
  String? _error;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastRoiAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _closed = false;
  Uint8List? _photo;
  String? _ocrStatus;
  double? _ocrProgress;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      unawaited(_prepareWebOcr());
    } else {
      _initCamera();
    }
  }

  Future<void> _prepareWebOcr() async {
    try {
      await ensureTesseractReady(onStatus: _setOcrStatus);
      if (_closed) return;
      unawaited(_pickPhoto());
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível carregar o OCR.');
    }
  }

  void _setOcrStatus(String? status) {
    if (!mounted) return;
    setState(() => _ocrStatus = status);
  }

  Future<void> _pickPhoto() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _processing = true;
        _error = null;
        _ocrStatus = 'Processando imagem...';
        _ocrProgress = 0;
      });

      final plate =
          await ServiceLocator.instance.plateRecognition.recognizeBytes(
        bytes,
        onProgress: (progress, status) {
          if (!mounted) return;
          setState(() {
            _ocrProgress = progress;
            if (status != null) _ocrStatus = status;
          });
        },
      );
      if (!mounted) return;
      setState(() => _processing = false);
      if (plate != null) {
        Navigator.of(context).pop(plate);
      } else {
        setState(() {
          _error = 'Nenhuma placa reconhecida. Tente outra foto.';
          _ocrStatus = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _ocrStatus = null;
        _error = 'Não foi possível processar a foto.';
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
      await controller.initialize();
      await controller.startImageStream(_onFrame);
      if (!mounted) return;
      setState(() {
        _cameraReady = true;
        _error = null;
        _processing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível acessar a câmera.');
    }
  }

  /// Captura uma foto de alta resolução como alternativa ao streaming.
  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.stopImageStream();
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _processing = true;
        _error = null;
        _ocrStatus = 'Processando imagem...';
        _ocrProgress = 0;
      });
      final plate =
          await ServiceLocator.instance.plateRecognition.recognizeBytes(bytes);
      if (!mounted) return;
      setState(() => _processing = false);
      if (plate != null) {
        _finish(plate);
      } else {
        setState(() {
          _error = 'Nenhuma placa reconhecida. Tente novamente.';
          _ocrStatus = null;
        });
        // retorna ao streaming para nova tentativa
        unawaited(_initCamera());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Não foi possível processar a foto.';
      });
      unawaited(_initCamera());
    }
  }

  /// Recebe cada quadro do feed. Processa com debounce para não estourar a CPU.
  void _onFrame(CameraImage image) {
    if (_processing || _closed) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessedAt).inMilliseconds <
        PlateScannerPage.processEveryMs) {
      return;
    }
    _lastProcessedAt = now;
    _processing = true;
    unawaited(_processFrame(image));
  }

  Future<void> _processFrame(CameraImage image) async {
    final recognizer = _recognizer;
    if (recognizer == null) return;
    try {
      final rotation = _rotationForImage(image);
      final inputImage = CameraImageConverter.convert(image, rotation);
      final plate =
          await ServiceLocator.instance.plateRecognition.processInputImage(
        inputImage,
        recognizer: recognizer,
      );
      if (plate != null) {
        _finish(plate);
        return;
      }

      // Reforço de precisão: converte o quadro e re-OCR a região da placa.
      final now = DateTime.now();
      if (now.difference(_lastRoiAt).inMilliseconds >=
          PlateScannerPage.roiEveryMs) {
        _lastRoiAt = now;
        final frame = CameraImageConverter.toRgba(image);
        final roiPlate = await ServiceLocator.instance.plateRecognition
            .recognizeRgba(
          frame.bytes,
          frame.width,
          frame.height,
          recognizer: recognizer,
        );
        if (roiPlate != null) {
          _finish(roiPlate);
          return;
        }
      }
    } catch (_) {
      // ignora falha pontual de um quadro; segue escaneando.
    } finally {
      _processing = false;
    }
  }

  void _finish(String plate) {
    if (_closed) return;
    _closed = true;
    if (mounted) Navigator.of(context).pop(plate);
  }

  /// Converte a orientação do sensor da câmera para o [InputImageRotation].
  InputImageRotation _rotationForImage(CameraImage image) {
    final sensorOrientation =
        _controller?.description.sensorOrientation ?? 90;
    return _sensorOrientationToRotation(sensorOrientation);
  }

  InputImageRotation _sensorOrientationToRotation(int degrees) {
    return switch (degrees) {
      90 => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation0deg,
    };
  }

  @override
  void dispose() {
    _closed = true;
    _controller?.stopImageStream();
    _controller?.dispose();
    unawaited(_recognizer?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            if (!_webMode) const Positioned.fill(child: _ScannerOverlay()),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_webMode)
              _buildWebFooter()
            else
              _buildMobileFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_webMode) return _buildWebBody();
    return _buildMobilePreview();
  }

  Widget _buildWebBody() {
    final photo = _photo;
    if (photo != null) {
      return Image.memory(photo, fit: BoxFit.contain);
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildMobilePreview() {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    }
    if (!_cameraReady || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return CameraPreview(_controller!);
  }

  Widget _buildWebFooter() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: _processing
            ? Column(
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    _ocrStatus ?? 'Processando imagem...',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (_ocrProgress != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 180,
                      child: LinearProgressIndicator(
                        value: _ocrProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ],
                ],
              )
            : ElevatedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Tirar foto da placa'),
              ),
      ),
    );
  }

  Widget _buildMobileFooter() {
    final photo = _photo;
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_processing && photo != null)
            Text(
              _ocrStatus ?? 'Processando imagem...',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          const SizedBox(height: 8),
          Center(
            child: _processing && photo != null
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Aponte a câmera para a placa',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _capturePhoto,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Capturar foto'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Sobreposição visual com um retângulo-guia central para alinhar a placa.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final guideWidth = constraints.maxWidth * 0.8;
        final guideHeight = guideWidth * 0.4;
        return Center(
          child: Container(
            width: guideWidth,
            height: guideHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}