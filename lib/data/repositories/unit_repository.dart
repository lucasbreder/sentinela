import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/unit.dart';

abstract class UnitRepository {
  Future<Unit> createUnit(String name);
  Future<Unit> getUnit(String unitId);
  Future<List<Permission>> getMyPermissions();
  Future<List<Permission>> getGuestPermissions();
  Future<bool> isOwner(String userId, String unitId);
  Future<bool> isGuest(String userId, String unitId);
  Future<bool> isMember(String userId, String unitId);
  Future<List<Permission>> getUnitGuests(String unitId);
  Future<void> addGuest(String unitId, String userId, DateTime? expiresAt);
  Future<void> deleteGuest(String unitId, String permissionId);
  Future<void> deleteUnit(String unitId);
  Future<void> removeUserFromAllUnits(String userId);
}
