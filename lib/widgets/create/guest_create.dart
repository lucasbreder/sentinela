import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class UnitGuestCreate extends StatefulWidget {
  const UnitGuestCreate({super.key, required this.unitId});

  final String unitId;

  @override
  State<UnitGuestCreate> createState() => _UnitGuestCreateState();
}

class _UnitGuestCreateState extends State<UnitGuestCreate> {
  String _email = '';
  DateTime? _expiresAt;

  final _formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();

  Future<void> _pickExpiration() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (pickedTime == null) return;
    final date = pickedDate.toLocal();
    setState(() {
      _expiresAt = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
    });
    final formatted = DateFormat("dd/MM/yyyy 'às' HH:mm");
    dateController.text = formatted.format(_expiresAt!);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _grantAccess() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ServiceLocator.instance.units
        .createInvite(widget.unitId, _email, _expiresAt);
    if (!mounted) return;
    result.when(
      success: (_) {
        _showSnack('Convite enviado ao e-mail');
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.units, (route) => false);
      },
      failure: (error) => _showSnack(error.message),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: (value) => setState(() => _email = value),
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo Obrigatório' : null,
          ),
          const SecondaryTitle(
            title: 'Caso queira dar acesso temporário defina uma data',
          ),
          TextFormField(
            controller: dateController,
            readOnly: true,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(labelText: 'Expira em'),
            onTap: _pickExpiration,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: _grantAccess,
              child: const Text('Enviar'),
            ),
          )
        ],
      ),
    );
  }
}
