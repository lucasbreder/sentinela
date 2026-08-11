import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/core/result.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/data/repositories/registry_repository.dart';

class RegistryController {
  final RegistryRepository _registries;

  RegistryController({required RegistryRepository registries}) : _registries = registries;

  Future<Result<void>> setRegistry({
    required String type,
    required String licensePlate,
    required String driver,
    required String documentNumber,
    required String unitId,
    required String notes,
    required String authorId,
  }) async {
    try {
      await _registries.add(
        Registry(
          id: '',
          type: type,
          licensePlate: licensePlate,
          driver: driver,
          documentNumber: documentNumber,
          unitId: unitId,
          notes: notes,
          authorId: authorId,
          createdAt: DateTime.now(),
        ),
      );
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    }
  }

  Future<Registry?> lastDriver(String licensePlate, String unitId) =>
      _registries.lastDriver(licensePlate, unitId);

  Future<List<Registry>> report(DateTime date, String unitId) =>
      _registries.report(date, unitId);
}
