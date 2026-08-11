import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/permission.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/widgets/list/report_pdf_item.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';
import 'dart:typed_data';

class ReportList extends StatefulWidget {
  const ReportList({super.key});

  @override
  State<ReportList> createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> {
  DateTime? _dateFilter;
  String unitId = '';
  String unitName = '';

  final dateFilterController = TextEditingController();

  Future<void> _pickDate() async {
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
      _dateFilter = DateTime(date.year, date.month, date.day, pickedTime.hour, pickedTime.minute);
    });
    final formatted = DateFormat("dd/MM/yyyy 'às' HH:mm");
    dateFilterController.text = formatted.format(_dateFilter!);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _savePdf(List<Registry> registries) async {
    final pdf = pw.Document();
    final pdfReport = registries.map(registryPdfItem).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (context) => pw.Container(
          width: PdfPageFormat.a4.width,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(height: 8),
              pw.Text(
                'Relatório criado com o app Sentinela disponível no Google Play e Apple Store',
                style: const pw.TextStyle(fontSize: 7),
              )
            ],
          ),
        ),
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório de guarda - $unitName',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'De ${formatDate(_dateFilter!)} até ${formatDate(_dateFilter!.add(const Duration(hours: 24)))}',
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Column(children: pdfReport)
        ],
      ),
    );

    final Uint8List file = await pdf.save();
    await FileSaver.instance.saveFile(
      name: 'Relatorio-${DateTime.now().toString()}',
      bytes: file,
      mimeType: MimeType.pdf,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SecondaryTitle(title: 'Selecione uma unidade'),
        Flexible(
          child: FutureBuilder<List<Permission>>(
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
                      onTap: () => setState(() {
                        unitId = data.unitId;
                        unitName = data.unitName;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 1,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(6)),
                          color: selected
                              ? Theme.of(context).colorScheme.surface
                              : Colors.transparent,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          data.unitName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Theme.of(context).colorScheme.surface,
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
        ),
        TextFormField(
          controller: dateFilterController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Data e hora do início',
            helperText: 'Serão incluídas todas as movimentações feitas em 24h.',
            helperMaxLines: 4,
            contentPadding: EdgeInsets.only(top: 20),
            isDense: true,
            prefixIcon: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Icon(Icons.calendar_today, size: 20),
            ),
          ),
          onTap: _pickDate,
        ),
        if (unitId.isNotEmpty && _dateFilter != null)
          Flexible(
            child: FutureBuilder<List<Registry>>(
              future: ServiceLocator.instance.registries.report(_dateFilter!, unitId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
                final registries = snapshot.data ?? [];
                if (registries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                    child: const Text('Sem Registros'),
                  );
                }

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => _savePdf(registries),
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                        ),
                        child: const Text(
                          'Salvar em PDF',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      addAutomaticKeepAlives: true,
                      itemCount: registries.length,
                      itemBuilder: (context, index) {
                        final data = registries[index];
                        final prevData =
                            registries[index == 0 ? index : index - 1];
                        final formatter = DateFormat('HH:mm:ss');
                        final formatterDate = DateFormat('dd/MM/yyyy');
                        final formattedHour = formatter.format(data.createdAt);
                        final formattedDate = formatterDate.format(data.createdAt);
                        final formattedDatePrev = formatterDate.format(prevData.createdAt);

                        return Column(
                          children: [
                            if (formattedDate != formattedDatePrev || index == 0)
                              SecondaryTitle(title: formattedDate),
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    width: 1,
                                    color: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        data.licensePlate,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(formattedHour),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        data.licensePlate,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(data.driver),
                                      const SizedBox(width: 10),
                                      Text(
                                        data.documentNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (data.notes.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      width: MediaQuery.of(context).size.width,
                                      child: Text(
                                        data.notes,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Sentinela',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          data.authorName ?? '',
                                          style: const TextStyle(fontSize: 8),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          data.authorRegistry ?? '',
                                          style: const TextStyle(fontSize: 8),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 40)
                  ],
                );
              },
            ),
          )
      ],
    );
  }
}
