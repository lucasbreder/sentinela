import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';

class InternalScaffold extends StatefulWidget {
  const InternalScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<InternalScaffold> createState() => _InternalScaffoldState();
}

class _InternalScaffoldState extends State<InternalScaffold> {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 114, 32, 59),
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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(left: 25, right: 25, top: 20),
          width: MediaQuery.of(context).size.width,
          child: widget.child,
        ),
      ),
    );
  }
}
