import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/data/datasources/auth_datasource.dart';
import 'package:sentinela/data/datasources/timestamp_util.dart';
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
    // created_at é definido pelo servidor para casar com request.time nas
    // Security Rules (impede adulteração da linha do tempo de acessos).
    data[AppFields.createdAt] = FieldValue.serverTimestamp();
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
    final data = normalizeTimestamps(q.docs.first.data(), [AppFields.createdAt]);
    return Registry.fromMap(q.docs.first.id, data);
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

    final registries = q.docs
        .map((doc) => Registry.fromMap(
              doc.id,
              normalizeTimestamps(doc.data(), [AppFields.createdAt]),
            ))
        .toList();

    return _enrichAuthors(registries);
  }

  Future<List<Registry>> _enrichAuthors(List<Registry> registries) async {
    // Só o próprio usuário pode ler o próprio perfil (regra de profiles).
    // Nunca lemos o perfil de outro autor — isso seria permission-denied e
    // vazaria PII. Autores de registros sem name/registry desnormalizados são
    // preenchidos na criação (add) ou por backfill de dados.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Profile? ownProfile;
    final result = <Registry>[];
    for (final registry in registries) {
      if (registry.authorName != null && registry.authorRegistry != null) {
        result.add(registry);
        continue;
      }
      if (uid != null && registry.authorId == uid) {
        ownProfile ??= await _profileRepository.getById(uid);
        final profile = ownProfile;
        result.add(profile != null
            ? registry.copyWith(
                authorName: profile.name, authorRegistry: profile.registry)
            : registry);
      } else {
        result.add(registry);
      }
    }
    return result;
  }
}
