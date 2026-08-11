import 'package:sentinela/data/models/registry.dart';

abstract class RegistryRepository {
  Future<void> add(Registry registry);
  Future<Registry?> lastDriver(String licensePlate, String unitId);
  Future<List<Registry>> report(DateTime date, String unitId);
}
