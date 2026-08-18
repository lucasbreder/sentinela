import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/widgets/create/plate_input_field.dart';

void main() {
  testWidgets('monta a placa a partir das 7 caixas', (tester) async {
    final controller = TextEditingController();
    String? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlateInputField(
            controller: controller,
            onChanged: (v) => emitted = v,
          ),
        ),
      ),
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(7));

    for (final (i, c) in ['A', 'B', 'C', '1', 'D', '2', '3'].indexed) {
      await tester.enterText(fields.at(i), c);
    }

    expect(controller.text, 'ABC1D23');
    expect(emitted, 'ABC1D23');
    controller.dispose();
  });

  testWidgets('distribui valor externo (câmera) nas caixas', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlateInputField(controller: controller),
        ),
      ),
    );

    controller.text = 'ABC6D23';
    await tester.pump();

    for (final (i, c) in ['A', 'B', 'C', '6', 'D', '2', '3'].indexed) {
      expect(
        tester.widget<TextField>(find.byType(TextField).at(i)).controller!.text,
        c,
      );
    }
    expect(controller.text, 'ABC6D23');
    controller.dispose();
  });

  testWidgets('valida placa incompleta', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PlateInputField(
              controller: controller,
              validator: (v) =>
                  v == null || v.length < 7 ? 'Digite a placa completa' : null,
            ),
          ),
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Digite a placa completa'), findsOneWidget);

    final fields = find.byType(TextField);
    for (final (i, c) in ['A', 'B', 'C', '1', 'D', '2', '3'].indexed) {
      await tester.enterText(fields.at(i), c);
    }
    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Digite a placa completa'), findsNothing);
    controller.dispose();
  });
}
