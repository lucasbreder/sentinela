import 'package:cloud_firestore/cloud_firestore.dart';

Future<DocumentSnapshot> getUserProfileById(String userId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentSnapshot query = await db.collection('profiles').doc(userId).get();
  return query;
}
