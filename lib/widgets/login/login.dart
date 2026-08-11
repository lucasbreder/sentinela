import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';

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
                                final result = await ServiceLocator.instance.auth
                                    .signIn(_email, _password);
                                if (!mounted) return;
                                result.when(
                                  success: (_) {
                                    if (!ServiceLocator
                                        .instance.auth.isEmailVerified) {
                                      setState(() {
                                        _loginFeedback =
                                            'Confirme seu e-mail antes de entrar';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_loginFeedback),
                                        ),
                                      );
                                      return;
                                    }
                                    Navigator.pushNamed(
                                        context, AppRoutes.units);
                                  },
                                  failure: (error) {
                                    setState(() {
                                      _loginFeedback = error.message;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(_loginFeedback)),
                                    );
                                  },
                                );
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
                                          final result = await ServiceLocator
                                              .instance
                                              .auth
                                              .sendPasswordReset(_email);
                                          if (!mounted) return;
                                          result.when(
                                            success: (_) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('Email Enviado')),
                                              );
                                            },
                                            failure: (error) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content:
                                                        Text(error.message)),
                                              );
                                            },
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
                                  Navigator.pushNamed(context, AppRoutes.signin);
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
