import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/domain/flow_report_service.dart';

Registry _registry({required DateTime createdAt, required String type}) =>
    Registry(
      id: '',
      type: type,
      licensePlate: '',
      driver: '',
      documentNumber: '',
      unitId: '',
      notes: '',
      authorId: '',
      createdAt: createdAt,
    );

void main() {
  group('FlowReportService.hourly', () {
    test('returns all 24 hours with zero counts when empty', () {
      final flow = FlowReportService.hourly([]);

      expect(flow.length, 24);
      expect(flow.every((h) => h.entradas == 0 && h.saidas == 0), isTrue);
      expect(flow.first.hour, 0);
      expect(flow.last.hour, 23);
    });

    test('groups entries and exits by hour', () {
      final flow = FlowReportService.hourly([
        _registry(createdAt: DateTime(2026, 8, 18, 8, 15), type: MovementType.entrada),
        _registry(createdAt: DateTime(2026, 8, 18, 8, 45), type: MovementType.entrada),
        _registry(createdAt: DateTime(2026, 8, 18, 8, 59), type: MovementType.saida),
        _registry(createdAt: DateTime(2026, 8, 18, 9, 0), type: MovementType.saida),
      ]);

      expect(flow[8].entradas, 2);
      expect(flow[8].saidas, 1);
      expect(flow[9].entradas, 0);
      expect(flow[9].saidas, 1);
    });

    test('ignores unknown movement types', () {
      final flow = FlowReportService.hourly([
        _registry(createdAt: DateTime(2026, 8, 18, 8, 15), type: 'Desconhecido'),
      ]);

      expect(flow[8].entradas, 0);
      expect(flow[8].saidas, 0);
    });

    test('accumulates multiple entries on the same hour', () {
      final flow = FlowReportService.hourly([
        _registry(createdAt: DateTime(2026, 8, 18, 23, 1), type: MovementType.entrada),
        _registry(createdAt: DateTime(2026, 8, 18, 23, 2), type: MovementType.entrada),
        _registry(createdAt: DateTime(2026, 8, 18, 23, 3), type: MovementType.entrada),
      ]);

      expect(flow[23].entradas, 3);
      expect(flow[23].saidas, 0);
    });
  });
}
