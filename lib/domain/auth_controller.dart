import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/core/result.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/data/repositories/auth_profile_repository.dart';
import 'package:sentinela/data/repositories/unit_repository.dart';

class AuthController {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final UnitRepository _units;

  AuthController({
    required AuthRepository auth,
    required ProfileRepository profiles,
    required UnitRepository units,
  })  : _auth = auth,
        _profiles = profiles,
        _units = units;

  String? get currentUserId => _auth.currentUserId;
  String? get currentUserEmail => _auth.currentUserEmail;
  bool get isEmailVerified => _auth.isEmailVerified;

  Future<Result<void>> signIn(String email, String password) async {
    try {
      await _auth.signIn(email, password);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
    required String registry,
  }) async {
    try {
      await _auth.signUp(email, password);
      final uid = _auth.currentUserId;
      if (uid == null) {
        throw const AuthError('Falha ao criar o usuário');
      }
      await _profiles.create(Profile(id: uid, name: name, email: email, registry: registry));
      await _auth.sendEmailVerification();
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    }
  }

  Future<Result<void>> deleteAccount(String password) async {
    try {
      await _auth.reauthenticate(password);
      final uid = _auth.currentUserId;
      if (uid != null) {
        await _units.removeUserFromAllUnits(uid);
      }
      await _auth.deleteAccount();
      return const Success(null);
    } on AppError catch (e) {
      return Failure(e);
    }
  }
}
