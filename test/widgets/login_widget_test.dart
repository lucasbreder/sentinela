import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/domain/auth_controller.dart';
import 'package:sentinela/widgets/login/login.dart';

import '../domain/fakes.dart';

void main() {
  setUp(() {
    final authRepo = FakeAuthRepository();
    final profRepo = FakeProfileRepository();
    final unitRepo = FakeUnitRepository();
    ServiceLocator.instance.overrideForTest(
      auth: AuthController(auth: authRepo, profiles: profRepo, units: unitRepo),
    );
  });

  testWidgets('valida campos vazios no login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Login()));

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Campo Obrigatório'), findsNWidgets(2));
  });
}
