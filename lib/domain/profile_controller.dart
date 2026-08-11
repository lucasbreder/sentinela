import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/data/repositories/auth_profile_repository.dart';

class ProfileController {
  final ProfileRepository _profiles;

  ProfileController({required ProfileRepository profiles}) : _profiles = profiles;

  Future<Profile?> getByEmail(String email) => _profiles.getByEmail(email);
  Future<Profile?> getById(String id) => _profiles.getById(id);
}
