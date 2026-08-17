import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/domain/camera_image_converter.dart';

/// Tela que escaneia placas.
///
/// Em dispositivos móveis escaneia em tempo real a partir do feed da câmera,
/// processando os quadros com debounce. No navegador (web) tira/abre uma foto
/// e executa o OCR na imagem, devolvendo o valor via `Navigator.pop`.
class PlateScannerPage extends StatefulWidget {
  const PlateScannerPage({super.key});

  /// Intervalo mínimo entre dois processamentos de OCR (em milissegundos).
  static const processEveryMs = 400;

  @override
  State<PlateScannerPage> createState() => _PlateScannerPageState();
}

class _PlateScannerPageState extends State<PlateScannerPage> {
  final ImagePicker _imagePicker = ImagePicker();

  CameraController? _controller;
  bool _processing = false;
  bool _cameraReady = false;
  String? _error;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _closed = false;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      unawaited(_pickPhoto());
    } else {
      _initCamera();
    }
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
      });

      final plate =
          await ServiceLocator.instance.plateRecognition.recognizeBytes(bytes);
      if (!mounted) return;
      setState(() => _processing = false);
      if (plate != null) {
        Navigator.of(context).pop(plate);
      } else {
        setState(() => _error = 'Nenhuma placa reconhecida. Tente outra foto.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _processing = false;
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
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      await controller.startImageStream(_onFrame);
      if (!mounted) return;
      setState(() => _cameraReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível acessar a câmera.');
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
    try {
      final rotation = _rotationForImage(image);
      final inputImage = CameraImageConverter.convert(image, rotation);
      final plate =
          await ServiceLocator.instance.plateRecognition.processInputImage(inputImage);
      if (plate != null && !_closed) {
        _closed = true;
        if (mounted) Navigator.of(context).pop(plate);
      }
    } catch (_) {
      // ignora falha pontual de um quadro; segue escaneando.
    } finally {
      _processing = false;
    }
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
            if (!kIsWeb) const Positioned.fill(child: _ScannerOverlay()),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (kIsWeb)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: _processing
                      ? const Column(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'Processando imagem...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Tirar foto da placa'),
                        ),
                ),
              )
            else
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: _processing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Aponte a câmera para a placa',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (kIsWeb) return _buildWebBody();
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
