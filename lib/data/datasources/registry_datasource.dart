import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/data/datasources/auth_datasource.dart';
import 'package:sentinela/data/datasources/unit_datasource.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/data/repositories/auth_profile_repository.dart';
import 'package:sentinela/data/repositories/registry_repository.dart';
import 'package:sentinela/data/repositories/unit_repository.dart';

class FirebaseRegistryRepository implements RegistryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProfileRepository _profileRepository;
  final UnitRepository _units;

  FirebaseRegistryRepository({
    ProfileRepository? profileRepository,
    UnitRepository? unitRepository,
  })  : _profileRepository = profileRepository ?? FirebaseProfileRepository(),
        _units = unitRepository ?? FirebaseUnitRepository();

  @override
  Future<void> add(Registry registry) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const AuthError('Usuário não autenticado');
    }
    if (!await _units.isMember(uid, registry.unitId)) {
      throw const ForbiddenError('Sem permissão para registrar nesta unidade');
    }
    final author = await _profileRepository.getById(registry.authorId);
    final data = registry
        .copyWith(authorName: author?.name, authorRegistry: author?.registry)
        .toMap();
    await _db
        .collection(AppCollections.units)
        .doc(registry.unitId)
        .collection(AppCollections.registries)
        .add(data);
  }

  @override
  Future<Registry?> lastDriver(String licensePlate, String unitId) async {
    final q = await _db
        .collection(AppCollections.units)
        .doc(unitId)
        .collection(AppCollections.registries)
        .where(AppFields.licensePlate, isEqualTo: licensePlate)
        .orderBy(AppFields.createdAt, descending: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Registry.fromMap(q.docs.first.id, q.docs.first.data());
  }

  @override
  Future<List<Registry>> report(DateTime date, String unitId) async {
    final ceil = date.add(const Duration(days: 1));
    final q = await _db
        .collection(AppCollections.units)
        .doc(unitId)
        .collection(AppCollections.registries)
        .where(AppFields.createdAt, isGreaterThan: date, isLessThan: ceil)
        .where(AppFields.unitId, isEqualTo: unitId)
        .orderBy(AppFields.createdAt, descending: true)
        .get();

    return q.docs.map((doc) => Registry.fromMap(doc.id, doc.data())).toList();
  }
}
