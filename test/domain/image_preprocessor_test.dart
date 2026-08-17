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
}
