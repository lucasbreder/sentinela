import 'package:cloud_firestore/cloud_firestore.dart';

Future<DocumentSnapshot> getUnit(String unitId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentSnapshot query = await db.collection('units').doc(unitId).get();
  return query;
}
