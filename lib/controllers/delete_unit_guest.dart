import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> deleteUnitGuest(unitId, docId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;

  await db
      .collection('units')
      .doc(unitId)
      .collection('permissions')
      .doc(docId)
      .delete();

  return 'Usuário Removido';
}
