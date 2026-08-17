import 'dart:typed_data';

/// Fallback para plataformas sem suporte a OCR no navegador.
Future<String> webOcrText(Uint8List imageBytes, String mime) async {
  throw UnsupportedError('OCR no navegador indisponível nesta plataforma');
}
