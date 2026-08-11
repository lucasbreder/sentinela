import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/profile.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class UnitGuestCreate extends StatefulWidget {
  const UnitGuestCreate({super.key, required this.unitId});

  final String unitId;

  @override
  State<UnitGuestCreate> createState() => _UnitGuestCreateState();
}

class _UnitGuestCreateState extends State<UnitGuestCreate> {
  String _formFeedback = '';
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

    try {
      final Profile? userProfile =
          await ServiceLocator.instance.profiles.getByEmail(_email);
      if (userProfile == null) {
        _showSnack('Usuário não encontrado. Verifique o e-mail');
        return;
      }

      final isGuest =
          await ServiceLocator.instance.units.isGuest(userProfile.id, widget.unitId);
      final isOwner =
          await ServiceLocator.instance.units.isOwner(userProfile.id, widget.unitId);

      if (isGuest || isOwner) {
        _showSnack('O usuário já tem acesso a essa unidade');
        return;
      }

      final result = await ServiceLocator.instance.units
          .addGuest(widget.unitId, userProfile.id, _expiresAt);
      result.when(
        success: (_) {
          _showSnack('Acesso concedido');
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.units, (route) => false);
        },
        failure: (error) => _showSnack(error.message),
      );
    } catch (e) {
      _showSnack('Erro ao conceder acesso: $e');
    }
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
