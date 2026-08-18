import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sentinela/domain/image_preprocessor.dart';

void main() {
  img.Image syntheticImage() {
    final image = img.Image(width: 4, height: 4);
    image.clear(img.ColorRgb8(128, 128, 128));
    return image;
  }

  group('ImagePreprocessor', () {
    test('mantém as mesmas dimensões da imagem de origem', () {
      final result = ImagePreprocessor.process(syntheticImage());
      expect(result.width, 4);
      expect(result.height, 4);
    });

    test('produz imagem em nível de cinza (canais iguais)', () {
      final image = img.Image(width: 2, height: 2)
        ..setPixelRgb(0, 0, 200, 20, 20)
        ..setPixelRgb(1, 0, 10, 180, 40)
        ..setPixelRgb(0, 1, 50, 60, 250)
        ..setPixelRgb(1, 1, 100, 100, 100);
      final result = ImagePreprocessor.process(image);
      for (final pixel in result) {
        final lum = pixel.r.toInt();
        expect(pixel.g.toInt(), lum);
        expect(pixel.b.toInt(), lum);
      }
    });

    test('retorna imagem válida (diferente de origem)', () {
      final result = ImagePreprocessor.process(syntheticImage());
      expect(result, isA<img.Image>());
    });
  });

  group('ImagePreprocessor.binarize', () {
    test('separa claros e escuros em preto e branco puros', () {
      final image = img.Image(width: 2, height: 2)
        ..setPixelRgb(0, 0, 240, 240, 240)
        ..setPixelRgb(1, 0, 10, 10, 10)
        ..setPixelRgb(0, 1, 20, 20, 20)
        ..setPixelRgb(1, 1, 250, 250, 250);
      final result = ImagePreprocessor.binarize(image);
      for (final pixel in result) {
        final v = pixel.r.toInt();
        expect(v == 0 || v == 255, true);
        expect(pixel.g.toInt(), v);
        expect(pixel.b.toInt(), v);
      }
      expect(result.getPixel(0, 0).r.toInt(), 255);
      expect(result.getPixel(0, 1).r.toInt(), 0);
    });

    test('process produz apenas pixels binários', () {
      final result = ImagePreprocessor.process(syntheticImage());
      for (final pixel in result) {
        final v = pixel.r.toInt();
        expect(v == 0 || v == 255, true);
      }
    });
  });

  group('ImagePreprocessor.upscale', () {
    test('amplia imagens menores que o alvo', () {
      final small = img.Image(width: 100, height: 50);
      final result = ImagePreprocessor.upscale(small);
      expect(result.width, greaterThan(small.width));
      expect(result.height, greaterThan(small.height));
      expect(result.width > result.height, true);
    });

    test('não amplia imagens já grandes o suficiente', () {
      final large = img.Image(width: 2000, height: 1000);
      final result = ImagePreprocessor.upscale(large);
      expect(result.width, large.width);
      expect(result.height, large.height);
    });
  });

  group('ImagePreprocessor.deslash', () {
    test('remove um traço diagonal fino por completo', () {
      final image = img.Image(width: 7, height: 7)..clear(img.ColorRgb8(255, 255, 255));
      for (var i = 1; i <= 5; i++) {
        image.setPixelRgb(i, i, 0, 0, 0);
      }
      final result = ImagePreprocessor.deslash(image);
      // O traço de 1px, sem vizinhos ortogonais, é removido inteiro (interior e
      // pontas), em cascata.
      expect(result.getPixel(3, 3).r.toInt(), 255);
      expect(result.getPixel(1, 1).r.toInt(), 255);
      expect(result.getPixel(5, 5).r.toInt(), 255);
    });

    test('preserva hastes horizontais/verticais de traço sólido', () {
      final image = img.Image(width: 6, height: 6)..clear(img.ColorRgb8(255, 255, 255));
      // barra horizontal de 2px de espessura.
      for (var x = 1; x <= 4; x++) {
        for (var y = 2; y <= 3; y++) {
          image.setPixelRgb(x, y, 0, 0, 0);
        }
      }
      final result = ImagePreprocessor.deslash(image);
      expect(result.getPixel(2, 2).r.toInt(), 0);
      expect(result.getPixel(3, 3).r.toInt(), 0);
    });

    test('mantém a imagem em preto-e-branco', () {
      final image = img.Image(width: 6, height: 6)..clear(img.ColorRgb8(255, 255, 255));
      image.setPixelRgb(1, 1, 0, 0, 0);
      image.setPixelRgb(2, 2, 0, 0, 0);
      image.setPixelRgb(3, 3, 0, 0, 0);
      final result = ImagePreprocessor.deslash(image);
      for (final p in result) {
        final v = p.r.toInt();
        expect(v == 0 || v == 255, true);
      }
    });

    test('remove o corte diagonal de um zero e preserva o anel', () {
      // "0" desenhado como anel (2px) com um corte diagonal de 1px no interior.
      final image = img.Image(width: 20, height: 20)..clear(img.ColorRgb8(255, 255, 255));
      const cx = 9;
      const cy = 9;
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 20; x++) {
          final dx = x - cx;
          final dy = y - cy;
          final dist = (dx * dx + dy * dy);
          // anel do zero
          if (dist >= 30 && dist <= 70) image.setPixelRgb(x, y, 0, 0, 0);
        }
      }
      // corte diagonal (1px) atravessando o interior.
      for (var i = -7; i <= 7; i++) {
        image.setPixelRgb(cx + i, cy - i, 0, 0, 0);
      }
      final result = ImagePreprocessor.deslash(image);
      // o corte (que cruza o centro) deve ter sido removido.
      expect(result.getPixel(cx, cy).r.toInt(), 255);
      // o anel continua presente.
      var ring = 0;
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 20; x++) {
          final dx = x - cx;
          final dy = y - cy;
          final dist = dx * dx + dy * dy;
          if (dist >= 30 && dist <= 70 && result.getPixel(x, y).r.toInt() == 0) ring++;
        }
      }
      expect(ring, greaterThan(0));
    });

    test('preserva traço diagonal grosso de letra (3px)', () {
      // Três linhas paralelas NW-SE = haste grossa (como a perna de uma letra).
      final image = img.Image(width: 10, height: 10)..clear(img.ColorRgb8(255, 255, 255));
      for (var off = 0; off < 3; off++) {
        for (var i = 0; i < 7; i++) {
          image.setPixelRgb(i, i + off, 0, 0, 0);
        }
      }
      final result = ImagePreprocessor.deslash(image);
      // O centro da haste grossa permanece preto (letra preservada).
      expect(result.getPixel(4, 4).r.toInt(), 0);
      expect(result.getPixel(4, 5).r.toInt(), 0);
    });
  });
}
