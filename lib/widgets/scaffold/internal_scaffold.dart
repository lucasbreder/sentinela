import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InternalScaffold extends StatefulWidget {
  const InternalScaffold({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<InternalScaffold> createState() => _InternalScaffoldState();
}

class _InternalScaffoldState extends State<InternalScaffold> {
  String currentUserName = '';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 114, 32, 59),
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
