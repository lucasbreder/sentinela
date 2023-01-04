import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentinela/controllers/is_unit_owner.dart';

Future<String> deleteUnit(unitId) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  bool isOwner = await isUnitOwner(currentUser!.uid, unitId);

  if (isOwner) {
    QuerySnapshot permissions = await db
        .collection('units')
        .doc(unitId)
        .collection('permissions')
        .get();
    QuerySnapshot registries =
        await db.collection('units').doc(unitId).collection('registries').get();

    for (var permission in permissions.docs) {
      await db
          .collection('units')
          .doc(unitId)
          .collection('permissions')
          .doc(permission.id)
          .delete();
    }

    for (var registry in registries.docs) {
      await db
          .collection('units')
          .doc(unitId)
          .collection('registries')
          .doc(registry.id)
          .delete();
    }

    await db.collection('units').doc(unitId).delete();
  }

  return 'Unidade Removida';
}
