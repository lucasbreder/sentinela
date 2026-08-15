import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Converte um quadro da câmera ([CameraImage]) em um [InputImage] aceito pelo
/// ML Kit. A conversão depende da plataforma e do formato do plano.
abstract final class CameraImageConverter {
  /// Converte um quadro de câmera em [InputImage].
  ///
  /// No Android o feed costuma chegar como `yuv_420_888`, que é encaixado em
  /// `nv21` (plano Y seguido de VU intercalado). No iOS o plano chega pronto
  /// em `yuv420`. A rotação real do dispositivo é aplicada para o OCR não ler
  /// a placa rotacionada.
  static InputImage convert(CameraImage image, InputImageRotation rotation) {
    if (Platform.isIOS) {
      final bytes = _concatenatePlanes(image);
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    final bytes = _toNv21(image);
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Monta o buffer NV21 (Android): plano Y inteiro + planos de crominância
  /// intercalados (VU). Se o feed já for NV21 (2 planos), concatena direto.
  static Uint8List _toNv21(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes.single.bytes;
    }

    final y = image.planes[0];
    final uv = image.planes[1];
    final buffer = Uint8List(y.bytes.length + uv.bytes.length);
    buffer.setRange(0, y.bytes.length, y.bytes);
    buffer.setRange(y.bytes.length, buffer.length, uv.bytes);
    return buffer;
  }

  /// Concatena todos os planos em um único buffer (usado no iOS).
  static Uint8List _concatenatePlanes(CameraImage image) {
    final total = image.planes.fold<int>(
      0,
      (sum, plane) => sum + plane.bytes.length,
    );
    final buffer = Uint8List(total);
    var offset = 0;
    for (final plane in image.planes) {
      buffer.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    return buffer;
  }
}
