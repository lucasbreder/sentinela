import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future setCarRegistry(String type, String licensePlate, String driver,
    String documentNumber, String unitId, String notes) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  await db.collection('units').doc(unitId).collection('registries').add({
    'author_id': currentUser!.uid,
    'type': type,
    'license_plate': licensePlate,
    'driver': driver,
    'document_number': documentNumber,
    'unit_id': unitId,
    'notes': notes,
    'created_at': DateTime.now(),
  });
}
