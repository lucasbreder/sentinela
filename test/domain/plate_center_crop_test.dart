import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/domain/plate_recognition_service.dart';

void main() {
  group('PlateRecognitionService.centerCropRect', () {
    test('recorta a faixa central de uma imagem grande', () {
      final rect = PlateRecognitionService.centerCropRect(1000, 1000);
      expect(rect, isNotNull);
      expect(rect!.left, 100);
      expect(rect.right, 900);
      expect(rect.top, 300);
      expect(rect.bottom, 700);
    });

    test('mantém a proporção da faixa em imagens verticais', () {
      final rect = PlateRecognitionService.centerCropRect(400, 800);
      expect(rect, isNotNull);
      expect(rect!.width, 320);
      expect(rect.height, 320);
    });

    test('devolve null para imagens muito pequenas', () {
      expect(PlateRecognitionService.centerCropRect(20, 20), isNull);
    });
  });
}