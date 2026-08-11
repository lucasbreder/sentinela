import 'package:sentinela/data/datasources/auth_datasource.dart';
import 'package:sentinela/data/datasources/registry_datasource.dart';
import 'package:sentinela/data/datasources/unit_datasource.dart';
import 'package:sentinela/domain/auth_controller.dart';
import 'package:sentinela/domain/plate_recognition_service.dart';
import 'package:sentinela/domain/profile_controller.dart';
import 'package:sentinela/domain/registry_controller.dart';
import 'package:sentinela/domain/unit_controller.dart';

/// Container simples de dependências. Controllers conhecem apenas interfaces
/// de repositório; a construção concreta (Firebase) fica centralizada aqui.
class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator instance = ServiceLocator._();

  late AuthController auth;
  late ProfileController profiles;
  late UnitController units;
  late RegistryController registries;
  late PlateRecognitionService plateRecognition;

  void init() {
    final profiles = FirebaseProfileRepository();
    final unitRepo = FirebaseUnitRepository();
    final registryRepo = FirebaseRegistryRepository(
      profileRepository: profiles,
      unitRepository: unitRepo,
    );
    final authRepo = FirebaseAuthRepository();

    auth = AuthController(auth: authRepo, profiles: profiles, units: unitRepo);
    this.profiles = ProfileController(profiles: profiles);
    units = UnitController(units: unitRepo);
    registries = RegistryController(registries: registryRepo);
    plateRecognition = PlateRecognitionService();
  }

  void overrideForTest({
    AuthController? auth,
    ProfileController? profiles,
    UnitController? units,
    RegistryController? registries,
    PlateRecognitionService? plateRecognition,
  }) {
    if (auth != null) this.auth = auth;
    if (profiles != null) this.profiles = profiles;
    if (units != null) this.units = units;
    if (registries != null) this.registries = registries;
    if (plateRecognition != null) this.plateRecognition = plateRecognition;
  }
}
