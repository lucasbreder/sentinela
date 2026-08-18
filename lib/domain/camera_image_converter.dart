import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Buffer RGB(RGBA) extraído de um quadro da câmera, para processamento em
/// Dart (ex.: recorte da placa).
class RgbaFrame {
  const RgbaFrame({required this.bytes, required this.width, required this.height});

  final Uint8List bytes;
  final int width;
  final int height;
}

/// Recorte (ROI) de um quadro da câmera em NV21, pronto para o ML Kit.
///
/// O buffer é um plano Y de `width * height` seguido da crominância VU
/// intercalada para `(width/2) * (height/2)`, com `bytesPerRow = width`.
class RoiFrame {
  const RoiFrame({required this.bytes, required this.width, required this.height});

  final Uint8List bytes;
  final int width;
  final int height;
}

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

  /// Monta o buffer NV21 (Android): plano Y inteiro seguido da crominância
  /// intercalada **VU** (V depois U alternando).
  ///
  /// No formato `yuv_420_888` do Android os planos costumam ser
  /// `planes[0] = Y`, `planes[1] = U`, `planes[2] = V`. O NV21 exige que U e V
  /// sejam intercalados como VU — apenas concatenar o plano U (como era feito
  /// antes) gerava um buffer malformado que o ML Kit rejeitava, silenciando o
  /// streaming.
  static Uint8List _toNv21(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes.single.bytes;
    }

    final y = image.planes[0];
    final u = image.planes[1];
    final v = image.planes[2];

    final buffer = Uint8List(y.bytes.length + u.bytes.length + v.bytes.length);
    buffer.setRange(0, y.bytes.length, y.bytes);

    final chromaCount = u.bytes.length < v.bytes.length
        ? u.bytes.length
        : v.bytes.length;
    var offset = y.bytes.length;
    for (var i = 0; i < chromaCount; i++) {
      buffer[offset++] = v.bytes[i];
      buffer[offset++] = u.bytes[i];
    }
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

  /// Converte um quadro NV21/YUV420 para RGBA, permitindo recortar a região da
  /// placa em Dart e re-OCR em alta qualidade.
  static RgbaFrame toRgba(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];

    Uint8List? uv;
    if (image.planes.length == 3) {
      uv = _interleaveVu(image.planes[1].bytes, image.planes[2].bytes);
    } else if (image.planes.length == 2) {
      uv = image.planes[1].bytes;
    }

    final out = Uint8List(width * height * 4);
    if (uv != null) {
      final uvWidth = width >> 1;
      for (var y = 0; y < height; y++) {
        final yRow = y * yPlane.bytesPerRow;
        for (var x = 0; x < width; x++) {
          final yIdx = yRow + x;
          if (yIdx >= yPlane.bytes.length) continue;
          final Y = (yPlane.bytes[yIdx] - 16) * 298;
          final uvIndex = (y >> 1) * uvWidth + (x >> 1);
          final V = uv[uvIndex * 2] - 128;
          final U = uv[uvIndex * 2 + 1] - 128;
          final r = (Y + 409 * V + 128) >> 8;
          final g = (Y - 100 * U - 208 * V + 128) >> 8;
          final b = (Y + 516 * U + 128) >> 8;
          final o = (y * width + x) * 4;
          out[o] = r.clamp(0, 255).toInt();
          out[o + 1] = g.clamp(0, 255).toInt();
          out[o + 2] = b.clamp(0, 255).toInt();
          out[o + 3] = 255;
        }
      }
    } else {
      // Sem crominância disponível: usa a luminância como tons de cinza.
      for (var i = 0; i < width * height; i++) {
        final yIdx = (i ~/ width) * yPlane.bytesPerRow + (i % width);
        if (yIdx >= yPlane.bytes.length) continue;
        final gray = yPlane.bytes[yIdx];
        final o = i * 4;
        out[o] = gray;
        out[o + 1] = gray;
        out[o + 2] = gray;
        out[o + 3] = 255;
      }
    }
    return RgbaFrame(bytes: out, width: width, height: height);
  }

  /// Recorta uma região de interesse ([Rect]) de um quadro da câmera e devolve
  /// um buffer NV21 menor, sem converter o quadro inteiro para RGBA.
  ///
  /// O recorte mantém alinhamento par para a crominância ficar válida. Como o
  /// ML Kit roda o OCR apenas sobre a região recortada, o processamento fica
  /// mais rápido e a placa (centralizada) ganha resolução relativa.
  static RoiFrame cropToRoi(CameraImage image, Rect roi) {
    final width = image.width;
    final height = image.height;
    final x = ((roi.left.round()) & ~1).clamp(0, width - 2);
    final y = ((roi.top.round()) & ~1).clamp(0, height - 2);
    final w = ((roi.width.round()) & ~1).clamp(2, width - x);
    final h = ((roi.height.round()) & ~1).clamp(2, height - y);
    final yPlane = image.planes[0];
    final cw = w ~/ 2;
    final ch = h ~/ 2;

    final out = Uint8List(w * h + cw * ch * 2);
    for (var row = 0; row < h; row++) {
      final srcRow = (y + row) * yPlane.bytesPerRow;
      out.setRange(row * w, row * w + w, yPlane.bytes, srcRow + x);
    }

    if (image.planes.length >= 3) {
      final u = image.planes[1];
      final v = image.planes[2];
      final cx = x ~/ 2;
      final cy = y ~/ 2;
      var offset = w * h;
      for (var crow = 0; crow < ch; crow++) {
        final srcU = (cy + crow) * u.bytesPerRow;
        final srcV = (cy + crow) * v.bytesPerRow;
        for (var ccol = 0; ccol < cw; ccol++) {
          out[offset++] = v.bytes[srcV + cx + ccol];
          out[offset++] = u.bytes[srcU + cx + ccol];
        }
      }
    } else {
      out.fillRange(w * h, out.length, 128);
    }
    return RoiFrame(bytes: out, width: w, height: h);
  }

  /// Intercala U e V no padrão NV21 (V depois U), para conversão direta.
  static Uint8List _interleaveVu(Uint8List u, Uint8List v) {
    final count = u.length < v.length ? u.length : v.length;
    final out = Uint8List(count * 2);
    for (var i = 0; i < count; i++) {
      out[i * 2] = v[i];
      out[i * 2 + 1] = u[i];
    }
    return out;
  }
}
