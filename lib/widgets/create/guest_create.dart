import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinela/controllers/get_unit.dart';
import 'package:sentinela/controllers/get_user_profile_by_email.dart';
import 'package:sentinela/controllers/is_unit_guest.dart';
import 'package:sentinela/controllers/is_unit_owner.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class UnitGuestCreate extends StatefulWidget {
  const UnitGuestCreate({Key? key, required this.unitId}) : super(key: key);

  final String unitId;

  @override
  State<UnitGuestCreate> createState() => _UnitGuestCreateState();
}

class _UnitGuestCreateState extends State<UnitGuestCreate> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;
  String _formFeedback = '';
  String _email = '';
  DateTime? _expiresAt;

  final _formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
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
            const SecondaryTitle(
              title: 'Caso queira dar acesso temporário defina uma data',
            ),
            TextFormField(
              controller: dateController,
              readOnly: true,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Expira em',
              ),
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2101),
                );

                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 0));
                  if (pickedTime != null) {
                    final date = pickedDate.toLocal();
                    setState(() {
                      _expiresAt = DateTime(date.year, date.month, date.day,
                          pickedTime.hour, pickedTime.minute);
                    });
                    DateFormat formatted = DateFormat("dd/MM/yyy à's' HH:mm");
                    dateController.text = formatted.format(_expiresAt!);
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final userProfile = await getUserProfileByEmail(_email);
                    if (userProfile.docs.isNotEmpty) {
                      final unit = await getUnit(widget.unitId);
                      final isGuest = await isUnitGuest(
                          userProfile.docs.first.id, widget.unitId);
                      final isOwner = await isUnitOwner(
                          userProfile.docs.first.id, widget.unitId);
                      if (!isGuest && !isOwner) {
                        db
                            .collection('units')
                            .doc(widget.unitId)
                            .collection('permissions')
                            .add(
                          {
                            'user_id': userProfile.docs.first.id,
                            'unit_id': widget.unitId,
                            'unit_name': unit.get('name'),
                            'expires_at': _expiresAt,
                            'role': 'guest'
                          },
                        );
                        setState(() {
                          _formFeedback = 'Acesso concedido';
                        });
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_formFeedback)),
                        );
                        Navigator.pushNamed(context, '/units');
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'O usuário já tem acesso a essa unidade')),
                        );
                      }
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Usuário não encontrado. Verifique o e-mail')),
                      );
                    }
                  }
                },
                child: const Text('Enviar'),
              ),
            )
          ],
        ));
  }
}
