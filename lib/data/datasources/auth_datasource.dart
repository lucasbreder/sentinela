import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/app_errors.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/data/repositories/auth_profile_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  String? get currentUserEmail => FirebaseAuth.instance.currentUser?.email;

  @override
  bool get isEmailVerified => FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      throw const AuthError('Email ou senha incorretos');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.reload();
      } on FirebaseAuthException {
        // estado local permanece; verificação é best-effort
      }
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw const AuthError('A senha definida é fraca');
        case 'email-already-in-use':
          throw const AuthError('Esse usuário já existe');
        case 'invalid-email':
          throw const AuthError('Email inválido');
        default:
          throw const AuthError('Não foi possível criar a conta');
      }
    }
  }

  @override
  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      throw const AuthError('O usuário não existe');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AuthError('Usuário não autenticado');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email ?? '',
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException {
      throw const AuthError('Falha ao remover, verifique sua senha');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AuthError('Usuário não autenticado');
    }
    await user.delete();
  }
}

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<Profile?> getById(String id) async {
    final snap = await _db.collection(AppCollections.profiles).doc(id).get();
    if (!snap.exists) return null;
    return Profile.fromMap(snap.id, snap.data() ?? {});
  }

  @override
  Future<void> create(Profile profile) async {
    await _db.collection(AppCollections.profiles).doc(profile.id).set(profile.toMap());
  }
}
