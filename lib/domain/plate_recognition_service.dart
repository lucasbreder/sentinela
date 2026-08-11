import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado do reconhecimento de uma placa.
class PlateRecognition {
  const PlateRecognition(this.plate);

  final String plate;
}

/// Lógica pura de extração de placa a partir de um texto reconhecido (OCR).
/// Mantida separada do reconhecimento para permitir teste unitário.
abstract final class PlateExtractor {
  static String? extract(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty || text.length >= 10 || text != text.toUpperCase()) {
      return null;
    }
    return text.replaceAll(RegExp(r'\n'), '-');
  }
}

class PlateRecognitionService {
  /// Reconhece e devolve a primeira placa válida em uma imagem.
  Future<String?> recognize(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);

      for (final block in recognizedText.blocks) {
        final plate = PlateExtractor.extract(block.text);
        if (plate != null) {
          return plate;
        }
      }
      return null;
    } finally {
      textRecognizer.close();
    }
  }
}
