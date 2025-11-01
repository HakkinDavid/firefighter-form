import 'dart:convert';
import 'dart:io';
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

    final fields = (template['fields'] as Map).values.expand((v) => v).toList();

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
}
