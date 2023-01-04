import 'package:firebase_auth/firebase_auth.dart';

Future<String> forgotPassword(email) async {
  final auth = FirebaseAuth.instance;

  try {
    await auth.sendPasswordResetEmail(email: email);
  } on FirebaseAuthException catch (e) {
    return 'O usuário não existe';
  }

  return 'Email Enviado';
}
