import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart' as pi;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:sentinela/domain/camera_image_converter.dart';

/// Constrói um quadro YUV420 de 4x2 com plano Y, U e V, como o Android entrega.
CameraImage _yuv420Image({int yValue = 100, int uvValue = 128}) {
  const width = 4;
  const height = 2;
  final y = Uint8List(width * height)..fillRange(0, width * height, yValue);
  final uv = Uint8List((width ~/ 2) * (height ~/ 2))
    ..fillRange(0, (width ~/ 2) * (height ~/ 2), uvValue);
  return CameraImage.fromPlatformInterface(pi.CameraImageData(
    format: const pi.CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
    width: width,
    height: height,
    planes: [
      pi.CameraImagePlane(bytes: y, bytesPerRow: width, bytesPerPixel: 1),
      pi.CameraImagePlane(bytes: uv, bytesPerRow: width ~/ 2, bytesPerPixel: 2),
      pi.CameraImagePlane(bytes: uv, bytesPerRow: width ~/ 2, bytesPerPixel: 2),
    ],
  ));
}

void main() {
  group('CameraImageConverter.convert (Android/NV21)', () {
    test('gera buffer NV21 válido: plano Y seguido de crominância VU intercalada', () {
      final image = _yuv420Image();
      final input = CameraImageConverter.convert(image, InputImageRotation.rotation0deg);

      // 8 bytes de Y + 4 bytes de crominância (V,U,V,U) = 12 bytes.
      expect(input.bytes!.length, 12);
      // Plano Y preservado nos primeiros 8 bytes.
      expect(input.bytes!.sublist(0, 8), everyElement(100));
      // Crominância intercalada como VU (todos iguais aqui).
      expect(input.bytes!.sublist(8), everyElement(128));
      expect(input.metadata!.format, InputImageFormat.nv21);
      expect(input.metadata!.size, const Size(4, 2));
    });

    test('metadados refletem dimensões do quadro', () {
      final input = CameraImageConverter.convert(
        _yuv420Image(),
        InputImageRotation.rotation90deg,
      );
      expect(input.metadata!.size.width, 4);
      expect(input.metadata!.size.height, 2);
      expect(input.metadata!.rotation, InputImageRotation.rotation90deg);
    });
  });

  group('CameraImageConverter.cropToRoi', () {
    test('recorta a região central mantendo o plano Y', () {
      const width = 8;
      const height = 4;
      final y = Uint8List(width * height);
      for (var i = 0; i < y.length; i++) {
        y[i] = (i % 256);
      }
      final uv = Uint8List(4 * 2)..fillRange(0, 8, 200);
      final image = CameraImage.fromPlatformInterface(pi.CameraImageData(
        format: const pi.CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
        width: width,
        height: height,
        planes: [
          pi.CameraImagePlane(bytes: y, bytesPerRow: width, bytesPerPixel: 1),
          pi.CameraImagePlane(bytes: uv, bytesPerRow: 4, bytesPerPixel: 2),
          pi.CameraImagePlane(bytes: uv, bytesPerRow: 4, bytesPerPixel: 2),
        ],
      ));

      final roi = CameraImageConverter.cropToRoi(
        image,
        const Rect.fromLTWH(2, 0, 4, 4),
      );
      expect(roi.width, 4);
      expect(roi.height, 4);
      expect(roi.bytes.length, 4 * 4 + 2 * 2 * 2);

      // Plano Y: linhas completas a partir da coluna 2.
      for (var row = 0; row < 4; row++) {
        for (var col = 0; col < 4; col++) {
          expect(roi.bytes[row * 4 + col], y[row * 8 + 2 + col]);
        }
      }
      // Crominância presente (valores 200) no fim do buffer.
      expect(roi.bytes.sublist(16), everyElement(200));
    });

    test('arredonda o recorte para dimensões pares', () {
      const width = 8;
      const height = 8;
      final y = Uint8List(width * height);
      final uv = Uint8List(4 * 4)..fillRange(0, 16, 128);
      final image = CameraImage.fromPlatformInterface(pi.CameraImageData(
        format: const pi.CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
        width: width,
        height: height,
        planes: [
          pi.CameraImagePlane(bytes: y, bytesPerRow: width, bytesPerPixel: 1),
          pi.CameraImagePlane(bytes: uv, bytesPerRow: 4, bytesPerPixel: 2),
          pi.CameraImagePlane(bytes: uv, bytesPerRow: 4, bytesPerPixel: 2),
        ],
      ));

      final roi = CameraImageConverter.cropToRoi(
        image,
        const Rect.fromLTWH(3, 1, 5, 3),
      );
      expect(roi.width, 4);
      expect(roi.height, 2);
      expect(roi.bytes.length, 4 * 2 + 2 * 1 * 2);
    });

    test('limita o recorte aos limites do quadro', () {
      const width = 8;
      const height = 8;
      final y = Uint8List(width * height);
      final uv = Uint8List(4 * 4)..fillRange(0, 16, 128);
      final image = CameraImage.fromPlatformInterface(pi.CameraImageData(
        format: const pi.CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
        width: width,
        height: height,
        planes: [
          pi.CameraImagePlane(bytes: y, bytesPerRow: width, bytesPerPixel: 1),
          pi.CameraImagePlane(bytes: uv, bytesPerRow: 4, bytesPerPixel: 2),
          pi.CameraImagePlane(bytes: uv, bytesPerRow: 4, bytesPerPixel: 2),
        ],
      ));

      final roi = CameraImageConverter.cropToRoi(
        image,
        const Rect.fromLTWH(6, 6, 10, 10),
      );
      expect(roi.width, 2);
      expect(roi.height, 2);
    });
  });

  group('CameraImageConverter.toRgba', () {
    test('converte quadro uniforme para tons de cinza esperados', () {
      final frame = CameraImageConverter.toRgba(_yuv420Image());
      expect(frame.width, 4);
      expect(frame.height, 2);
      expect(frame.bytes.length, 4 * 2 * 4);

      // Com U = V = 128 (crominância neutra), R = G = B para todos os pixels.
      for (var i = 0; i < 4 * 2; i++) {
        final o = i * 4;
        expect(frame.bytes[o], frame.bytes[o + 1]);
        expect(frame.bytes[o + 1], frame.bytes[o + 2]);
        expect(frame.bytes[o + 3], 255);
      }
    });

    test('dimensões do RGBA batem com o quadro de origem', () {
      final frame = CameraImageConverter.toRgba(_yuv420Image());
      expect(frame.width, 4);
      expect(frame.height, 2);
    });
  });
}