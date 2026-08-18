import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/pages/plate_scanner_page.dart';
import 'package:sentinela/widgets/create/plate_input_field.dart';
import 'package:sentinela/widgets/lookup/driver_result_card.dart';
import 'package:sentinela/widgets/select/unit_selector.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class DriverLookup extends StatefulWidget {
  const DriverLookup({super.key});

  @override
  State<DriverLookup> createState() => _DriverLookupState();
}

class _DriverLookupState extends State<DriverLookup> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  late final Future<List<Unit>> _unitsFuture;
  String unitId = '';
  Registry? _result;
  bool _loading = false;

  Future<void> _selectFirstUnit() async {
    final units = await _unitsFuture;
    if (units.isNotEmpty && mounted) {
      setState(() => unitId = units.first.id);
    }
  }

  Future<void> _pickPlateByCamera() async {
    final plate = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PlateScannerPage()),
    );
    if (plate == null) {
      _showSnack('Nenhuma placa reconhecida');
      return;
    }
    if (!mounted) return;
    _licensePlateController.text = plate;
    await _lookup(plate);
  }

  Future<void> _lookup(String plate) async {
    if (unitId.isEmpty) {
      _showSnack('Selecione a unidade');
      return;
    }
    if (plate.length < 7) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final last = await ServiceLocator.instance.registries.lastDriver(plate, unitId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = last;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    unawaited(_lookup(_licensePlateController.text));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    _unitsFuture = ServiceLocator.instance.units.getActiveUnits();
    _selectFirstUnit();
    super.initState();
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle(title: 'Último Condutor'),
          const SecondaryTitle(title: 'Unidade'),
          FutureBuilder<List<Unit>>(
            future: _unitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final units = snapshot.data ?? [];
              if (units.isEmpty) return const SizedBox();
              return UnitSelector(
                units: units,
                selectedUnitId: unitId,
                onSelected: (id) => setState(() => unitId = id),
              );
            },
          ),
          const SizedBox(height: 8),
          const SecondaryTitle(title: 'Placa'),
          PlateInputField(
            controller: _licensePlateController,
            showCameraButton: !kIsWeb,
            onCameraTap: _pickPlateByCamera,
            validator: (value) =>
                value == null || value.length < 7 ? 'Digite a placa completa' : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buscar'),
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_result != null)
            DriverResultCard(registry: _result!)
          else if (_result == null && _licensePlateController.text.isNotEmpty)
            const Text('Nenhum registro encontrado para esta placa.'),
        ],
      ),
    );
  }
}
