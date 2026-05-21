import 'dart:convert';
import 'dart:io';
import 'package:bomberos/models/settings.dart' show Settings;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

class ServicePDF {
  // static bool _isBase64Image(String? str) {
  //   final regex = RegExp(
  //     r'^data:image\/(png|jpeg|jpg|gif|bmp|webp);base64,[A-Za-z0-9+/=]+$',
  //   );
  //   return str != null && regex.hasMatch(str);
  // }

  static Future<void> generate({
    required String formId,
    required Map<String, dynamic> template,
    required Map<String, dynamic> formData,
    bool ignoreEmptyFields = false,
    bool preview = true,
  }) async {
    final pdf = pw.Document();

    final images = <String, pw.MemoryImage>{};
    // Si tienes tus logos embebidos o base64, aquí podrías cargarlos
    try {
      images['left_logo'] = pw.MemoryImage(
        (await rootBundle.load('assets/tijuana.png')).buffer.asUint8List(),
      );
      images['right_logo'] = pw.MemoryImage(
        (await rootBundle.load('assets/bomberos.png')).buffer.asUint8List(),
      );
    } catch (_) {}

    final header = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (images['left_logo'] != null)
          pw.Image(images['left_logo']!, width: 80),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "Ayuntamiento de Tijuana",
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.Text("Dirección de Bomberos Tijuana"),
              pw.Text(
                "Formato de Registro de Atención Hospitalaria",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (images['right_logo'] != null)
          pw.Image(images['right_logo']!, width: 80),
      ],
    );

    final content = <pw.Widget>[header, pw.SizedBox(height: 16)];

    final Map<String, dynamic> fieldsMap = Map<String, dynamic>.from(template['fields'] as Map? ?? {});
    final Map<String, dynamic> orderMap = Map<String, dynamic>.from(template['order'] as Map? ?? {});

    final sectionKeys = fieldsMap.keys.toList();
    sectionKeys.sort((a, b) {
      final av = orderMap[a];
      final bv = orderMap[b];
      final ai = av is num ? av.toInt() : 0;
      final bi = bv is num ? bv.toInt() : 0;
      return ai.compareTo(bi);
    });

    final fields = <dynamic>[];
    for (final section in sectionKeys) {
      final list = fieldsMap[section];
      if (list is List) {
        fields.addAll(list);
      }
    }

    int numColumns = 4;
    int counter = 0;
    List<pw.Widget> row = [];

    void resetRow() {
      if (row.isNotEmpty) {
        content.add(
          pw.Row(
            children: row,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          ),
        );
        content.add(pw.SizedBox(height: 10));
        row = [];
        counter = 0;
      }
    }

    for (final field in fields) {
      final name = field['name'];
      final type = field['type'];
      final label = field['label'] ?? '';
      final value = formData['data']?[name] ?? formData[name];

      if (ignoreEmptyFields &&
          (value == null || value.isEmpty)) {
        continue;
      }

      if (counter >= numColumns) resetRow();
      counter++;

      switch (type) {
        case 'input':
        case 'select':
        case 'textarea':
        case 'multiple':
          if (value is List) {
            row.add(
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Bullet(
                      text: value.join(", "),
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          } else {
            row.add(
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      label,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      value?.toString() ?? "—",
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }
          break;

        case 'text':
          resetRow();
          final text = (field['text'] ?? '').toString().replaceAll(
            RegExp(r'<[^>]*>'),
            '',
          );
          content.add(
            pw.Text(
              text,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          );
          break;

        case 'tuple':
          resetRow();
          content.add(
            pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          );
          final tupleFields = (field['tuple'] as List)
              .where(
                (t) => [
                  'input',
                  'select',
                  'textarea',
                  'multiple',
                ].contains(t['type']),
              )
              .toList();
          final headers = tupleFields.map((t) => t['label']).toList();

          final body = <List<String>>[];
          if (value is List) {
            for (final tuple in value) {
              body.add([
                for (final subfield in tupleFields)
                  (tuple[subfield['name']] is List)
                      ? (tuple[subfield['name']] as List).join(", ")
                      : (tuple[subfield['name']] ?? "").toString(),
              ]);
            }
          }

          content.add(
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: body,
              cellStyle: pw.TextStyle(fontSize: 9),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
            ),
          );
          break;

        case 'drawingboard':
          resetRow();
          final text = (field['text'] ?? '').toString();
          final sec = (field['secondaryLabel'] ?? '').toString();
          pw.Widget bgWidget = pw.SvgImage(
            svg: field['background'] != null ? utf8.decode(
              base64Decode(
                field['background'].replaceAll(RegExp(r'data:image/svg\+xml;base64,'), ''),
              ),
            ) : "<svg></svg>",
            width: 200,
            height: 200
          );
          pw.Widget imgWidget = pw.SvgImage(
            svg: value != null ? utf8.decode(
              base64Decode(
                value.replaceAll(RegExp(r'data:image/svg\+xml;base64,'), ''),
              ),
            ) : "<svg></svg>",
            width: 200,
            height: 200
          );
          content.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                if (sec.isNotEmpty) pw.Text(sec),
                if (text.isNotEmpty) pw.Text(text, style: pw.TextStyle(fontSize: 10)),
                (value != null || field['background'] != null) ? pw.Stack(children: [bgWidget, imgWidget]) : pw.Text("No proporcionado"),
              ],
            ),
          );
          break;
      }
    }

    if (row.isNotEmpty) resetRow();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => content,
      ),
    );

    // Guardar y abrir
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$formId.pdf");
    await file.writeAsBytes(await pdf.save());

    if (preview) {
      await OpenFilex.open(file.path);
    } else {
      await Printing.sharePdf(bytes: await pdf.save(), filename: '$formId.pdf');
    }
  }

  static Future<void> generateInventoryReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required Map<String, String> filters,
    String? signatureSvg,
    bool preview = true,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromInt(Settings.instance.colors.primary.toARGB32());
    final accentColor = PdfColor.fromInt(Settings.instance.colors.primaryContrastDark.toARGB32());

    final images = <String, pw.MemoryImage>{};
    try {
      images['left_logo'] = pw.MemoryImage(
        (await rootBundle.load('assets/tijuana.png')).buffer.asUint8List(),
      );
      images['right_logo'] = pw.MemoryImage(
        (await rootBundle.load('assets/bomberos.png')).buffer.asUint8List(),
      );
    } catch (_) {}

    final header = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        if (images['left_logo'] != null)
          pw.Image(images['left_logo']!, width: 80),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "Ayuntamiento de Tijuana",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("Dirección de Bomberos Tijuana", style: pw.TextStyle(fontSize: 14)),
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 4),
                height: 2,
                color: accentColor,
              ),
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        if (images['right_logo'] != null)
          pw.Image(images['right_logo']!, width: 80),
      ],
    );

    final List<pw.Widget> filterWidgets = [];
    if (filters.isNotEmpty) {
      filterWidgets.add(pw.Text("Filtros Aplicados:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)));
      filters.forEach((key, val) {
        filterWidgets.add(pw.Text("$key: $val", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)));
      });
      filterWidgets.add(pw.SizedBox(height: 12));
    }

    // Build a vector horizontal bar chart for the PDF report
    final List<pw.Widget> chartWidgets = [];
    if (rows.isNotEmpty) {
      chartWidgets.add(
        pw.Text(
          "GRÁFICO DE DISTRIBUCIÓN (TOP 6):",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryColor),
        ),
      );
      chartWidgets.add(pw.SizedBox(height: 8));

      // Parse chart data from table rows
      final List<MapEntry<String, double>> chartData = [];
      for (final row in rows) {
        if (row.length >= 2) {
          final name = row[0];
          final val = double.tryParse(row[1]) ?? 0.0;
          chartData.add(MapEntry(name, val));
        }
      }
      
      // Sort descending
      chartData.sort((a, b) => b.value.compareTo(a.value));

      final total = chartData.fold<double>(0.0, (sum, e) => sum + e.value);
      final double maxVal = chartData.isEmpty
          ? 1.0
          : chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

      // Take top 6
      final topData = chartData.take(6).toList();

      for (final entry in topData) {
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
        final barFactor = maxVal > 0 ? (entry.value / maxVal) : 0.0;

        chartWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3.0),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    entry.key,
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        if (barFactor > 0)
                          pw.Expanded(
                            flex: (barFactor * 1000).toInt(),
                            child: pw.Container(
                              height: 8,
                              decoration: pw.BoxDecoration(
                                color: primaryColor,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        if (1 - barFactor > 0)
                          pw.Expanded(
                            flex: ((1 - barFactor) * 1000).toInt(),
                            child: pw.SizedBox(),
                          ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.SizedBox(
                  width: 70,
                  child: pw.Text(
                    "${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)",
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      chartWidgets.add(pw.SizedBox(height: 20));
    }

    final tableWidget = pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      cellStyle: pw.TextStyle(fontSize: 9),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration: pw.BoxDecoration(
        color: primaryColor,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: 0.5,
          ),
        ),
      ),
    );

    pw.Widget? sigImageWidget;
    if (signatureSvg != null && signatureSvg.isNotEmpty) {
      try {
        final decodedSvg = utf8.decode(
          base64Decode(
            signatureSvg.replaceAll(RegExp(r'data:image/svg\+xml;base64,'), ''),
          ),
        );
        sigImageWidget = pw.SvgImage(svg: decodedSvg, height: 60);
      } catch (_) {}
    }

    final signatureSection = pw.Column(
      children: [
        pw.SizedBox(height: 40),
        pw.Center(
          child: pw.Column(
            children: [
              if (sigImageWidget != null) ...[
                sigImageWidget,
                pw.SizedBox(height: 8),
              ] else
                pw.SizedBox(height: 50),
              pw.Container(
                width: 200,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                "Firma del Responsable",
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          header,
          pw.SizedBox(height: 16),
          ...filterWidgets,
          ...chartWidgets,
          tableWidget,
          signatureSection,
        ],
      ),
    );

    // Save and open
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    if (preview) {
      await OpenFilex.open(file.path);
    } else {
      await Printing.sharePdf(bytes: await pdf.save(), filename: 'reporte.pdf');
    }
  }
}
