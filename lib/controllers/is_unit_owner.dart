import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> isUnitOwner(String userId, String unitId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  QuerySnapshot query = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: userId)
      .where('unit_id', isEqualTo: unitId)
      .get();

  return query.docs.isEmpty ? false : true;
}
