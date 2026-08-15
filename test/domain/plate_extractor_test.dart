import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/domain/plate_recognition_service.dart';

void main() {
  group('PlateExtractor', () {
    test('extrai placa Mercosul pura', () {
      expect(PlateExtractor.extract('ABC1D23'), 'ABC1D23');
    });

    test('extrai placa antiga pura', () {
      expect(PlateExtractor.extract('ABC1234'), 'ABC1234');
    });

    test('aceita texto com minúsculas', () {
      expect(PlateExtractor.extract('abc1d23'), 'ABC1D23');
    });

    test('extrai placa em meio a texto ao redor', () {
      expect(PlateExtractor.extract('veiculo ABC1D23 saida'), 'ABC1D23');
    });

    test('extrai placa com espaços internos', () {
      expect(PlateExtractor.extract('ABC 1D23'), 'ABC1D23');
    });

    test('extrai placa com ruído de caracteres', () {
      expect(PlateExtractor.extract('ABC1D2 3 xyz'), 'ABC1D23');
    });

    test('corrige confusão O/0 em posição de letra', () {
      expect(PlateExtractor.extract('AB01D23'), 'ABO1D23');
    });

    test('corrige confusão O/0 em posição de dígito', () {
      expect(PlateExtractor.extract('ABC1O23'), 'ABC1023');
    });

    test('corrige confusão I/1/L em posição de dígito', () {
      expect(PlateExtractor.extract('ABC1L23'), 'ABC1123');
    });

    test('rejeita texto sem padrão de placa', () {
      expect(PlateExtractor.extract('RESTRICAO GENERAL'), isNull);
    });

    test('rejeita texto vazio', () {
      expect(PlateExtractor.extract(''), isNull);
    });
  });
}
