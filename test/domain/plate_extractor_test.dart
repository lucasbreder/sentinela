import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/domain/plate_recognition_service.dart';
import 'package:sentinela/domain/plate_type.dart';

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

    test('O na posição 4 não é letra Mercosul e vira dígito 0 (antiga)', () {
      expect(PlateExtractor.extract('ABC1O23'), 'ABC1023');
    });

    test('mantém I na posição 4 do Mercosul (A–J, não vira 1)', () {
      expect(PlateExtractor.extract('ABC1I23'), 'ABC1I23');
    });

    test('L na posição 4 não é letra Mercosul e vira dígito 1 (antiga)', () {
      expect(PlateExtractor.extract('ABC1L23'), 'ABC1123');
    });

    test('corrige O/0 em dígito da placa antiga', () {
      expect(PlateExtractor.extract('ABC12O3'), 'ABC1203');
    });

    test('Mercosul oferece 0 e 6 em posição de dígito (zero cortado)', () {
      expect(PlateExtractor.extractAll('ABC6D23'), ['ABC6D23', 'ABC0D23']);
      expect(PlateExtractor.extractAll('ABC0D23'), ['ABC0D23', 'ABC6D23']);
    });

    test('antiga confia no OCR em posição de dígito (sem 0/6)', () {
      expect(
        PlateExtractor.extractAll('ABC6D23', type: PlateType.old),
        isEmpty,
      );
      expect(
        PlateExtractor.extractAll('ABC6234', type: PlateType.old),
        ['ABC6234'],
      );
    });

    test('placa sem ambiguidade gera um único candidato', () {
      expect(PlateExtractor.extractAll('ABC1D23'), ['ABC1D23']);
    });

    test('rejeita texto sem padrão de placa', () {
      expect(PlateExtractor.extract('RESTRICAO GENERAL'), isNull);
    });

    test('rejeita texto vazio', () {
      expect(PlateExtractor.extract(''), isNull);
    });
  });

  group('PlateExtractor com tipo conhecido', () {
    test('Mercosul puro gera um único candidato', () {
      expect(
        PlateExtractor.extractAll('ABC1D23', type: PlateType.mercosul),
        ['ABC1D23'],
      );
    });

    test('placa antiga pura gera um único candidato', () {
      expect(
        PlateExtractor.extractAll('ABC1234', type: PlateType.old),
        ['ABC1234'],
      );
    });

    test('antiga não é interpretada como Mercosul', () {
      expect(
        PlateExtractor.extractAll('ABC1D23', type: PlateType.old),
        isEmpty,
      );
    });

    test('Mercosul não converte dígito em letra fora de A–J', () {
      expect(
        PlateExtractor.extractAll('ABC1234', type: PlateType.mercosul),
        isEmpty,
      );
    });

    test('placa antiga não gera variação Mercosul com Z na posição 4', () {
      expect(PlateExtractor.extractAll('OSM5222'), ['OSM5222']);
      expect(
        PlateExtractor.extractAll('OSM5222', type: PlateType.old),
        ['OSM5222'],
      );
    });

    test('letra Mercosul da posição 4 é restrita a A–J', () {
      expect(
        PlateExtractor.extractAll('ABC1F23', type: PlateType.mercosul),
        ['ABC1F23'],
      );
      expect(
        PlateExtractor.extractAll('ABC1K23', type: PlateType.mercosul),
        isEmpty,
      );
    });

    test('tipo conhecido restringe candidatos da posição 4', () {
      expect(
        PlateExtractor.extractAll('ABC1623'),
        ['ABC1623'],
      );
      expect(
        PlateExtractor.extractAll('ABC1623', type: PlateType.old),
        ['ABC1623'],
      );
      expect(
        PlateExtractor.extractAll('ABC1623', type: PlateType.mercosul),
        ['ABC1G23'],
      );
    });
  });
}
