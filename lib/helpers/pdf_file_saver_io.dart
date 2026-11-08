import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> savePdfFilePlatform({
  required String fileName,
  required Uint8List bytes,
  required String subject,
  required String text,
}) async {
  final path = await FileSaver.instance.saveAs(
    name: fileName,
    bytes: bytes,
    fileExtension: 'pdf',
    mimeType: MimeType.pdf,
  );
  if (path == null) return false;

  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/$fileName.pdf');
  await tempFile.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(tempFile.path, mimeType: 'application/pdf')],
    subject: subject,
    text: text,
  );
  return true;
}
