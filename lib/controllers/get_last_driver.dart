import 'package:cloud_firestore/cloud_firestore.dart';

Future<QuerySnapshot> getLastDriver(String licensePlate, String unitID) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  QuerySnapshot query = await db
      .collection('units')
      .doc(unitID)
      .collection('registries')
      .where('license_plate', isEqualTo: licensePlate)
      .orderBy('created_at', descending: true)
      .get();

  return query;
}
