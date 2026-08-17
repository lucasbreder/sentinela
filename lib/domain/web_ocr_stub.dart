import 'dart:typed_data';

/// Fallback para plataformas sem suporte a OCR no navegador.
Future<void> ensureTesseractReady({void Function(String? status)? onStatus}) async {
  throw UnsupportedError('OCR no navegador indisponível nesta plataforma');
}

/// Fallback para plataformas sem suporte a OCR no navegador.
Future<String> webOcrText(
  Uint8List imageBytes,
  String mime, {
  void Function(double? progress, String? status)? onProgress,
}) async {
  throw UnsupportedError('OCR no navegador indisponível nesta plataforma');
}