import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentinela/controllers/get_my_units.dart';
import 'package:sentinela/controllers/get_report.dart';
import 'package:sentinela/controllers/get_unit.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/widgets/list/report_pdf_item.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportList extends StatefulWidget {
  const ReportList({Key? key}) : super(key: key);

  @override
  State<ReportList> createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> {
  DateTime? _dateFilter;

  final dateFilterController = TextEditingController();
  String unitId = '';
  DocumentSnapshot? unit;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SecondaryTitle(title: 'Selecione uma unidade'),
        Flexible(
          child: FutureBuilder(
            future: getMyUnits(),
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data.length > 0) {
                  return Column(
                    children: [
                      SizedBox(
                        height:
                            70.0 * (snapshot.data.length / 3).ceilToDouble(),
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
                                onTap: () async {
                                  setState(() {
                                    unitId = data.get('unit_id');
                                  });

                                  final unitData = await getUnit(unitId);

                                  setState(() {
                                    unit = unitData;
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
          controller: dateFilterController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Data e hora do início',
            helperText: 'Serão incluídas todas as movimentações feitas em 24h.',
            helperMaxLines: 4,
            contentPadding:
                EdgeInsets.only(top: 20), // add padding to adjust text
            isDense: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(top: 15), // add padding to adjust icon
              child: Icon(
                Icons.calendar_today,
                size: 20,
              ),
            ),
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
                  _dateFilter = DateTime(date.year, date.month, date.day,
                      pickedTime.hour, pickedTime.minute);
                });
                DateFormat formatted = DateFormat("dd/MM/yyy à's' HH:mm");
                dateFilterController.text = formatted.format(_dateFilter!);
                FocusManager.instance.primaryFocus?.unfocus();
              }
            }
          },
        ),
        (unitId.isNotEmpty && _dateFilter != null)
            ? Flexible(
                child: FutureBuilder(
                future: getReport(_dateFilter!, unitId),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.length == 0) {
                      return Container(
                        padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                        child: const Text('Sem Registros'),
                      );
                    } else {
                      List<pw.Widget> pdfReport = [];

                      for (var i = 0; i < snapshot.data.length; i++) {
                        pdfReport.add(registyPDFItem(snapshot, i));
                      }

                      return Column(
                        children: [
                          GestureDetector(
                            child: Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 10, 20, 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Salvar em PDF',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            onTap: () async {
                              final pdf = pw.Document();

                              pdf.addPage(
                                pw.MultiPage(
                                  pageFormat: PdfPageFormat.a4,
                                  footer: ((context) => pw.Container(
                                      width: PdfPageFormat.a4.width,
                                      child: pw.Column(
                                        crossAxisAlignment:
                                            pw.CrossAxisAlignment.center,
                                        children: [
                                          pw.SizedBox(
                                            height: 8,
                                          ),
                                          pw.Text(
                                            'Relatório criado com o app Sentinela disponível no Google Play e Apple Store',
                                            style: const pw.TextStyle(
                                              fontSize: 7,
                                            ),
                                          )
                                        ],
                                      ))),
                                  build: (pw.Context context) => [
                                    pw.Column(
                                      mainAxisSize: pw.MainAxisSize.max,
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      children: [
                                        if (unit != null)
                                          pw.Text(
                                            'Relatório de guarda - ${unit!.get('name')}',
                                            style: pw.TextStyle(
                                              fontSize: 20,
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                        pw.Text(
                                            "De ${formatDate(_dateFilter.toString())} até ${formatDate(_dateFilter!.add(const Duration(hours: 24)).toString())}"),
                                      ],
                                    ),
                                    pw.SizedBox(height: 10),
                                    pw.Column(children: pdfReport)
                                  ],
                                ),
                              );

                              final output = await getTemporaryDirectory();
                              final filePath =
                                  "${output.path}/Relatorio-${DateTime.now().toString()}.pdf";
                              final file = File(filePath);

                              await file.writeAsBytes(await pdf.save());

                              OpenFilex.open(filePath);
                            },
                          ),
                          ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              addAutomaticKeepAlives: true,
                              itemCount: snapshot.data.length,
                              itemBuilder: (((context, index) {
                                final data = snapshot.data[index];
                                final prevData = snapshot
                                    .data[index == 0 ? index : index - 1];
                                final DateFormat formatter =
                                    DateFormat('HH:mm:ss');
                                final DateFormat formatterDate =
                                    DateFormat('dd/MM/yyyy');
                                final itemDate = DateTime.parse(
                                    data['created_at'].toDate().toString());
                                final prevDate = DateTime.parse(
                                    prevData['created_at'].toDate().toString());
                                final formattedHour =
                                    formatter.format(itemDate);
                                final formattedDate =
                                    formatterDate.format(itemDate);
                                final formattedDatePrev =
                                    formatterDate.format(prevDate);
                                return Column(
                                  children: [
                                    formattedDate != formattedDatePrev ||
                                            index == 0
                                        ? SecondaryTitle(title: formattedDate)
                                        : const SizedBox(),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              width: 1,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .background),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                data['license_plate'],
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(formattedHour),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                data['license_plate'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(data['driver']),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                data['document_number'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: data['notes']
                                                    .toString()
                                                    .isNotEmpty
                                                ? Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                            top: 5),
                                                    child: Text(
                                                      data['notes'],
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  "Sentinela",
                                                  style: TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  data['user']['name'],
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 5,
                                                ),
                                                Text(
                                                  data['user']['registry'],
                                                  style: const TextStyle(
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }))),
                          const SizedBox(
                            height: 40,
                          )
                        ],
                      );
                    }
                  } else {
                    return CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                },
              ))
            : const SizedBox()
      ],
    );
  }
}
