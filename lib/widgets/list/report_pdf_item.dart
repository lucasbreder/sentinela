import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sentinela/helpers/format_date.dart';

pw.Widget registyPDFItem(AsyncSnapshot snapshot, int index) {
  final data = snapshot.data[index];
  return pw.Container(
    width: PdfPageFormat.a4.width,
    padding: const pw.EdgeInsets.fromLTRB(0, 5, 0, 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(
          color: PdfColor(0, 0, 0),
          width: 1,
        ),
      ),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.max,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Row(
          children: [
            pw.Column(
              mainAxisSize: pw.MainAxisSize.max,
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      data['license_plate'],
                      textAlign: pw.TextAlign.left,
                      style: const pw.TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "${data['type']}: ",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formatDate(
                        data['created_at'].toDate().toString(),
                      ),
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(
                      width: 10,
                    ),
                    pw.SizedBox(
                      width: 10,
                    ),
                    pw.Row(children: [
                      pw.Text(
                        "Condutor: ",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "${data['driver']}",
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ]),
                    pw.SizedBox(
                      width: 10,
                    ),
                    data['document_number'].toString().isNotEmpty
                        ? pw.Row(
                            children: [
                              pw.Text(
                                "Documento: ",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                "${data['document_number']}",
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                ),
                              )
                            ],
                          )
                        : pw.SizedBox(),
                  ],
                ),
                pw.Row(children: [
                  pw.Text(
                    "Sentinela: ",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(
                    height: 5,
                  ),
                  pw.Text(
                    "${data['user']['name']}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(
                    width: 5,
                  ),
                  pw.Text(
                    "Matrícula: ",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "${data['user']['registry']}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ]),
                data['notes'].toString().isNotEmpty
                    ? pw.Row(
                        children: [
                          pw.SizedBox(
                            height: 5,
                          ),
                          pw.Text("Observações: ",
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              )),
                          pw.Text(
                            "${data['notes']}",
                            style: const pw.TextStyle(
                              fontSize: 10,
                            ),
                          )
                        ],
                      )
                    : pw.SizedBox(),
              ],
            ),
          ],
        )
      ],
    ),
  );
}
