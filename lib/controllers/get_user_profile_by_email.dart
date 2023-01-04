import 'package:cloud_firestore/cloud_firestore.dart';

Future<QuerySnapshot> getUserProfileByEmail(String userEmail) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  QuerySnapshot query = await db
      .collection('profiles')
      .where('email', isEqualTo: userEmail)
      .get();
  return query;
}
