import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/widgets/lookup/driver_result_card.dart';

void main() {
  testWidgets('exibe dados do condutor', (tester) async {
    final registry = Registry(
      id: 'r-1',
      type: 'Entrada',
      licensePlate: 'ABC1D23',
      driver: 'Maria Souza',
      documentNumber: '123456',
      unitId: 'u-1',
      notes: 'entrega de carga',
      authorId: 'user-1',
      createdAt: DateTime(2026, 8, 18, 10, 30),
      authorName: 'Carlos',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DriverResultCard(registry: registry)),
      ),
    );

    expect(find.text('ABC1D23'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('entrega de carga'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text(formatDate(registry.createdAt)), findsOneWidget);
  });

  testWidgets('omite observações e autor quando vazios', (tester) async {
    final registry = Registry(
      id: 'r-1',
      type: 'Saída',
      licensePlate: 'ABC1D23',
      driver: 'João',
      documentNumber: '',
      unitId: 'u-1',
      notes: '',
      authorId: 'user-1',
      createdAt: DateTime(2026, 8, 18, 10, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DriverResultCard(registry: registry)),
      ),
    );

    expect(find.text('Observações'), findsNothing);
    expect(find.text('Registrado por'), findsNothing);
  });
}
