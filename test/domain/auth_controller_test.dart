import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/core/result.dart';
import 'package:sentinela/domain/auth_controller.dart';

import 'fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeUnitRepository units;
  late AuthController controller;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    units = FakeUnitRepository();
    controller = AuthController(auth: auth, profiles: profiles, units: units);
  });

  group('signIn', () {
    test('retorna sucesso e autentica usuário', () async {
      final result = await controller.signIn('a@b.com', '123456');
      expect(result, isA<Success<void>>());
      expect(auth.userId, 'user-1');
    });

    test('retorna falha com a mensagem do erro', () async {
      auth.signInError = const AuthError('Email ou senha incorretos');
      final result = await controller.signIn('a@b.com', 'errada');
      result.when(
        success: (_) => fail('não deveria ter sucesso'),
        failure: (error) => expect(error.message, 'Email ou senha incorretos'),
      );
    });
  });

  group('signUp', () {
    test('cria perfil e envia verificação de email', () async {
      final result = await controller.signUp(
        name: 'João',
        email: 'joao@example.com',
        password: '123456',
        registry: 'REG-1',
      );
      expect(result, isA<Success<void>>());
      expect(profiles.profiles['user-1']?.name, 'João');
      expect(profiles.profiles['user-1']?.registry, 'REG-1');
    });

    test('retorna falha se o email já existe', () async {
      auth.signUpError = const AuthError('Esse usuário já existe');
      final result = await controller.signUp(
        name: 'João',
        email: 'joao@example.com',
        password: '123456',
        registry: 'REG-1',
      );
      result.when(
        success: (_) => fail('não deveria ter sucesso'),
        failure: (error) => expect(error, isA<AuthError>()),
      );
    });
  });

  group('deleteAccount', () {
    test('reautentica, remove dados do usuário e exclui a conta', () async {
      final result = await controller.deleteAccount('senha');
      expect(result, isA<Success<void>>());
      expect(auth.reauthenticateCalls, 1);
      expect(auth.deleteAccountCalls, 1);
      expect(units.calls, contains('removeUserFromAllUnits'));
    });

    test('não remove dados se a senha estiver errada', () async {
      auth.reauthenticateShouldFail = true;
      final result = await controller.deleteAccount('errada');
      result.when(
        success: (_) => fail('não deveria ter sucesso'),
        failure: (error) =>
            expect(error.message, 'Falha ao remover, verifique sua senha'),
      );
      expect(units.calls, isNot(contains('removeUserFromAllUnits')));
      expect(auth.deleteAccountCalls, 0);
    });
  });

  test('signOut limpa o usuário atual', () async {
    await controller.signOut();
    expect(auth.userId, isNull);
  });

  test('sendPasswordReset retorna sucesso', () async {
    final result = await controller.sendPasswordReset('a@b.com');
    expect(result, isA<Success<void>>());
  });

  group('isEmailVerified', () {
    test('reflete o estado de verificação do usuário', () async {
      auth.emailVerified = false;
      expect(controller.isEmailVerified, isFalse);

      auth.emailVerified = true;
      expect(controller.isEmailVerified, isTrue);
    });
  });
}
