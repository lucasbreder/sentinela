import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:sentinela/domain/image_preprocessor.dart';

/// Resultado do reconhecimento de uma placa.
class PlateRecognition {
  const PlateRecognition(this.plate);

  final String plate;
}

/// Lógica pura de extração de placa a partir de um texto reconhecido (OCR).
/// Mantida separada do reconhecimento para permitir teste unitário.
///
/// O texto reconhecido pelo OCR raramente é a placa pura: costuma vir com
/// minúsculas, espaços, texto ao redor e confusões entre letras e números
/// (0/O, 1/I/L, 5/S, 2/Z, 8/B, 6/G). Este extrator normaliza e procura o
/// padrão de placa brasileira (Mercosul `ABC1D23` ou antiga `ABC1234`) em
/// qualquer posição do texto.
abstract final class PlateExtractor {
  /// Placa Mercosul: 3 letras + 1 dígito + 1 letra + 2 dígitos.
  static final RegExp _mercosul = RegExp(r'^[A-Z]{3}\d[A-Z]\d{2}$');
  /// Placa antiga: 3 letras + 4 dígitos.
  static final RegExp _old = RegExp(r'^[A-Z]{3}\d{4}$');

  static String? extract(String rawText) {
    if (rawText.isEmpty) return null;
    final text = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (text.length < 7) return null;

    final candidates = <String>{};
    for (var i = 0; i <= text.length - 7; i++) {
      final window = text.substring(i, i + 7);
      final old = _normalize(window, letterPositions: {0, 1, 2});
      if (_old.hasMatch(old)) {
        candidates.add(old);
      }
      final mercosul = _normalize(window, letterPositions: {0, 1, 2, 4});
      if (_mercosul.hasMatch(mercosul)) {
        candidates.add(mercosul);
      }
    }
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  /// Corrige confusões comuns do OCR posicionando cada caractere conforme o
  /// padrão da placa (posições de letra ou de dígito).
  static String _normalize(String candidate, {required Set<int> letterPositions}) {
    final chars = candidate.split('');
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (letterPositions.contains(i)) {
        chars[i] = switch (c) {
          '0' => 'O',
          '1' => 'I',
          '5' => 'S',
          '2' => 'Z',
          '8' => 'B',
          '6' => 'G',
          _ => c,
        };
      } else {
        chars[i] = switch (c) {
          'O' => '0',
          'I' || 'L' => '1',
          'S' => '5',
          'Z' => '2',
          'B' => '8',
          'G' => '6',
          _ => c,
        };
      }
    }
    return chars.join();
  }
}

/// Bloco de texto reconhecido com sua posição (usado para localizar a placa).
class PlateTextBlock {
  const PlateTextBlock(this.text, this.rect);

  final String text;
  final Rect rect;
}

class PlateRecognitionService {
  /// Dimensão máxima (lado maior) para reduzir fotos grandes antes do OCR.
  /// Fotos de câmera chegam a 12+ MP; processar em tamanho cheio gasta memória
  /// e deixa o OCR lento.
  static const int _maxOcrDimension = 1600;

  /// Quantos blocos candidatos a recortar e reprocessar em alta qualidade.
  static const int _maxRoiCandidates = 3;

  /// Reconhece e devolve a primeira placa válida em uma imagem.
  Future<String?> recognize(String imagePath) async {
    final decoded = img.decodeImage(File(imagePath).readAsBytesSync());
    if (decoded == null) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await _recognizeOnImage(decoded, recognizer);
    } finally {
      unawaited(recognizer.close());
    }
  }

  /// Reconhece e devolve a primeira placa válida a partir dos bytes de uma
  /// imagem, pelo ML Kit com recorte da região da placa (ROI).
  Future<String?> recognizeBytes(
    Uint8List imageBytes, {
    void Function(double? progress, String? status)? onProgress,
  }) async {
    final decoded = _decodeForOcr(imageBytes);
    if (decoded == null) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await _recognizeOnImage(decoded, recognizer);
    } finally {
      unawaited(recognizer.close());
    }
  }

  /// Decodifica a imagem e reduz fotos muito grandes, preservando a
  /// proporção, para evitar uso excessivo de memória e OCR lento.
  img.Image? _decodeForOcr(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return null;
    final maxDim = decoded.width > decoded.height ? decoded.width : decoded.height;
    if (maxDim <= _maxOcrDimension) return decoded;
    final scale = _maxOcrDimension / maxDim;
    return img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  /// Recorte (ROI) da faixa central da foto, onde a moldura-guia orienta a
  /// placa. Reduz a área antes do OCR e permite ampliar a placa no passo
  /// seguinte, melhorando a leitura dos caracteres.
  static Rect? centerCropRect(int width, int height) {
    final x = (width * 0.10).round();
    final right = (width * 0.90).round();
    final y = (height * 0.30).round();
    final bottom = (height * 0.70).round();
    if (right - x < 16 || bottom - y < 16) return null;
    return Rect.fromLTRB(
      x.toDouble(),
      y.toDouble(),
      right.toDouble(),
      bottom.toDouble(),
    );
  }

  /// Executa o OCR completo com recorte (ROI) sobre uma imagem decodificada.
  Future<String?> _recognizeOnImage(
    img.Image decoded,
    TextRecognizer recognizer,
  ) async {
    final processed = ImagePreprocessor.process(decoded);

    // 1ª passada: tenta extrair a placa direto do texto dos blocos.
    final blocks = await _extractBlocks(processed, recognizer);
    for (final block in blocks) {
      final plate = PlateExtractor.extract(block.text);
      if (plate != null) return plate;
    }

    // 2ª passada (ROI): recorta os blocos candidatos, amplia e relê em alta
    // qualidade. Melhora a precisão quando a placa é pequena ou confusa.
    final candidates = _rankCandidates(blocks);
    for (final candidate in candidates) {
      final crop = _cropBlock(processed, candidate.rect);
      if (crop == null) continue;
      final upscaled = ImagePreprocessor.upscale(crop);
      final cropBlocks = await _extractBlocks(upscaled, recognizer);
      for (final cb in cropBlocks) {
        final plate = PlateExtractor.extract(cb.text);
        if (plate != null) return plate;
      }
    }
    return null;
  }

  /// Reconhece a placa a partir de um recorte de quadro em NV21 (já reduzido
  /// pela ROI), reutilizando o [recognizer] do streaming para não recriar o
  /// reconhecedor a cada quadro. É o caminho rápido de leitura em tempo real.
  Future<String?> recognizeNv21(
    Uint8List nv21,
    int width,
    int height, {
    TextRecognizer? recognizer,
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  }) async {
    final owns = recognizer == null;
    final textRecognizer = recognizer ??
        TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width,
        ),
      );
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _extractPlate(recognizedText);
    } finally {
      if (owns) unawaited(textRecognizer.close());
    }
  }

  /// Roda o reconhecedor e devolve os blocos de texto com suas posições.
  Future<List<PlateTextBlock>> _extractBlocks(
    img.Image image,
    TextRecognizer recognizer,
  ) async {
    final inputImage = _toInputImage(image);
    final recognizedText = await recognizer.processImage(inputImage);
    return [
      for (final block in recognizedText.blocks)
        PlateTextBlock(block.text, block.boundingBox),
    ];
  }

  /// Ordena os blocos por chance de serem uma placa (texto alfanumérico com
  /// ~7 caracteres e área relevante), priorizando os mais prováveis.
  List<PlateTextBlock> _rankCandidates(List<PlateTextBlock> blocks) {
    final scored = blocks.map((b) => (block: b, score: _score(b))).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .take(_maxRoiCandidates)
        .map((e) => e.block)
        .toList();
  }

  int _score(PlateTextBlock block) {
    final norm =
        block.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final letters = norm.replaceAll(RegExp(r'[0-9]'), '').length;
    final digits = norm.length - letters;
    var score = 0;
    if (norm.length >= 6) score += 10;
    if (letters >= 3) score += 5;
    if (digits >= 2) score += 5;
    if (block.text.trim().isNotEmpty) score += 3;
    score += (block.rect.width * block.rect.height).round() ~/ 10000;
    return score;
  }

  /// Recorta a região de um bloco com uma pequena margem, com limites seguros.
  img.Image? _cropBlock(img.Image image, Rect rect) {
    const margin = 8;
    final x = (rect.left - margin).clamp(0, image.width - 1).round();
    final y = (rect.top - margin).clamp(0, image.height - 1).round();
    final right =
        (rect.right + margin).clamp(0, image.width).round();
    final bottom =
        (rect.bottom + margin).clamp(0, image.height).round();
    final w = right - x;
    final h = bottom - y;
    if (w < 8 || h < 8) return null;
    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  /// Constrói o [InputImage] do ML Kit (Android) a partir de uma imagem em
  /// tons de cinza, convertendo para o formato NV21 — o único aceito pelo
  /// `InputImage.fromBytes` nesta plataforma.
  InputImage _toInputImage(img.Image image) {
    final width = image.width;
    final height = image.height;
    final bytes = _grayscaleToNv21(image);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  /// Converte uma imagem em tons de cinza para NV21 (plano Y com a luminância
  /// e crominância U/V neutra = 128, já que a imagem não tem cor).
  Uint8List _grayscaleToNv21(img.Image image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvWidth = (width + 1) >> 1;
    final uvHeight = (height + 1) >> 1;
    final buffer = Uint8List(ySize + uvWidth * uvHeight * 2);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer[y * width + x] = image.getPixel(x, y).r.toInt();
      }
    }
    // Crominância neutra (NV21: V alternando com U, todos 128).
    buffer.fillRange(ySize, buffer.length, 128);
    return buffer;
  }

  /// Extrai a primeira placa válida do texto reconhecido.
  String? _extractPlate(RecognizedText recognizedText) {
    for (final block in recognizedText.blocks) {
      final plate = PlateExtractor.extract(block.text);
      if (plate != null) {
        return plate;
      }
    }
    return null;
  }
}