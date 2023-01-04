import 'package:cloud_firestore/cloud_firestore.dart';

class Unit {
  String? name;

  Unit({
    this.name,
  });

  factory Unit.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Unit(
      name: data?['name'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
    };
  }
}
