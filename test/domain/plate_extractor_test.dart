import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/domain/plate_recognition_service.dart';

void main() {
  group('PlateExtractor', () {
    test('extrai texto curto em maiúsculas', () {
      expect(PlateExtractor.extract('ABC1D23'), 'ABC1D23');
    });

    test('rejeita texto com minúsculas', () {
      expect(PlateExtractor.extract('abc1d23'), isNull);
    });

    test('rejeita texto longo demais', () {
      expect(PlateExtractor.extract('PLACA12345LONGA'), isNull);
    });

    test('rejeita texto vazio', () {
      expect(PlateExtractor.extract(''), isNull);
    });

    test('substitui quebras de linha por hífen', () {
      expect(PlateExtractor.extract('ABC\n1234'), 'ABC-1234');
    });

    test('ignora espaços ao redor', () {
      expect(PlateExtractor.extract('  ABC1234  '), 'ABC1234');
    });
  });
}
