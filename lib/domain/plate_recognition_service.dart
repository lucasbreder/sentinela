import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:sentinela/domain/image_preprocessor.dart';
import 'package:sentinela/domain/plate_color_detector.dart';
import 'package:sentinela/domain/plate_type.dart';

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

  /// Extrai todas as interpretações válidas de placa a partir do texto do OCR,
  /// incluindo variações de caracteres ambíguos (zero cortado `0/6`, `I/1`,
  /// `O/0`, etc.). O primeiro candidato é o mais provável (confia no OCR); os
  /// demais são alternativas para o usuário confirmar.
  ///
  /// Quando o [type] é conhecido (ex.: inferido pela cor da placa), usa apenas
  /// o padrão correspondente e restringe os caracteres de cada posição ao tipo
  /// esperado (Mercosul exige letra na posição 4; a antiga, dígito). Isso
  /// reduz a quantidade de candidatos gerados — e de opções para o usuário.
  static List<String> extractAll(
    String rawText, {
    PlateType type = PlateType.unknown,
  }) {
    if (rawText.isEmpty) return const [];
    final text = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (text.length < 7) return const [];

    final candidates = <String>[];
    final seen = <String>{};
    for (var i = 0; i <= text.length - 7; i++) {
      final window = text.substring(i, i + 7);
      switch (type) {
        case PlateType.mercosul:
          _addCandidates(candidates, seen, window, _mercosul, {0, 1, 2, 4});
        case PlateType.old:
          _addCandidates(candidates, seen, window, _old, {0, 1, 2});
        case PlateType.unknown:
          _addUnknownCandidates(candidates, seen, window);
      }
    }
    return candidates;
  }

  /// Quando o tipo é desconhecido, confia no OCR para decidir o padrão a partir
  /// do caractere da posição 4: letra indica Mercosul; dígito indica antiga.
  /// Assim não gera um número onde o OCR leu letra (nem letra onde leu dígito),
  /// reduzindo as opções. Se o padrão indicado não formar placa válida, recorre
  /// ao outro como rede de segurança.
  static void _addUnknownCandidates(
    List<String> candidates,
    Set<String> seen,
    String window,
  ) {
    final letterAtPos4 = _isLetter(window[4]);
    final local = <String>[];
    if (letterAtPos4) {
      _fillMatching(local, window, _mercosul, {0, 1, 2, 4});
      if (local.isEmpty) _fillMatching(local, window, _old, {0, 1, 2});
    } else {
      _fillMatching(local, window, _old, {0, 1, 2});
      if (local.isEmpty) _fillMatching(local, window, _mercosul, {0, 1, 2, 4});
    }
    for (final plate in local) {
      if (seen.add(plate)) candidates.add(plate);
    }
  }

  /// Preenche [out] com as variações da janela que casam com o [pattern].
  static void _fillMatching(
    List<String> out,
    String window,
    RegExp pattern,
    Set<int> letterPositions,
  ) {
    for (final variant in _variants(window, letterPositions)) {
      if (pattern.hasMatch(variant)) out.add(variant);
    }
  }

  /// Devolve a primeira placa válida (a mais provável) ou `null`.
  static String? extract(String rawText, {PlateType type = PlateType.unknown}) {
    final candidates = extractAll(rawText, type: type);
    return candidates.isEmpty ? null : candidates.first;
  }

  static bool _isLetter(String c) => RegExp(r'[A-Z]').hasMatch(c);

  static void _addCandidates(
    List<String> candidates,
    Set<String> seen,
    String window,
    RegExp pattern,
    Set<int> letterPositions,
  ) {
    for (final variant in _variants(window, letterPositions)) {
      if (pattern.hasMatch(variant) && seen.add(variant)) {
        candidates.add(variant);
      }
    }
  }

  /// Gera todas as combinações de caracteres plausíveis para a janela, na
  /// ordem "confia no OCR" primeiro (menos substituições) e depois as trocas
  /// de caracteres ambíguos.
  static Iterable<String> _variants(
    String window,
    Set<int> letterPositions,
  ) sync* {
    // Mercosul tem a posição 4 como letra; usa alternativas de dígito que
    // expandem 0↔6 (o zero cortado é lido como 6) para abrir a confirmação.
    final mercosul = letterPositions.contains(4);
    final alternatives = <List<String>>[];
    for (var i = 0; i < window.length; i++) {
      final c = window[i];
      if (letterPositions.contains(i)) {
        var alts = _letterAlternatives(c);
        // Na posição 4 o Mercosul (discriminador) só usa letras A–J. Letras
        // fora desse intervalo (Z, O, L...) não formam placa Mercosul — se
        // não houver alternativa válida, o padrão não produz candidato.
        if (i == 4) {
          alts = alts.where(_isMercosulDiscriminator).toList();
        }
        alternatives.add(alts);
      } else {
        alternatives.add(mercosul ? _digitAlternativesMercosul(c) : _digitAlternatives(c));
      }
    }
    for (final combo in _combinations(alternatives)) {
      yield combo.join();
    }
  }

  /// Alternativas de dígito para placa Mercosul: o zero cortado é lido como
  /// `6`, então um `6`/`0` nas posições de dígito (3, 5, 6) oferece as duas
  /// opções para o usuário confirmar. Placas antigas não têm zero cortado e
  /// usam a versão que confia no OCR.
  static List<String> _digitAlternativesMercosul(String c) => switch (c) {
        '6' => ['6', '0'],
        '0' => ['0', '6'],
        'O' => ['0', '6'],
        'G' => ['6'],
        'I' || 'L' => ['1'],
        'S' => ['5'],
        'Z' => ['2'],
        'B' => ['8'],
        _ => [c],
      };

  /// Letras permitidas no discriminador (posição 4) da placa Mercosul: A–J.
  static bool _isMercosulDiscriminator(String c) => 'ABCDEFGHIJ'.contains(c);

  static Iterable<List<String>> _combinations(List<List<String>> lists) sync* {
    if (lists.isEmpty) {
      yield const [];
      return;
    }
    for (final head in lists.first) {
      for (final tail in _combinations(lists.sublist(1))) {
        yield [head, ...tail];
      }
    }
  }

  /// Alternativas para uma posição de letra (Mercosul posições 0, 1, 2, 4;
  /// antiga 0, 1, 2). A primeira opção é a leitura mais provável do OCR.
  ///
  /// Confia no OCR para 0/6/G (o zero cortado já é limpo no pré-processamento),
  /// gerando uma única opção em vez de alternativas múltiplas.
  static List<String> _letterAlternatives(String c) => switch (c) {
        '0' => ['O'],
        '1' => ['I', 'L'],
        '5' => ['S'],
        '2' => ['Z'],
        '8' => ['B'],
        '6' => ['G'],
        _ => [c],
      };

  /// Alternativas para uma posição de dígito. Confia no OCR para 0/6 (o zero
  /// cortado do Mercosul já é normalizado no pré-processamento), então não
  /// gera mais opções múltiplas de 0↔6.
  static List<String> _digitAlternatives(String c) => switch (c) {
        'O' => ['0'],
        'I' || 'L' => ['1'],
        'S' => ['5'],
        'Z' => ['2'],
        'B' => ['8'],
        'G' => ['6'],
        '6' => ['6'],
        '0' => ['0'],
        _ => [c],
      };
}

/// Bloco de texto reconhecido com sua posição (usado para localizar a placa).
class PlateTextBlock {
  const PlateTextBlock(this.text, this.rect);

  final String text;
  final Rect rect;
}

/// Resultado do reconhecimento de placa com o nível de confiança do OCR
/// (0..1). Usado para decidir se é preciso pedir confirmação ao usuário.
class PlateReadingResult {
  const PlateReadingResult({
    required this.candidates,
    required this.confidence,
  });

  final List<String> candidates;
  final double confidence;
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
      final candidates = await _recognizeOnImage(decoded, recognizer);
      return candidates.isEmpty ? null : candidates.first;
    } finally {
      unawaited(recognizer.close());
    }
  }
  /// Reconhece e devolve os candidatos de placa a partir dos bytes de uma
  /// imagem, pelo ML Kit com recorte da região da placa (ROI).
  Future<List<String>> recognizeBytes(
    Uint8List imageBytes, {
    void Function(double? progress, String? status)? onProgress,
  }) async {
    final decoded = _decodeForOcr(imageBytes);
    if (decoded == null) return const [];
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
  Future<List<String>> _recognizeOnImage(
    img.Image decoded,
    TextRecognizer recognizer,
  ) async {
    final processed = ImagePreprocessor.process(decoded);
    final type = PlateColorDetector.detect(decoded);

    // 1ª passada: tenta extrair a placa direto do texto dos blocos.
    final blocks = await _extractBlocks(processed, recognizer);
    for (final block in blocks) {
      final candidates = _extractSafe(block.text, type);
      if (candidates.isNotEmpty) return candidates;
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
        final extracted = _extractSafe(cb.text, type);
        if (extracted.isNotEmpty) return extracted;
      }
    }
    return const [];
  }

  /// Reconhece a placa a partir de um recorte de quadro em NV21 (já reduzido
  /// pela ROI), reutilizando o [recognizer] do streaming para não recriar o
  /// reconhecedor a cada quadro. É o caminho rápido de leitura em tempo real.
  ///
  /// O [type] (inferido pela cor da placa) restringe o padrão de extração e
  /// reduz os candidatos gerados.
  Future<PlateReadingResult> recognizeNv21(
    Uint8List nv21,
    int width,
    int height, {
    TextRecognizer? recognizer,
    InputImageRotation rotation = InputImageRotation.rotation0deg,
    PlateType type = PlateType.unknown,
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
      final raw = _extractWithConfidence(recognizedText, type: type);

      // 2ª passada (alta qualidade): aplica o pré-processamento completo
      // (contraste, binarização e deslash do zero cortado) e amplia, como no
      // caminho de foto. Preferida por melhorar a acurácia — o deslash evita
      // que o zero cortado do Mercosul seja lido como `6`.
      final source = _nv21ToGrayscale(nv21, width, height);
      final processedImage =
          ImagePreprocessor.upscale(ImagePreprocessor.process(source));
      final processedText =
          await textRecognizer.processImage(_toInputImage(processedImage, rotation: rotation));
      final processed = _extractWithConfidence(processedText, type: type);

      return processed.candidates.isNotEmpty ? processed : raw;
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
  InputImage _toInputImage(
    img.Image image, {
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  }) {
    final width = image.width;
    final height = image.height;
    final bytes = _grayscaleToNv21(image);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  /// Converte um buffer NV21 em imagem em tons de cinza (plano Y), preservando
  /// a luminância — suficiente para o OCR e para a ampliação da 2ª passada.
  img.Image _nv21ToGrayscale(Uint8List nv21, int width, int height) {
    final out = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final lum = nv21[y * width + x];
        out.setPixelRgb(x, y, lum, lum, lum);
      }
    }
    return out;
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

  /// Extrai os candidatos de placa de um texto, sem nunca degradar a leitura
  /// em relação ao comportamento sem tipo.
  ///
  /// O [type] (cor da placa) só é aplicado quando não muda o primeiro
  /// candidato que a extração padrão produziria — caso contrário, usa o
  /// resultado padrão. Isso mantém a acurácia que existia antes da inferência
  /// de cor e ainda reduz alternativas quando o tipo confirma a leitura.
  List<String> _extractSafe(String text, PlateType type) {
    final unknown = PlateExtractor.extractAll(text);
    if (unknown.isEmpty) return const [];
    if (type == PlateType.unknown) return unknown;
    final typed = PlateExtractor.extractAll(text, type: type);
    if (typed.isNotEmpty && typed.first == unknown.first) return typed;
    return unknown;
  }

  /// Extrai os candidatos de placa do texto reconhecido, com a confiança do
  /// bloco que gerou a leitura.
  PlateReadingResult _extractWithConfidence(
    RecognizedText recognizedText, {
    PlateType type = PlateType.unknown,
  }) {
    for (final block in recognizedText.blocks) {
      final candidates = _extractSafe(block.text, type);
      if (candidates.isNotEmpty) {
        return PlateReadingResult(
          candidates: candidates,
          confidence: _blockConfidence(block),
        );
      }
    }
    return const PlateReadingResult(candidates: [], confidence: 0);
  }

  /// Confiança média dos elementos de um bloco de texto reconhecido (0..1).
  /// Se não houver confiança disponível, assume leitura confiável (1.0).
  double _blockConfidence(TextBlock block) {
    final values = <double>[];
    for (final line in block.lines) {
      for (final element in line.elements) {
        final c = element.confidence;
        if (c != null) values.add(c);
      }
    }
    if (values.isEmpty) return 1.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}