import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/widgets/title/page_title.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

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
                    decoration: const InputDecoration(labelText: 'Nome'),
                    onChanged: (value) => setState(() => _name = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo Obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (value) => setState(() => _email = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo Obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Matrícula'),
                    onChanged: (value) => setState(() => _registry = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo Obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                    onChanged: (value) => setState(() => _password = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo Obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Confirme sua senha'),
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
                          final result = await ServiceLocator.instance.auth.signUp(
                            name: _name,
                            email: _email,
                            password: _password,
                            registry: _registry,
                          );
                          result.when(
                            success: (_) {
                              setState(() => _formFeedback = 'Usuário criado');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_formFeedback)),
                              );
                              Navigator.pushNamed(context, AppRoutes.login);
                            },
                            failure: (error) {
                              setState(() => _formFeedback = error.message);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_formFeedback)),
                              );
                            },
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
      ),
    );
  }
}
