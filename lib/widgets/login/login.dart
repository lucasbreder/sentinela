import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/controllers/forgot_password.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _loginFeedback = '';
  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Stack(
              children: [
                Positioned(
                  top: 240,
                  left: 45,
                  child: Container(
                      width: MediaQuery.of(context).size.width - 80,
                      height: 345,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6)),
                        border: Border.all(
                          width: 0.5,
                          color: Colors.white,
                        ),
                      )),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Image.asset('assets/images/bg-login.png'),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(80, 180, 80, 60),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Flexible(
                              child: Text(
                                'CONTROLE DE GUARDA',
                                style: TextStyle(
                                  height: 1.2,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 122, 163, 210),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Image.asset(
                                'assets/images/sentinela-icon.png',
                                width: 80,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.white),
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
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Senha',
                            labelStyle: TextStyle(color: Colors.white),
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
                        Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.only(top: 20),
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                try {
                                  await FirebaseAuth.instance
                                      .signInWithEmailAndPassword(
                                    email: _email,
                                    password: _password,
                                  );
                                  Navigator.pushNamed(context, '/units');
                                } on FirebaseAuthException catch (e) {
                                  if (e.toString().isNotEmpty) {
                                    setState(() {
                                      _loginFeedback =
                                          'Email ou senha incorretos';
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(_loginFeedback)),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('Entrar'),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: GestureDetector(
                            onTap: (() => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: const Text(
                                        'O email será enviado para o endereço digitado na tela anterior'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'Cancel'),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          String resultDelete =
                                              await forgotPassword(_email);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(resultDelete)),
                                          );
                                          return Navigator.pop(context, 'OK');
                                        },
                                        child: const Text('Enviar'),
                                      ),
                                    ],
                                  ),
                                )),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Esqueci a Senha',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            const Text(
                              'Ainda não tem uma conta?',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(35, 10, 35, 10),
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(6)),
                                color: Color.fromARGB(255, 46, 84, 127),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/signin');
                                },
                                child: const Text(
                                  'Cadastre-se',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
