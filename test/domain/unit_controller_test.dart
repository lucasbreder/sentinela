import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/result.dart';
import 'package:sentinela/domain/unit_controller.dart';

import 'fakes.dart';

void main() {
  late FakeUnitRepository units;
  late UnitController controller;

  setUp(() {
    units = FakeUnitRepository();
    controller = UnitController(units: units);
  });

  test('createUnit cria unidade e permissão de dono', () async {
    final result = await controller.createUnit('Condomínio A');
    result.when(
      success: (unit) {
        expect(unit.name, 'Condomínio A');
        expect(units.units[unit.id]?.name, 'Condomínio A');
      },
      failure: (error) => fail('não deveria falhar'),
    );
    expect(units.permissions.single.role, UserRole.owner);
  });

  test('isOwner retorna true apenas para donos', () async {
    await controller.createUnit('Condomínio A');
    expect(await controller.isOwner('user-1', 'u-1'), isTrue);
    expect(await controller.isOwner('user-2', 'u-1'), isFalse);
  });

  test('isGuest retorna true apenas para convidados', () async {
    await controller.createUnit('Condomínio A');
    await controller.addGuest('u-1', 'user-2', null);
    expect(await controller.isGuest('user-2', 'u-1'), isTrue);
    expect(await controller.isGuest('user-1', 'u-1'), isFalse);
  });

  test('addGuest registra permissão de convidado com expiração', () async {
    await controller.createUnit('Condomínio A');
    final expiry = DateTime.now().add(const Duration(days: 1));
    final result = await controller.addGuest('u-1', 'user-2', expiry);
    expect(result, isA<Success<void>>());
    final guest = units.permissions.singleWhere((p) => p.isGuest);
    expect(guest.userId, 'user-2');
    expect(guest.expiresAt, expiry);
  });

  test('deleteGuest remove a permissão', () async {
    await controller.createUnit('Condomínio A');
    await controller.addGuest('u-1', 'user-2', null);
    final guestId = units.permissions.singleWhere((p) => p.isGuest).id;
    await controller.deleteGuest('u-1', guestId);
    expect(units.permissions.any((p) => p.id == guestId), isFalse);
  });

  test('deleteUnit remove a unidade', () async {
    await controller.createUnit('Condomínio A');
    final result = await controller.deleteUnit('u-1');
    expect(result, isA<Success<void>>());
    expect(units.units.containsKey('u-1'), isFalse);
  });

  test('getUnitGuests devolve apenas convidados da unidade', () async {
    await controller.createUnit('Condomínio A');
    await controller.addGuest('u-1', 'user-2', null);
    final guests = await controller.getUnitGuests('u-1');
    expect(guests.length, 1);
    expect(guests.single.isGuest, isTrue);
  });

  test('createInvite registra convite sem expor perfil', () async {
    await controller.createUnit('Condomínio A');
    final result = await controller.createInvite('u-1', 'convidado@x.com', null);
    expect(result, isA<Success<void>>());
    expect(units.invites.single.email, 'convidado@x.com');
    expect(units.invites.single.unitId, 'u-1');
  });

  test('getPendingInvites devolve convites do usuário', () async {
    await controller.createUnit('Condomínio A');
    await controller.createInvite('u-1', 'convidado@x.com', null);
    final pending = await controller.getPendingInvites();
    expect(pending.length, 1);
    expect(pending.single.unitName, 'Condomínio A');
  });

  test('acceptInvite cria permissão de convidado e remove o convite', () async {
    await controller.createUnit('Condomínio A');
    await controller.createInvite('u-1', 'convidado@x.com', null);
    final result = await controller.acceptInvite('u-1');
    expect(result, isA<Success<void>>());
    expect(units.invites, isEmpty);
    expect(units.permissions.any((p) => p.isGuest && p.unitId == 'u-1'), isTrue);
  });

  test('declineInvite remove o convite sem criar permissão', () async {
    await controller.createUnit('Condomínio A');
    await controller.createInvite('u-1', 'convidado@x.com', null);
    final result = await controller.declineInvite('u-1');
    expect(result, isA<Success<void>>());
    expect(units.invites, isEmpty);
    expect(units.permissions.any((p) => p.isGuest && p.unitId == 'u-1'), isFalse);
  });
}
