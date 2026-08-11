import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentinela/core/app_constants.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/helpers/text_uppercase_formater.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

class RegistryCreate extends StatefulWidget {
  const RegistryCreate({super.key});

  @override
  State<RegistryCreate> createState() => _RegistryCreateState();
}

class _RegistryCreateState extends State<RegistryCreate> {
  String type = '';
  String licensePlate = '';
  String driver = '';
  String documentNumber = '';
  String unitId = '';
  String notes = '';

  final driverNameController = TextEditingController();
  final driverDocumentController = TextEditingController();
  final licensePlateController = TextEditingController();
  final notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future<void> _selectFirstUnit() async {
    final permissions = await ServiceLocator.instance.units.getMyPermissions();
    if (permissions.isNotEmpty && mounted) {
      setState(() => unitId = permissions.first.unitId);
    }
  }

  Future<void> _pickPlateByCamera() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 100,
    );
    if (pickedImage == null) return;

    final plate = await ServiceLocator.instance.plateRecognition.recognize(pickedImage.path);
    if (plate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum texto encontrado')),
        );
      }
      return;
    }

    setState(() {
      licensePlate = plate;
      licensePlateController.text = plate;
    });
    await _fillLastDriver(plate);
  }

  Future<void> _fillLastDriver(String plate) async {
    if (unitId.isEmpty) return;
    final Registry? last = await ServiceLocator.instance.registries.lastDriver(plate, unitId);
    if (!mounted) return;
    setState(() {
      if (last != null) {
        driver = last.driver;
        driverNameController.text = last.driver;
        driverDocumentController.text = last.documentNumber;
      } else {
        driver = '';
        driverNameController.text = '';
        driverDocumentController.text = '';
      }
    });
  }

  Future<void> _submit() async {
    if (unitId.isEmpty) {
      _showSnack('Selecione a unidade');
      return;
    }
    if (type.isEmpty) {
      _showSnack('Selecione o tipo de movimentação');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authorId = ServiceLocator.instance.auth.currentUserId ?? '';
    final result = await ServiceLocator.instance.registries.setRegistry(
      type: type,
      licensePlate: licensePlate,
      driver: driver,
      documentNumber: documentNumber,
      unitId: unitId,
      notes: notes,
      authorId: authorId,
    );
    if (!mounted) return;
    result.when(
      success: (_) {
        _showSnack('Registro Criado');
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() {
          type = '';
          licensePlate = '';
          driver = '';
          documentNumber = '';
          unitId = '';
          notes = '';
          driverNameController.text = '';
          driverDocumentController.text = '';
          licensePlateController.text = '';
          notesController.text = '';
        });
      },
      failure: (error) => _showSnack(error.message),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    _selectFirstUnit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const PageTitle(title: 'Registro'),
          const SecondaryTitle(title: 'Tipo de Movimentação'),
          Row(
            children: [
              Expanded(child: _buildTypeButton(MovementType.entrada)),
              const SizedBox(width: 10),
              Expanded(child: _buildTypeButton(MovementType.saida)),
            ],
          ),
          const SecondaryTitle(title: 'Unidades'),
          FutureBuilder<List<Permission>>(
            future: ServiceLocator.instance.units.getMyPermissions(),
            builder: (context, snapshot) {
              final permissions = snapshot.data ?? [];
              if (permissions.isEmpty) return const SizedBox();
              return SizedBox(
                height: 70.0 * (permissions.length / 3).ceilToDouble(),
                child: GridView.builder(
                  clipBehavior: Clip.none,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    childAspectRatio: 3.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    final data = permissions[index];
                    final selected = unitId == data.unitId;
                    return GestureDetector(
                      onTap: () => setState(() => unitId = data.unitId),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          data.unitName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          TextFormField(
            inputFormatters: [UpperCaseTextFormatter()],
            controller: licensePlateController,
            decoration: InputDecoration(
              suffixIcon: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: GestureDetector(
                  onTap: _pickPlateByCamera,
                  child: const Icon(Icons.camera_alt),
                ),
              ),
              labelText: 'Placa',
              helperMaxLines: 20,
              helperText:
                  'Caso o veículo já tenha se movimentado na sua unidade os dados do último condutor serão automaticamente preenchidos',
              helperStyle: const TextStyle(fontSize: 11),
            ),
            onChanged: (value) {
              setState(() => licensePlate = value.toUpperCase());
              if (value.length > 4) {
                _fillLastDriver(value.toUpperCase());
              }
            },
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo Obrigatório' : null,
          ),
          TextFormField(
            controller: driverNameController,
            decoration: const InputDecoration(labelText: 'Nome'),
            onChanged: (value) => setState(() => driver = value),
            validator: (value) =>
                value == null || value.isEmpty ? 'Campo Obrigatório' : null,
          ),
          TextFormField(
            controller: driverDocumentController,
            decoration: const InputDecoration(labelText: 'Documento'),
            onChanged: (value) => setState(() => documentNumber = value),
          ),
          TextFormField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Observações'),
            onChanged: (value) => setState(() => notes = value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Enviar'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTypeButton(String value) {
    final selected = type == value;
    return GestureDetector(
      onTap: () => setState(() => type = value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            width: selected ? 2 : 1,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
        ),
        padding: const EdgeInsets.all(10),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
