import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';

class NavScaffold extends StatefulWidget {
  const NavScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<NavScaffold> {
  String currentUserName = '';

  Future<void> _loadCurrentUserName() async {
    final uid = ServiceLocator.instance.auth.currentUserId;
    if (uid == null) return;
    final profile = await ServiceLocator.instance.profiles.getById(uid);
    if (!mounted) return;
    setState(() {
      currentUserName = profile?.name ?? '';
    });
  }

  Future<void> _signOut() async {
    await ServiceLocator.instance.auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  void initState() {
    _loadCurrentUserName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.nav),
          icon: const Icon(Icons.menu),
        ),
        actions: <Widget>[
          Row(
            children: [
              Text(
                currentUserName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Sair',
                onPressed: _signOut,
              ),
            ],
          )
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.all(25),
        width: MediaQuery.of(context).size.width,
        child: widget.child,
      ),
    );
  }
}
