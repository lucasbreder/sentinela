import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> isUnitGuest(String userId, String unitId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  QuerySnapshot query = await db
      .collection('unit_guests')
      .where('user_id', isEqualTo: userId)
      .where('unit_id', isEqualTo: unitId)
      .get();

  return query.docs.isEmpty ? false : true;
}
