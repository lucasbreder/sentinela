import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/core/result.dart';
import 'package:sentinela/data/models/invite.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/data/repositories/unit_repository.dart';

class UnitController {
  final UnitRepository _units;

  UnitController({required UnitRepository units}) : _units = units;

  Future<List<Permission>> getMyPermissions() => _units.getMyPermissions();
  Future<List<Permission>> getGuestPermissions() => _units.getGuestPermissions();
  Future<Unit> getUnit(String unitId) => _units.getUnit(unitId);
  Future<bool> isOwner(String userId, String unitId) => _units.isOwner(userId, unitId);
  Future<bool> isGuest(String userId, String unitId) => _units.isGuest(userId, unitId);
  Future<List<Permission>> getUnitGuests(String unitId) => _units.getUnitGuests(unitId);

  Future<Result<Unit>> createUnit(String name) async {
    try {
      return Success(await _units.createUnit(name));
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível criar a unidade'));
    }
  }

  Future<Result<void>> addGuest(
    String unitId,
    String userId,
    DateTime? expiresAt,
  ) async {
    try {
      await _units.addGuest(unitId, userId, expiresAt);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível conceder acesso'));
    }
  }

  Future<Result<void>> deleteGuest(String unitId, String permissionId) async {
    try {
      await _units.deleteGuest(unitId, permissionId);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível remover o acesso'));
    }
  }

  Future<Result<void>> deleteUnit(String unitId) async {
    try {
      await _units.deleteUnit(unitId);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível excluir a unidade'));
    }
  }

  Future<List<Invite>> getPendingInvites() => _units.getPendingInvites();
  Future<List<Invite>> getUnitInvites(String unitId) => _units.getUnitInvites(unitId);

  Future<Result<void>> createInvite(
    String unitId,
    String email,
    DateTime? expiresAt,
  ) async {
    try {
      await _units.createInvite(unitId, email, expiresAt);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível enviar o convite'));
    }
  }

  Future<Result<void>> acceptInvite(String unitId) async {
    try {
      await _units.acceptInvite(unitId);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível aceitar o convite'));
    }
  }

  Future<Result<void>> deleteInvite(String unitId, String email) async {
    try {
      await _units.deleteInvite(unitId, email);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(OperationError('Não foi possível remover o convite'));
    }
  }
}
