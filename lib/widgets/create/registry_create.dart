import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentinela/controllers/get_last_driver.dart';
import 'package:sentinela/controllers/get_my_units.dart';
import 'package:sentinela/controllers/set_car_registry.dart';
import 'package:sentinela/helpers/is_uppercase.dart';
import 'package:sentinela/helpers/text_uppercase_formater.dart';
import 'package:sentinela/widgets/title/page_title.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class RegistryCreate extends StatefulWidget {
  const RegistryCreate({Key? key}) : super(key: key);

  @override
  State<RegistryCreate> createState() => _RegistryCreateState();
}

class _RegistryCreateState extends State<RegistryCreate> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  String formFeedback = '';
  String authorId = '';
  String type = '';
  String licensePlate = '';
  String driver = '';
  String documentNumber = '';
  String unitId = '';
  String notes = '';
  String createdAt = '';

  final driverNameController = TextEditingController();
  final driverDocumentController = TextEditingController();
  final licensePlateController = TextEditingController();
  final notesController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void selectFirstUnit() async {
    final units = await getMyUnits();

    setState(() {
      unitId = units[0].get('unit_id');
    });
  }

  @override
  void initState() {
    selectFirstUnit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PageTitle(title: 'Registro'),
              Column(
                children: [
                  const SecondaryTitle(title: 'Tipo de Movimentação'),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              type = 'Entrada';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 1,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6)),
                              color: type == 'Entrada'
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.transparent,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'Entrada',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: type == 'Entrada'
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.surface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              type = 'Saída';
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 1,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6)),
                              color: type == 'Saída'
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.transparent,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              'Saída',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: type == 'Saída'
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.surface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SecondaryTitle(title: 'Unidades'),
              Flexible(
                child: FutureBuilder(
                  future: getMyUnits(),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data.length > 0) {
                        return Column(
                          children: [
                            SizedBox(
                              height: 70.0 *
                                  (snapshot.data.length / 3).ceilToDouble(),
                              child: GridView.builder(
                                  clipBehavior: Clip.none,
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 300,
                                    childAspectRatio: 3.2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 20,
                                  ),
                                  itemCount: snapshot.data.length,
                                  itemBuilder: ((context, index) {
                                    final data = snapshot.data[index];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          unitId = data.get('unit_id');
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .background,
                                            width: 1,
                                          ),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(6)),
                                          color: unitId == data.get('unit_id')
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .background
                                              : Colors.transparent,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: Text(
                                          data.get('unit_name'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: unitId == data.get('unit_id')
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .background,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  })),
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
              ),
              TextFormField(
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                controller: licensePlateController,
                decoration: InputDecoration(
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(
                        top: 15), // add padding to adjust icon
                    child: GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();

                        final XFile? pickedImage = await picker.pickImage(
                          source: ImageSource.camera,
                          preferredCameraDevice: CameraDevice.rear,
                          imageQuality: 100,
                        );

                        if (pickedImage != null) {
                          final textRecognizer = TextRecognizer(
                              script: TextRecognitionScript.latin);

                          final inputImage =
                              InputImage.fromFilePath(pickedImage.path);
                          final RecognizedText recognizedText =
                              await textRecognizer.processImage(inputImage);

                          if (recognizedText.blocks.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nenhum texto encontrado'),
                              ),
                            );
                          }

                          for (TextBlock block in recognizedText.blocks) {
                            if (block.text.isNotEmpty &&
                                isUppercase(block.text) &&
                                block.text.length < 10) {
                              final String text =
                                  block.text.replaceAll(RegExp(r"\n"), "-");
                              final QuerySnapshot lastDriver =
                                  await getLastDriver(text, unitId);

                              if (lastDriver.size > 0) {
                                setState(() {
                                  driver = lastDriver.docs[0].get('driver');
                                  driverNameController.text =
                                      lastDriver.docs[0].get('driver');
                                  driverDocumentController.text =
                                      lastDriver.docs[0].get('document_number');
                                });
                              } else {
                                driverNameController.text = '';
                                driverDocumentController.text = '';
                              }
                              setState(() {
                                licensePlate = text;
                                licensePlateController.text = text;
                              });

                              textRecognizer.close();
                            }
                          }
                        }
                      },
                      child: const Icon(
                        Icons.camera_alt,
                      ),
                    ),
                  ),
                  labelText: 'Placa',
                  helperMaxLines: 20,
                  helperText:
                      "Caso o veículo já tenha se movimentado na sua unidade os dados do último condutor serão automaticamente preenchidos",
                  helperStyle: const TextStyle(fontSize: 11),
                ),
                onChanged: (value) async {
                  setState(() {
                    licensePlate = value.toUpperCase();
                  });

                  if (value.length > 4) {
                    final QuerySnapshot lastDriver =
                        await getLastDriver(value, unitId);

                    if (lastDriver.size > 0) {
                      setState(() {
                        driver = lastDriver.docs[0].get('driver');
                        driverNameController.text =
                            lastDriver.docs[0].get('driver');
                        driverDocumentController.text =
                            lastDriver.docs[0].get('document_number');
                      });
                    } else {
                      driverNameController.text = '';
                      driverDocumentController.text = '';
                    }
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo Obrigatório';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: driverNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                ),
                onChanged: (value) {
                  setState(() {
                    driver = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo Obrigatório';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: driverDocumentController,
                decoration: const InputDecoration(
                  labelText: 'Documento',
                ),
                onChanged: (value) {
                  setState(() {
                    documentNumber = value;
                  });
                },
              ),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                ),
                onChanged: (value) {
                  setState(() {
                    notes = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    if (unitId == '') {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione a unidade'),
                        ),
                      );
                    } else if (type == '') {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione o tipo de movimentação'),
                        ),
                      );
                    } else {
                      if (_formKey.currentState!.validate()) {
                        setCarRegistry(type, licensePlate, driver,
                            documentNumber, unitId, notes);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registro Criado')),
                        );
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          formFeedback = '';
                          authorId = '';
                          type = '';
                          licensePlate = '';
                          driver = '';
                          documentNumber = '';
                          notes = '';
                          createdAt = '';
                          driverNameController.text = '';
                          driverDocumentController.text = '';
                          licensePlateController.text = '';
                          notesController.text = '';
                        });
                      }
                    }
                  },
                  child: const Text('Enviar'),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
