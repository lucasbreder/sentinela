import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sentinela/controllers/delete_unit.dart';

Future<String> deleteUser(String password) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User currentUser = FirebaseAuth.instance.currentUser!;

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: currentUser.email ?? '',
      password: password,
    );
  } on FirebaseAuthException {
    return 'Falha ao remover, verifique sua senha';
  }

  QuerySnapshot permissions = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser.uid)
      .where('role', isEqualTo: 'guest')
      .get();

  for (var permission in permissions.docs) {
    await db
        .collection('units')
        .doc(permission.get('unit_id'))
        .collection('permissions')
        .doc(permission.id)
        .delete();
  }

  QuerySnapshot ownerPermissions = await db
      .collectionGroup('permissions')
      .where('user_id', isEqualTo: currentUser.uid)
      .where('role', isEqualTo: 'owner')
      .get();

  for (var permission in ownerPermissions.docs) {
    await deleteUnit(permission.get('unit_id'));
  }

  await currentUser.delete();

  return 'Usuário Removido';
}
