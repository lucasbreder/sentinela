import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

Future<bool> savePdfFilePlatform({
  required String fileName,
  required Uint8List bytes,
  required String subject,
  required String text,
}) async {
  final destination = await FileSaver.instance.saveFile(
    name: fileName,
    bytes: bytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
  return destination.isNotEmpty;
}
