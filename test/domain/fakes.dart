import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/data/models/invite.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/data/repositories/auth_profile_repository.dart';
import 'package:sentinela/data/repositories/registry_repository.dart';
import 'package:sentinela/data/repositories/unit_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.userId = 'user-1', this.email = 'user@example.com'});

  String? userId;
  String? email;
  AuthError? signInError;
  AuthError? signUpError;
  bool reauthenticateShouldFail = false;
  int reauthenticateCalls = 0;
  int deleteAccountCalls = 0;
  bool emailVerified = true;

  @override
  String? get currentUserId => userId;

  @override
  String? get currentUserEmail => email;

  @override
  bool get isEmailVerified => emailVerified;

  @override
  Future<void> signIn(String email, String password) async {
    if (signInError != null) throw signInError!;
    userId = 'user-1';
  }

  @override
  Future<void> signUp(String email, String password) async {
    if (signUpError != null) throw signUpError!;
    userId = 'user-1';
    this.email = email;
  }

  @override
  Future<void> signOut() async {
    userId = null;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reauthenticate(String password) async {
    reauthenticateCalls++;
    if (reauthenticateShouldFail) {
      throw const AuthError('Falha ao remover, verifique sua senha');
    }
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls++;
    userId = null;
  }
}

class FakeProfileRepository implements ProfileRepository {
  final Map<String, Profile> profiles = {};

  @override
  Future<Profile?> getById(String id) async => profiles[id];

  @override
  Future<void> create(Profile profile) async {
    profiles[profile.id] = profile;
  }
}

class FakeUnitRepository implements UnitRepository {
  final Map<String, Unit> units = {};
  final List<Permission> permissions = [];
  final List<Invite> invites = [];
  final List<String> calls = [];

  @override
  Future<Unit> createUnit(String name) async {
    calls.add('createUnit');
    final id = 'u-${units.length + 1}';
    final unit = Unit(id: id, name: name);
    units[id] = unit;
    permissions.add(Permission(
      id: 'p-${permissions.length + 1}',
      userId: 'user-1',
      unitId: id,
      unitName: name,
      role: UserRole.owner,
    ));
    return unit;
  }

  @override
  Future<Unit> getUnit(String unitId) async {
    final unit = units[unitId];
    if (unit == null) throw const NotFoundError('Unidade não encontrada');
    return unit;
  }

  @override
  Future<List<Permission>> getMyPermissions() async => List.of(permissions);

  @override
  Future<List<Permission>> getGuestPermissions() async =>
      permissions.where((p) => p.isGuest).toList();

  @override
  Future<bool> isOwner(String userId, String unitId) async =>
      permissions.any((p) => p.userId == userId && p.unitId == unitId && p.isOwner);

  @override
  Future<bool> isGuest(String userId, String unitId) async =>
      permissions.any((p) => p.userId == userId && p.unitId == unitId && p.isGuest);

  @override
  Future<bool> isMember(String userId, String unitId) async {
    if (await isOwner(userId, unitId)) return true;
    final guest = permissions
        .where((p) => p.userId == userId && p.unitId == unitId && p.isGuest);
    for (final p in guest) {
      final exp = p.expiresAt;
      if (exp == null || exp.isAfter(DateTime.now())) return true;
    }
    return false;
  }

  @override
  Future<List<Permission>> getUnitGuests(String unitId) async =>
      permissions.where((p) => p.unitId == unitId && p.isGuest).toList();

  @override
  Future<void> addGuest(String unitId, String userId, DateTime? expiresAt) async {
    calls.add('addGuest');
    final unit = units[unitId];
    permissions.add(Permission(
      id: 'p-${permissions.length + 1}',
      userId: userId,
      unitId: unitId,
      unitName: unit?.name ?? '',
      role: UserRole.guest,
      expiresAt: expiresAt,
    ));
  }

  @override
  Future<void> deleteGuest(String unitId, String permissionId) async {
    calls.add('deleteGuest');
    permissions.removeWhere((p) => p.id == permissionId);
  }

  @override
  Future<void> deleteUnit(String unitId) async {
    calls.add('deleteUnit');
    units.remove(unitId);
    permissions.removeWhere((p) => p.unitId == unitId);
  }

  @override
  Future<void> removeUserFromAllUnits(String userId) async {
    calls.add('removeUserFromAllUnits');
  }

  @override
  Future<void> createInvite(String unitId, String email, DateTime? expiresAt) async {
    calls.add('createInvite');
    final unit = units[unitId];
    invites.add(Invite(
      email: email,
      unitId: unitId,
      unitName: unit?.name ?? '',
      ownerId: unit?.ownerId,
      expiresAt: expiresAt,
    ));
  }

  @override
  Future<List<Invite>> getPendingInvites() async => List.of(invites);

  @override
  Future<List<Invite>> getUnitInvites(String unitId) async =>
      invites.where((i) => i.unitId == unitId).toList();

  @override
  Future<void> deleteInvite(String unitId, String email) async {
    calls.add('deleteInvite');
    invites.removeWhere((i) => i.unitId == unitId && i.email == email);
  }

  @override
  Future<void> acceptInvite(String unitId) async {
    calls.add('acceptInvite');
    String? unitName;
    for (final i in invites) {
      if (i.unitId == unitId) {
        unitName = i.unitName;
        break;
      }
    }
    invites.removeWhere((i) => i.unitId == unitId);
    permissions.add(Permission(
      id: 'p-${permissions.length + 1}',
      userId: 'user-1',
      unitId: unitId,
      unitName: unitName ?? '',
      role: UserRole.guest,
    ));
  }
}

class FakeRegistryRepository implements RegistryRepository {
  final List<Registry> registries = [];

  @override
  Future<void> add(Registry registry) async {
    registries.add(registry);
  }

  @override
  Future<Registry?> lastDriver(String licensePlate, String unitId) async {
    for (final r in registries.reversed) {
      if (r.licensePlate == licensePlate) return r;
    }
    return null;
  }

  @override
  Future<List<Registry>> report(DateTime date, String unitId) async {
    final ceil = date.add(const Duration(days: 1));
    return registries
        .where((r) => r.unitId == unitId && r.createdAt.isAfter(date) && r.createdAt.isBefore(ceil))
        .toList();
  }
}
