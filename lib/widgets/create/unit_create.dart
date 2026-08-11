import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';

class UnitCreate extends StatefulWidget {
  const UnitCreate({super.key});

  @override
  State<UnitCreate> createState() => _UnitCreateState();
}

class _UnitCreateState extends State<UnitCreate> {
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
            decoration: const InputDecoration(labelText: 'Nome'),
            onChanged: (value) => setState(() => _unitName = value),
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo Obrigatório' : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final result = await ServiceLocator.instance.units.createUnit(_unitName);
                  result.when(
                    success: (_) {
                      setState(() => _formFeedback = 'Unidade Criada');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_formFeedback)),
                      );
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.units,
                        (route) => false,
                      );
                    },
                    failure: (error) {
                      setState(() => _formFeedback = error.message);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_formFeedback)),
                      );
                    },
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          )
        ],
      ),
    );
  }
}
