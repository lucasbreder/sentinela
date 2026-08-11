import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/widgets/scaffold/internal_scaffold.dart';
import 'package:sentinela/widgets/title/page_title.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _resultDelete = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _email = ServiceLocator.instance.auth.currentUserEmail ?? '';
  }

  Future<void> _deleteAccount() async {
    final password = passwordController.text;
    if (password.isEmpty) {
      _formKey.currentState!.validate();
      return;
    }
    final result = await ServiceLocator.instance.auth.deleteAccount(password);
    if (!mounted) return;
    result.when(
      success: (_) {
        ServiceLocator.instance.auth.signOut();
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário Removido')),
        );
      },
      failure: (error) {
        setState(() => _resultDelete = error.message);
        _formKey.currentState!.validate();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InternalScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(title: 'Perfil'),
          Text(_email),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Tem certeza que deseja excluir seu usuário?'),
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
                              return 'Digite sua senha';
                            }
                            if (_resultDelete == 'Falha ao remover, verifique sua senha') {
                              return _resultDelete;
                            }
                            return null;
                          },
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Senha'),
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
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteAccount();
                    },
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 1),
                borderRadius: const BorderRadius.all(Radius.circular(20)),
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
