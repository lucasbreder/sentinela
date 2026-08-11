import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/result.dart';
import 'package:sentinela/domain/registry_controller.dart';

import 'fakes.dart';

void main() {
  late FakeRegistryRepository registries;
  late RegistryController controller;

  setUp(() {
    registries = FakeRegistryRepository();
    controller = RegistryController(registries: registries);
  });

  test('setRegistry adiciona registro com dados informados', () async {
    final result = await controller.setRegistry(
      type: MovementType.entrada,
      licensePlate: 'ABC1D23',
      driver: 'Maria',
      documentNumber: '123',
      unitId: 'u-1',
      notes: 'carga',
      authorId: 'user-1',
    );
    expect(result, isA<Success<void>>());
    final registry = registries.registries.single;
    expect(registry.licensePlate, 'ABC1D23');
    expect(registry.driver, 'Maria');
    expect(registry.authorId, 'user-1');
    expect(registry.unitId, 'u-1');
    expect(registry.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))),
        isTrue);
  });

  test('lastDriver devolve o registro mais recente da placa', () async {
    await controller.setRegistry(
      type: MovementType.entrada,
      licensePlate: 'ABC1D23',
      driver: 'Ana',
      documentNumber: '1',
      unitId: 'u-1',
      notes: '',
      authorId: 'user-1',
    );
    await controller.setRegistry(
      type: MovementType.saida,
      licensePlate: 'ABC1D23',
      driver: 'Beto',
      documentNumber: '2',
      unitId: 'u-1',
      notes: '',
      authorId: 'user-1',
    );

    final last = await controller.lastDriver('ABC1D23', 'u-1');
    expect(last?.driver, 'Beto');
  });

  test('lastDriver devolve null se a placa nunca foi registrada', () async {
    expect(await controller.lastDriver('ZZZ9Z99', 'u-1'), isNull);
  });

  test('report filtra movimentações do dia e da unidade', () async {
    final today = DateTime.now();
    await controller.setRegistry(
      type: MovementType.entrada,
      licensePlate: 'AAA1111',
      driver: 'Ana',
      documentNumber: '1',
      unitId: 'u-1',
      notes: '',
      authorId: 'user-1',
    );

    final result = await controller.report(today, 'u-1');
    expect(result.length, 1);
    expect(result.single.licensePlate, 'AAA1111');
  });
}
