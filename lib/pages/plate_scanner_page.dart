import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/domain/camera_image_converter.dart';
import 'package:sentinela/domain/plate_recognition_service.dart';

/// Tela que escaneia placas.
///
/// Escaneia em tempo real a partir do feed da câmera com o ML Kit (on-device),
/// processando os quadros com debounce e recorte (ROI) como reforço de
/// precisão. Oferece também uma captura de foto como alternativa, devolvendo
/// o valor via `Navigator.pop`.
class PlateScannerPage extends StatefulWidget {
  const PlateScannerPage({super.key});

  /// Intervalo mínimo entre dois processamentos de OCR (em milissegundos).
  static const processEveryMs = 250;

  @override
  State<PlateScannerPage> createState() => _PlateScannerPageState();
}

class _PlateScannerPageState extends State<PlateScannerPage> {
  CameraController? _controller;
  TextRecognizer? _recognizer;
  bool _processing = false;
  bool _cameraReady = false;
  String? _error;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _closed = false;
  Uint8List? _photo;
  String? _ocrStatus;
  double? _ocrProgress;

  @override
  void initState() {
    super.initState();
    _initCamera();
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
        ResolutionPreset.medium,
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

  /// Processa cada quadro recortando a faixa central (onde a moldura-guia
  /// orienta a placa) antes do OCR. Recortar deixa a placa maior e o OCR mais
  /// rápido e preciso; confirma na primeira leitura válida.
  Future<void> _processFrame(CameraImage image) async {
    final recognizer = _recognizer;
    if (recognizer == null) return;
    try {
      final rotation = _rotationForImage(image);
      final rect =
          PlateRecognitionService.centerCropRect(image.width, image.height);
      if (rect == null) return;
      final roi = CameraImageConverter.cropToRoi(image, rect);
      final plate = await ServiceLocator.instance.plateRecognition
          .recognizeNv21(
        roi.bytes,
        roi.width,
        roi.height,
        recognizer: recognizer,
        rotation: rotation,
      );
      if (plate != null) _finish(plate);
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
            Positioned.fill(child: _buildPreview()),
            const Positioned.fill(child: _ScannerOverlay()),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            _buildMobileFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
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