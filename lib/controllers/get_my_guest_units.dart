import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List> getMyGuestUnits() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  List mergedList = [];

  QuerySnapshot queryWithNoExpiration = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser!.uid)
      .where("expires_at", isNull: true)
      .where('role', isEqualTo: 'guest')
      .get();

  QuerySnapshot query = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser.uid)
      .where("expires_at", isGreaterThan: DateTime.now())
      .where('role', isEqualTo: 'guest')
      .get();

  mergedList.addAll(queryWithNoExpiration.docs);
  mergedList.addAll(query.docs);

  return mergedList;
}
