import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/widgets/title/page_title.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String _password = '';
  String _email = '';
  String _name = '';
  String _registry = '';
  String _formFeedback = '';

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Form(
              key: _formKey,
              child: Container(
                height: 700,
                padding: const EdgeInsets.fromLTRB(30, 100, 30, 0),
                child: Column(
                  children: [
                    const PageTitle(title: 'Crie sua conta'),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _name = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo Obrigatório';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _email = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo Obrigatório';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Matrícula',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _registry = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo Obrigatório';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                      ),
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          _password = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo Obrigatório';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Confirme sua senha',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo Obrigatório';
                        } else if (value != _password) {
                          return 'As senhas não são iguais';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              final newUser = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                email: _email,
                                password: _password,
                              );
                              setState(() {
                                _formFeedback = 'Usuário criado';
                              });
                              Navigator.pushNamed(context, '/');

                              FirebaseFirestore db = FirebaseFirestore.instance;
                              db
                                  .collection('profiles')
                                  .doc(newUser.user!.uid)
                                  .set({
                                'name': _name,
                                'registry': _registry,
                                'email': _email,
                              });
                              newUser.user!.sendEmailVerification();
                            } on FirebaseAuthException catch (e) {
                              if (e.code == 'weak-password') {
                                setState(() {
                                  _formFeedback = 'A senha definida é fraca';
                                });
                              } else if (e.code == 'email-already-in-use') {
                                setState(() {
                                  _formFeedback = 'Esse usuário já existe';
                                });
                              } else if (e.code == 'invalid-email') {
                                _formFeedback = 'Email inválido';
                              }
                            } catch (e) {
                              print(e);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_formFeedback)),
                            );
                          }
                        },
                        child: const Text('Enviar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
