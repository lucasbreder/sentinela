import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sentinela/controllers/delete_user.dart';
import 'package:sentinela/widgets/list/my_units_list.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _resultDelete = '';

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return InternalScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(
            title: 'Perfil',
          ),
          currentUser != null
              ? Text(currentUser.email ?? '')
              : const SizedBox(),
          const SizedBox(
            height: 40,
          ),
          GestureDetector(
            onTap: (() => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text(
                        'Tem certeza que deseja excluir seu usuário?'),
                    content: SizedBox(
                      height: 210,
                      child: Column(
                        children: [
                          const Text(
                            'Ao excluir o usuário seus dados serão removidos do sistema. Todas as suas unidades e registro serão excluídos',
                          ),
                          Form(
                            key: _formKey,
                            child: TextFormField(
                              controller: passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Digite sua senha";
                                }
                                if (_resultDelete ==
                                    "Falha ao remover, verifique sua senha") {
                                  return _resultDelete;
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Senha',
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (passwordController.text.isNotEmpty) {
                            String result =
                                await deleteUser(passwordController.text);
                            setState(() {
                              _resultDelete = result;
                            });
                            if (result == "Usuário Removido") {
                              if (!mounted) return;
                              Navigator.pushNamed(context, '/');
                              await FirebaseAuth.instance.signOut();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result)),
                              );
                            } else {
                              _formKey.currentState!.validate();
                            }
                          } else {
                            _formKey.currentState!.validate();
                          }
                        },
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                )),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 1),
                borderRadius: const BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
              child: Text(
                'Excluir minha conta',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
