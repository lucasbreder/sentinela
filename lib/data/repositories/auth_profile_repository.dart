import 'package:sentinela/data/models/profile.dart';

abstract class AuthRepository {
  String? get currentUserId;
  String? get currentUserEmail;
  bool get isEmailVerified;

  Future<void> signIn(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();
  Future<void> reauthenticate(String password);
  Future<void> deleteAccount();
}

abstract class ProfileRepository {
  Future<Profile?> getById(String id);
  Future<void> create(Profile profile);
}
