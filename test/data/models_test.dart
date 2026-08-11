import 'package:flutter_test/flutter_test.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/data/models/unit.dart';

void main() {
  test('Profile.fromMap/toMap preserva os dados', () {
    final profile = Profile.fromMap('u1', {'name': 'Ana', 'email': 'a@b.com', 'registry': 'R1'});
    expect(profile.id, 'u1');
    expect(profile.name, 'Ana');
    expect(profile.toMap(), {'name': 'Ana', 'email': 'a@b.com', 'registry': 'R1'});
  });

  test('Profile.fromMap omite campos ausentes', () {
    final profile = Profile.fromMap('u1', {'name': 'Ana'});
    expect(profile.email, isNull);
    expect(profile.toMap(), {'name': 'Ana'});
  });

  test('Unit.fromMap/toMap', () {
    final unit = Unit.fromMap('unit1', {'name': 'Condomínio'});
    expect(unit.id, 'unit1');
    expect(unit.name, 'Condomínio');
    expect(unit.toMap(), {'name': 'Condomínio'});
  });

  test('Registry.fromMap/toMap preserva os campos', () {
    final createdAt = DateTime(2024, 1, 1);
    final registry = Registry.fromMap('r1', {
      AppFields.type: 'Entrada',
      AppFields.licensePlate: 'ABC1D23',
      AppFields.driver: 'Maria',
      AppFields.documentNumber: '123',
      AppFields.unitId: 'u1',
      AppFields.notes: 'obs',
      AppFields.authorId: 'u9',
      AppFields.createdAt: createdAt,
    });
    expect(registry.id, 'r1');
    expect(registry.licensePlate, 'ABC1D23');
    expect(registry.createdAt, createdAt);
    expect(registry.toMap()[AppFields.type], 'Entrada');
  });

  test('Permission distingue dono e convidado', () {
    final owner = Permission.fromMap('p1', {
      AppFields.userId: 'u1',
      AppFields.unitId: 'u1',
      AppFields.unitName: 'Condomínio',
      AppFields.role: UserRole.owner,
    });
    expect(owner.isOwner, isTrue);
    expect(owner.isGuest, isFalse);

    final guest = Permission.fromMap('p2', {
      AppFields.userId: 'u2',
      AppFields.unitId: 'u1',
      AppFields.unitName: 'Condomínio',
      AppFields.role: UserRole.guest,
      AppFields.expiresAt: DateTime(2025, 1, 1),
    });
    expect(guest.isGuest, isTrue);
    expect(guest.expiresAt, isNotNull);
  });
}
