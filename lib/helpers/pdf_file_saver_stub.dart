import 'dart:typed_data';

Future<bool> savePdfFilePlatform({
  required String fileName,
  required Uint8List bytes,
  required String subject,
  required String text,
}) {
  throw UnsupportedError('Salvar PDF não é suportado nesta plataforma');
}
