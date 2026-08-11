import 'package:sentinela/core/app_constants.dart';

class Profile {
  const Profile({required this.id, this.name, this.email, this.registry});

  final String id;
  final String? name;
  final String? email;
  final String? registry;

  factory Profile.fromMap(String id, Map<String, dynamic> data) => Profile(
        id: id,
        name: data[AppFields.name],
        email: data[AppFields.email],
        registry: data[AppFields.registry],
      );

  Map<String, dynamic> toMap() => {
        if (name != null) AppFields.name: name,
        if (email != null) AppFields.email: email,
        if (registry != null) AppFields.registry: registry,
      };
}
