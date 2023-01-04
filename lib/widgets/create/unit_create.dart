import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UnitCreate extends StatefulWidget {
  const UnitCreate({Key? key}) : super(key: key);

  @override
  State<UnitCreate> createState() => _UnitCreateState();
}

class _UnitCreateState extends State<UnitCreate> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  String _formFeedback = '';
  String _unitName = '';

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
              onChanged: (value) {
                setState(() {
                  _unitName = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo Obrigatório';
                }
                return null;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final unit = await db.collection('units').add({
                      'name': _unitName,
                    });
                    await db
                        .collection('units')
                        .doc(unit.id)
                        .collection('permissions')
                        .add(
                      {
                        'user_id': currentUser!.uid,
                        'unit_id': unit.id,
                        'unit_name': _unitName,
                        'role': 'owner'
                      },
                    );
                    setState(() {
                      _formFeedback = 'Unidade Criada';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_formFeedback)),
                    );
                    Navigator.pushNamed(context, '/units');
                  }
                },
                child: const Text('Enviar'),
              ),
            )
          ],
        ));
  }
}
