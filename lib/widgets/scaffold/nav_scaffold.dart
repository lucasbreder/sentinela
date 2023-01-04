import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NavScaffold extends StatefulWidget {
  const NavScaffold({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<NavScaffold> {
  String currentUserName = '';
  User? currentUser = FirebaseAuth.instance.currentUser;

  void getCurrentUser() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    FirebaseFirestore db = FirebaseFirestore.instance;

    DocumentSnapshot currentUserProfile =
        await db.collection('profiles').doc(currentUser!.uid).get();

    setState(() {
      currentUserName = currentUserProfile.get('name');
    });
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: GestureDetector(
        onTap: () {
          launchUrlString('https://linktr.ee/appsentinela');
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
          child: RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: 'Faça uma doação e ajude a manter esse app no ar',
                style: TextStyle(color: Colors.white),
              ),
              WidgetSpan(
                  child: SizedBox(
                width: 5,
              )),
              WidgetSpan(
                  child: Icon(
                Icons.favorite,
                color: Colors.white,
              ))
            ]),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/nav');
          },
          icon: const Icon(
            Icons.menu,
          ),
        ),
        actions: <Widget>[
          Row(
            children: [
              Text(
                currentUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'Sair',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushNamed(context, '/');
                },
              ),
            ],
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
        ),
        padding: const EdgeInsets.all(25),
        width: MediaQuery.of(context).size.width,
        child: widget.child,
      ),
    );
  }
}
