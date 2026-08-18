import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sentinela/core/service_locator.dart';
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/data/models/unit.dart';
import 'package:sentinela/domain/flow_report_service.dart';
import 'package:sentinela/helpers/format_date.dart';
import 'package:sentinela/widgets/chart/hourly_flow_chart.dart';
import 'package:sentinela/widgets/list/report_pdf_item.dart';
import 'package:sentinela/widgets/select/unit_selector.dart';
import 'package:sentinela/widgets/title/secondary_title.dart';

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
  late final Future<List<Unit>> _unitsFuture;

  @override
  void initState() {
    super.initState();
    _unitsFuture = ServiceLocator.instance.units.getActiveUnits();
  }

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
    final ttf = await rootBundle.load('assets/fonts/monda-regular.ttf');
    final boldTtf = await rootBundle.load('assets/fonts/monda-bold.ttf');
    final font = pw.Font.ttf(ttf);
    final boldFont = pw.Font.ttf(boldTtf);
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: boldFont),
    );
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
                'Relatório criado com o app Sentinela disponível no Google Play',
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
    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    try {
      final path = await FileSaver.instance.saveAs(
        name: 'Relatorio-$timestamp',
        bytes: file,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (path == null) return;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/Relatorio-$timestamp.pdf');
      await tempFile.writeAsBytes(file);
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/pdf')],
        subject: 'Relatório de guarda - $unitName',
        text: 'Relatório de guarda - $unitName',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SecondaryTitle(title: 'Selecione uma unidade'),
        Flexible(
          child: FutureBuilder<List<Unit>>(
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
                onSelected: (id) => setState(() {
                  unitId = id;
                  unitName = units.firstWhere((u) => u.id == id).name;
                }),
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
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                    child: Text(
                      'Erro ao carregar: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (registries.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                    child: const Text('Sem Registros'),
                  );
                }

                final flow = FlowReportService.hourly(registries);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: HourlyFlowChart(flow: flow),
                    ),
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
