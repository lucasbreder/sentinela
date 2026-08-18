import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sentinela/domain/plate_color_detector.dart';
import 'package:sentinela/domain/plate_type.dart';

/// Imagem sintética de placa: fundo branco e, opcionalmente, faixa azul no topo
/// (Mercosul).
img.Image _plate({bool mercosul = true}) {
  final im = img.Image(width: 100, height: 40);
  final band = (40 * 0.35).round();
  for (var y = 0; y < 40; y++) {
    for (var x = 0; x < 100; x++) {
      if (mercosul && y < band) {
        im.setPixelRgb(x, y, 0, 0, 200);
      } else {
        im.setPixelRgb(x, y, 240, 240, 240);
      }
    }
  }
  return im;
}

/// Buffer NV21 sintético com plano Y neutro e crominância configurável na
/// faixa superior. Por padrão U alto e V baixo (azul).
Uint8List _nv21({
  int width = 40,
  int height = 20,
  bool blueTop = true,
  int uBlue = 190,
  int vBlue = 110,
}) {
  final ySize = width * height;
  final cw = (width + 1) >> 1;
  final ch = (height + 1) >> 1;
  final buf = Uint8List(ySize + cw * ch * 2);
  buf.fillRange(0, ySize, 100);
  final bandHeight = (height * 0.35).round().clamp(1, height);
  for (var y = 0; y < height; y++) {
    final uvRow = (y >> 1) * cw;
    for (var x = 0; x < width; x += 2) {
      final off = ySize + (uvRow + (x >> 1)) * 2;
      final isBlue = blueTop && y < bandHeight;
      buf[off] = isBlue ? vBlue : 128; // V
      buf[off + 1] = isBlue ? uBlue : 128; // U
    }
  }
  return buf;
}

void main() {
  group('PlateColorDetector.detect (imagem)', () {
    test('faixa azul no topo indica Mercosul', () {
      expect(PlateColorDetector.detect(_plate(mercosul: true)),
          PlateType.mercosul);
    });

    test('placa branca indica antiga', () {
      expect(
        PlateColorDetector.detect(_plate(mercosul: false)),
        PlateType.old,
      );
    });

    test('imagem pequena demais retorna unknown', () {
      final tiny = img.Image(width: 2, height: 2);
      expect(PlateColorDetector.detect(tiny), PlateType.unknown);
    });
  });

  group('PlateColorDetector.detectNv21 (buffer NV21)', () {
    test('crominância azul no topo indica Mercosul', () {
      expect(
        PlateColorDetector.detectNv21(_nv21(blueTop: true), 40, 20),
        PlateType.mercosul,
      );
    });

    test('crominância neutra indica antiga', () {
      expect(
        PlateColorDetector.detectNv21(_nv21(blueTop: false), 40, 20),
        PlateType.old,
      );
    });

    test('cinza com brilho alto (U=V) retorna unknown', () {
      expect(
        PlateColorDetector.detectNv21(
          _nv21(blueTop: true, uBlue: 170, vBlue: 170),
          40,
          20,
        ),
        PlateType.unknown,
      );
    });

    test('magenta (U e V altos) retorna unknown', () {
      expect(
        PlateColorDetector.detectNv21(
          _nv21(blueTop: true, uBlue: 190, vBlue: 185),
          40,
          20,
        ),
        PlateType.unknown,
      );
    });

    test('azul com brilho reduzido ainda é detectado', () {
      expect(
        PlateColorDetector.detectNv21(
          _nv21(blueTop: true, uBlue: 170, vBlue: 120),
          40,
          20,
        ),
        PlateType.mercosul,
      );
    });

    test('buffer pequeno demais retorna unknown', () {
      expect(
        PlateColorDetector.detectNv21(Uint8List(4), 4, 2),
        PlateType.unknown,
      );
    });
  });
}
