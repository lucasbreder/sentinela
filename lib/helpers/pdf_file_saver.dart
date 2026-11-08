import 'dart:typed_data';

import 'pdf_file_saver_stub.dart'
    if (dart.library.io) 'pdf_file_saver_io.dart'
    if (dart.library.js_interop) 'pdf_file_saver_web.dart'
    as platform;

Future<bool> savePdfFile({
  required String fileName,
  required Uint8List bytes,
  required String subject,
  required String text,
}) {
  return platform.savePdfFilePlatform(
    fileName: fileName,
    bytes: bytes,
    subject: subject,
    text: text,
  );
}
