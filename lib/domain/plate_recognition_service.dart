import 'dart:async';
import 'dart:io';
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

class PlateRecognitionService {
  /// Reconhece e devolve a primeira placa válida em uma imagem.
  Future<String?> recognize(String imagePath) async {
    final inputImage = _buildInputImage(imagePath);
    if (inputImage == null) return null;
    return processInputImage(inputImage);
  }

  /// Processa um [InputImage] (de foto ou quadro de câmera) e devolve a
  /// primeira placa válida, ou `null` se nada for encontrado. Cria e fecha um
  /// `TextRecognizer` por chamada.
  Future<String?> processInputImage(InputImage inputImage) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _extractPlate(recognizedText);
    } finally {
      unawaited(textRecognizer.close());
    }
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

  /// Pré-processa a imagem para melhorar a acurácia e constrói o `InputImage`
  /// do ML Kit com o buffer de pixels. Devolve `null` se a imagem não puder
  /// ser processada.
  InputImage? _buildInputImage(String imagePath) {
    final decoded = img.decodeImage(File(imagePath).readAsBytesSync());
    if (decoded == null) return null;

    final processed = ImagePreprocessor.process(decoded);
    final width = processed.width;
    final height = processed.height;
    final bytes = processed.getBytes(order: img.ChannelOrder.rgba);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: width * 4,
      ),
    );
  }
}
