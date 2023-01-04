import 'package:cloud_firestore/cloud_firestore.dart';

Future<QuerySnapshot> getUnitGuests(unitId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  final QuerySnapshot query = await db
      .collectionGroup('permissions')
      .where('role', isEqualTo: 'guest')
      .where('unit_id', isEqualTo: unitId)
      .get();
  return query;
}
