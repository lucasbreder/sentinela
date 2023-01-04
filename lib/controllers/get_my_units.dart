import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<List> getMyUnits() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  List mergedList = [];

  QuerySnapshot query = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser!.uid)
      .where('role', isEqualTo: 'owner')
      .get();

  QuerySnapshot queryGuestsWithNoExpiration = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser.uid)
      .where("expires_at", isNull: true)
      .where('role', isEqualTo: 'guest')
      .get();

  QuerySnapshot queryGuests = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser.uid)
      .where("expires_at", isGreaterThan: DateTime.now())
      .where('role', isEqualTo: 'guest')
      .get();

  mergedList.addAll(query.docs);
  mergedList.addAll(queryGuestsWithNoExpiration.docs);
  mergedList.addAll(queryGuests.docs);

  return mergedList;
}
