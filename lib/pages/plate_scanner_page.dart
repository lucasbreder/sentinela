import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/domain/camera_image_converter.dart';
import 'package:sentinela/domain/plate_color_detector.dart';
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
      // Infere o tipo de placa pela cor da faixa superior (Mercosul tem banda
      // azul) para restringir o padrão de extração e reduzir as alternativas.
      final type = PlateColorDetector.detectNv21(
        roi.bytes,
        roi.width,
        roi.height,
      );
      final result = await ServiceLocator.instance.plateRecognition
          .recognizeNv21(
        roi.bytes,
        roi.width,
        roi.height,
        recognizer: recognizer,
        rotation: rotation,
        type: type,
      );
      if (result.candidates.isNotEmpty) unawaited(_presentCandidates(result));
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

  /// Confirma a placa: se houver apenas uma leitura, finaliza direto. Se a
  /// leitura for ambígua (ex.: zero cortado `0/6`), só abre o diálogo de opções
  /// quando a confiança do OCR for baixa — com alta confiança, confia na
  /// primeira leitura.
  Future<void> _presentCandidates(PlateReadingResult result) async {
    if (_closed) return;
    final unique = result.candidates.toSet().toList();
    if (unique.length == 1) {
      _finish(unique.first);
      return;
    }
    if (result.confidence >= _confidenceThreshold) {
      _finish(unique.first);
      return;
    }
    await _controller?.stopImageStream();
    if (!mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => _PlateChoiceDialog(
        candidates: unique.take(_maxChoices).toList(),
        hiddenCount: unique.length > _maxChoices ? unique.length - _maxChoices : 0,
      ),
    );
    if (_closed) return;
    if (picked != null) {
      _finish(picked);
      return;
    }
    // usuário cancelou: volta a escanear.
    setState(() {
      _cameraReady = false;
      _error = null;
    });
    unawaited(_initCamera());
  }

  /// Quantidade máxima de alternativas exibidas no diálogo de confirmação.
  static const int _maxChoices = 4;

  /// Confiança do OCR (0..1) a partir da qual uma leitura é considerada segura
  /// e não abre o diálogo de confirmação.
  static const double _confidenceThreshold = 0.7;

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
    return const Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Aponte a câmera para a placa',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
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

/// Diálogo que apresenta leituras alternativas da placa (ex.: `0`/`6`) para o
/// usuário confirmar a correta. As opções são limitadas e roláveis para não
/// quebrar o layout em placas muito ambíguas.
class _PlateChoiceDialog extends StatelessWidget {
  const _PlateChoiceDialog({required this.candidates, this.hiddenCount = 0});

  final List<String> candidates;
  final int hiddenCount;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirme a placa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final plate in candidates)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(plate),
                    child: Text(plate, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Mais $hiddenCount opção(ões) não exibida(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}