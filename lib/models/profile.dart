import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String? name;
  final String? email;
  final String? registry;

  Profile({
    this.name,
    this.email,
    this.registry,
  });

  factory Profile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Profile(
      name: data?['name'],
      email: data?['email'],
      registry: data?['registry'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (email != null) "email": email,
      if (registry != null) "registry": registry,
    };
  }
}
