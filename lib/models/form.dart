import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ServiceForm {
  Map<String, dynamic> _template = const {};
  List<String> _sectionKeys = const [];
  final Map<String, List<String>> _errors = {};

  final int _templateId;
  final String _filler;
  final int _status;
  final Map<String, dynamic> _content;
  final DateTime _filledAt;

  String get name => _template['formname'] ?? 'Formulario';
  Map<String, dynamic> get sections => _template['fields'];
  List<String> get sectionKeys => _sectionKeys;
  Map<String, dynamic> get content => _content;
  Map<String, dynamic> get errors => _errors;

  String get filler => _filler;
  int get status => _status;
  DateTime get filledAt => _filledAt;

  bool get isLoaded => _template['formname'] != null;

  ServiceForm(
    this._templateId,
    this._filler,
    this._filledAt,
    this._content,
    this._status,
  ) {
    load();
  }

  void load() async {
    _template = json.decode(
      await File(
        '${(await getApplicationDocumentsDirectory()).path}/frap/$_templateId.json',
      ).readAsString(),
    );
    final sections = _template['fields'] as Map<String, dynamic>;
    _sectionKeys = sections.keys.toList();
    for (var section in _sectionKeys) {
      for (var field in sections[section]) {
        _content[field['name']] ??= getDefaultValue(field);
      }
    }
  }

  void set(String fieldName, dynamic newValue) {
    if (status != 0) return;
    content[fieldName] = newValue;
  }

  dynamic getDefaultValue(Map<String, dynamic> field) {
    if (field['type'] == 'multiple' && field['inputType'] == 'checkbox') {
      return <String>[];
    }
    if (field['type'] == 'multiple' && field['inputType'] == 'radio') {
      return '';
    }
    if (field['type'] == 'select') {
      return '';
    }
    if (field['type'] == 'textarea') {
      return '';
    }
    if (field['type'] == 'drawingboard') {
      return null; // Canvas data
    }
    if (field['type'] == 'tuple') {
      return <Map<String, dynamic>>[];
    }
    if (field['type'] == 'input') {
      if (field['multiple'] == true) return <String>[];
      if (field['inputType'] == 'number') return '';
      if (field['inputType'] == 'date') return '';
      if (field['inputType'] == 'time') return '';
      return '';
    }
    return '';
  }

  // Restriction handler (minimal Dart port)
  void handleFieldRestrictions() {
    if (_template['restrictions'] == null) return;
    _template['restrictions'].forEach((key, items) {
      for (final field in items) {
        final fieldName = field['name'];
        final value = _content[fieldName];
        bool passed = true;
        switch (key) {
          case 'notEmpty':
            passed = value != null && value.toString().trim().isNotEmpty;
            break;
          case 'lessThan':
            passed =
                value != null &&
                    value != '' &&
                    double.tryParse(value.toString()) != null
                ? double.parse(value.toString()) < field['value']
                : true;
            break;
          case 'greaterThan':
            passed =
                value != null &&
                    value != '' &&
                    double.tryParse(value.toString()) != null
                ? double.parse(value.toString()) > field['value']
                : true;
            break;
          // ...add more cases as needed...
          default:
            passed = true;
        }
        if (!passed) {
          final msg = field['message'] ?? 'Campo inválido';
          _errors[fieldName] = msg;
        }
      }
    });
  }

  Map<String, dynamic> toJson() {
    return content;
  }
}
