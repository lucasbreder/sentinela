import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sentinela/data/models/registry.dart';
import 'package:sentinela/helpers/format_date.dart';

pw.Widget registryPdfItem(Registry registry) {
  return pw.Container(
    width: PdfPageFormat.a4.width,
    padding: const pw.EdgeInsets.fromLTRB(0, 5, 0, 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColor(0, 0, 0), width: 1),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      registry.licensePlate,
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${registry.type}: ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formatDate(registry.createdAt),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(width: 10),
                    pw.SizedBox(width: 10),
                    pw.Row(children: [
                      pw.Text(
                        'Condutor: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        registry.driver,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ]),
                    pw.SizedBox(width: 10),
                    if (registry.documentNumber.isNotEmpty)
                      pw.Row(
                        children: [
                          pw.Text(
                            'Documento: ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            registry.documentNumber,
                            style: const pw.TextStyle(fontSize: 10),
                          )
                        ],
                      ),
                  ],
                ),
                pw.Row(children: [
                  pw.Text(
                    'Sentinela: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    registry.authorName ?? '',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(width: 5),
                  pw.Text(
                    'Matrícula: ',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    registry.authorRegistry ?? '',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ]),
                if (registry.notes.isNotEmpty)
                  pw.Row(
                    children: [
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Observações: ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        registry.notes,
                        style: const pw.TextStyle(fontSize: 10),
                      )
                    ],
                  ),
              ],
            ),
          ],
        )
      ],
    ),
  );
}
