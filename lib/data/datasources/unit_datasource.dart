import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/data/repositories/unit_repository.dart';

class FirebaseUnitRepository implements UnitRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<Unit> createUnit(String name) async {
    final uid = _currentUserId();
    final ref = _db.collection(AppCollections.units).doc();
    await ref.set({AppFields.name: name, AppFields.ownerId: uid});
    await ref.collection(AppCollections.permissions).doc(uid).set({
      AppFields.userId: uid,
      AppFields.unitId: ref.id,
      AppFields.unitName: name,
      AppFields.role: UserRole.owner,
      AppFields.ownerId: uid,
    });
    return Unit(id: ref.id, name: name, ownerId: uid);
  }

  @override
  Future<Unit> getUnit(String unitId) async {
    final snap = await _db.collection(AppCollections.units).doc(unitId).get();
    if (!snap.exists) {
      throw const NotFoundError('Unidade não encontrada');
    }
    return Unit.fromMap(snap.id, snap.data() ?? {});
  }

  @override
  Future<List<Permission>> getMyPermissions() async {
    final uid = _currentUserId();
    return [
      ...await _queryPermissions(uid: uid, role: UserRole.owner),
      ...await _queryPermissions(uid: uid, role: UserRole.guest, onlyActive: true),
    ];
  }

  @override
  Future<List<Permission>> getGuestPermissions() async {
    final uid = _currentUserId();
    return _queryPermissions(uid: uid, role: UserRole.guest, onlyActive: true);
  }

  @override
  Future<bool> isOwner(String userId, String unitId) async {
    final snap = await _db.collection(AppCollections.units).doc(unitId).get();
    if (!snap.exists) return false;
    return snap.data()?[AppFields.ownerId] == userId;
  }

  @override
  Future<bool> isGuest(String userId, String unitId) async {
    final q = await _db
        .collectionGroup(AppCollections.permissions)
        .where(AppFields.userId, isEqualTo: userId)
        .where(AppFields.unitId, isEqualTo: unitId)
        .where(AppFields.role, isEqualTo: UserRole.guest)
        .get();
    return q.docs.isNotEmpty;
  }

  @override
  Future<bool> isMember(String userId, String unitId) async {
    if (await isOwner(userId, unitId)) return true;
    final q = await _db
        .collectionGroup(AppCollections.permissions)
        .where(AppFields.userId, isEqualTo: userId)
        .where(AppFields.unitId, isEqualTo: unitId)
        .where(AppFields.role, isEqualTo: UserRole.guest)
        .get();
    if (q.docs.isEmpty) return false;
    final expiresAt = q.docs.first.data()[AppFields.expiresAt] as DateTime?;
    return expiresAt == null || expiresAt.isAfter(DateTime.now());
  }

  @override
  Future<List<Permission>> getUnitGuests(String unitId) async {
    await _requireOwner(unitId);
    final q = await _db
        .collectionGroup(AppCollections.permissions)
        .where(AppFields.unitId, isEqualTo: unitId)
        .where(AppFields.role, isEqualTo: UserRole.guest)
        .get();
    return q.docs.map((d) => Permission.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> addGuest(String unitId, String userId, DateTime? expiresAt) async {
    await _requireOwner(unitId);
    final unit = await getUnit(unitId);
    await _db
        .collection(AppCollections.units)
        .doc(unitId)
        .collection(AppCollections.permissions)
        .doc(userId)
        .set({
          AppFields.userId: userId,
          AppFields.unitId: unitId,
          AppFields.unitName: unit.name,
          AppFields.role: UserRole.guest,
          AppFields.ownerId: unit.ownerId,
          if (expiresAt != null) AppFields.expiresAt: expiresAt,
        });
  }

  @override
  Future<void> deleteGuest(String unitId, String permissionId) async {
    await _requireOwner(unitId);
    await _db
        .collection(AppCollections.units)
        .doc(unitId)
        .collection(AppCollections.permissions)
        .doc(permissionId)
        .delete();
  }

  @override
  Future<void> deleteUnit(String unitId) async {
    await _requireOwner(unitId);
    final permissions = await _db
        .collection(AppCollections.units)
        .doc(unitId)
        .collection(AppCollections.permissions)
        .get();
    final registries = await _db
        .collection(AppCollections.units)
        .doc(unitId)
        .collection(AppCollections.registries)
        .get();

    final batch = _db.batch();
    final unitRef = _db.collection(AppCollections.units).doc(unitId);
    for (final p in permissions.docs) {
      batch.delete(unitRef.collection(AppCollections.permissions).doc(p.id));
    }
    for (final r in registries.docs) {
      batch.delete(unitRef.collection(AppCollections.registries).doc(r.id));
    }
    batch.delete(unitRef);
    await batch.commit();
  }

  @override
  Future<void> removeUserFromAllUnits(String userId) async {
    final guestPermissions = await _db
        .collectionGroup(AppCollections.permissions)
        .where(AppFields.userId, isEqualTo: userId)
        .where(AppFields.role, isEqualTo: UserRole.guest)
        .get();
    final ownerPermissions = await _db
        .collectionGroup(AppCollections.permissions)
        .where(AppFields.userId, isEqualTo: userId)
        .where(AppFields.role, isEqualTo: UserRole.owner)
        .get();

    for (final p in guestPermissions.docs) {
      await _db
          .collection(AppCollections.units)
          .doc(p.data()[AppFields.unitId] as String)
          .collection(AppCollections.permissions)
          .doc(p.id)
          .delete();
    }

    for (final p in ownerPermissions.docs) {
      await deleteUnit(p.data()[AppFields.unitId] as String);
    }
  }

  Future<List<Permission>> _queryPermissions({
    required String uid,
    required String role,
    bool onlyActive = false,
  }) async {
    Query<Map<String, dynamic>> base = _db
        .collectionGroup(AppCollections.permissions)
        .where(AppFields.userId, isEqualTo: uid)
        .where(AppFields.role, isEqualTo: role);

    if (onlyActive) {
      final noExpiration = await base.where(AppFields.expiresAt, isNull: true).get();
      final active = await base
          .where(AppFields.expiresAt, isGreaterThan: DateTime.now())
          .get();
      return [
        ...noExpiration.docs,
        ...active.docs,
      ].map((d) => Permission.fromMap(d.id, d.data())).toList();
    }

    final q = await base.get();
    return q.docs.map((d) => Permission.fromMap(d.id, d.data())).toList();
  }

  String _currentUserId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const AuthError('Usuário não autenticado');
    }
    return uid;
  }

  Future<void> _requireOwner(String unitId) async {
    final uid = _currentUserId();
    if (!await isOwner(uid, unitId)) {
      throw const ForbiddenError('Sem permissão para gerenciar esta unidade');
    }
  }
}
