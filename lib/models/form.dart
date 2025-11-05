import 'package:bomberos/models/pdf_renderer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

class ServiceForm {
  Map<String, dynamic> _template = const {};
  final Map<String, (String, int)> _reference = {};
  List<String> _sectionKeys = const [];
  final Map<String, Set<String>> _errors = {};

  String? _id;
  final int _templateId;
  final String _filler;
  int _status;
  final Map<String, dynamic> _content;
  final DateTime _filledAt;

  bool _edited = false;

  String get name => _template['formname'] ?? 'Formulario';
  Map<String, dynamic> get sections => _template['fields'];
  List<String> get sectionKeys => _sectionKeys;
  Map<String, dynamic> get content => _content;
  Map<String, dynamic> get errors => _errors;

  String get filler => _filler;
  int get status => _status;
  DateTime get filledAt => _filledAt;

  String get id => _id!;
  int get templateId => _templateId;

  bool get edited => _edited;

  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  set editOverride(bool v) {
    if (Settings.instance.role >= 1 && v) _status = 0;
  }

  ServiceForm(
    this._id,
    this._templateId,
    this._filler,
    this._filledAt,
    this._content,
    this._status,
  ) {
    _id ??= Uuid().v8(config: V8Options(DateTime.now(), null));
  }

  Future<void> load() async {
    _template = await Settings.instance.getTemplate(_templateId);
    final sections = _template['fields'] as Map<String, dynamic>;
    _sectionKeys = sections.keys.toList();
    for (var section in _sectionKeys) {
      int fieldIndex = 0;
      for (var field in sections[section]) {
        _content[field['name']] ??= getDefaultValue(field);
        _reference[field['name']] = (section, fieldIndex);
        fieldIndex++;
      }
    }
    _isLoaded = true;
  }

  void set(String fieldName, dynamic newValue) {
    if (!canEditForm) return;
    if (newValue != _content[fieldName]) _edited = true;
    _content[fieldName] = newValue;
    _clearErrors(fieldName);
  }

  void _clearErrors(String fieldName) {
    _errors.remove(fieldName);
  }

  Future<void> save({bool shouldSetAsFinished = false}) async {
    if (shouldSetAsFinished && canFinishForm) {
      _status = 1;
    } else if (!canSaveForm) {
      return;
    }
    await Settings.instance.enqueueForm(this);
  }

  Future<void> delete() async {
    if (!canDeleteForm) return;
    await Settings.instance.deleteForm(this);
  }

  Future<void> render() async {
    if (!_isLoaded) await load();
    await ServicePDF.generate(
      formId: _id!,
      template: _template,
      formData: content,
      ignoreEmptyFields: true,
    );
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
        if (!shouldDisplay(getFieldFromReference(fieldName))) {
          _clearErrors(fieldName);
          continue;
        }
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
          case 'regexOnlyLetters':
            if (value != null && value.toString().isNotEmpty) {
              final regex = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÜüÑñ\s]+$');
              passed = regex.hasMatch(value.toString());
            }
            break;
          case 'regexOnlyNumbers':
            if (value != null && value.toString().isNotEmpty) {
              final regex = RegExp(r'^[0-9]+$');
              passed = regex.hasMatch(value.toString());
            }
            break;
          case 'regexPhoneNumber':
            if (value != null && value.toString().isNotEmpty) {
              final regex = RegExp(r'^\d{10}$');
              passed = regex.hasMatch(value.toString());
            }
            break;
          case 'regexEmail':
            if (value != null && value.toString().isNotEmpty) {
              final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[A-Za-z]{2,4}$');
              passed = regex.hasMatch(value.toString());
            }
            break;
          case 'regexAlphanumeric':
            if (value != null && value.toString().isNotEmpty) {
              final regex = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÜüÑñ0-9\s.,#°\-]+$');
              passed = regex.hasMatch(value.toString());
            }
            break;
          default:
            passed = true;
        }
        if (!passed) {
          final msg = field['message'] ?? 'Campo inválido';
          _errors[fieldName] = (_errors[fieldName] ?? <String>{})..add(msg);
        }
      }
    });
  }

  bool fieldNotEmpty(Map<String, dynamic> fieldReference) {
    return _content[fieldReference['name']]?.isNotEmpty ?? false;
  }

  bool fieldIsEmpty(Map<String, dynamic> fieldReference) {
    return _content[fieldReference['name']]?.isEmpty ?? true;
  }

  bool fieldEqualsTo(Map<String, dynamic> fieldReference) {
    return _content[fieldReference['name']] == fieldReference['value'];
  }

  bool fieldIncludes(Map<String, dynamic> fieldReference) {
    return _content[fieldReference['name']]?.contains(
          fieldReference['value'],
        ) ??
        false;
  }

  bool shouldDisplay(Map<String, dynamic> field) {
    final List<dynamic> notEmpty = field['displayOn']?['notEmpty'] ?? [];
    final List<dynamic> isEmpty = field['displayOn']?['isEmpty'] ?? [];
    final List<dynamic> equalsTo = field['displayOn']?['equalsTo'] ?? [];
    final List<dynamic> includes = field['displayOn']?['includes'] ?? [];

    bool willDisplay = true;

    for (var fieldReference in notEmpty) {
      willDisplay = willDisplay && fieldNotEmpty(fieldReference);
    }
    for (var fieldReference in isEmpty) {
      willDisplay = willDisplay && fieldIsEmpty(fieldReference);
    }
    for (var fieldReference in equalsTo) {
      willDisplay = willDisplay && fieldEqualsTo(fieldReference);
    }
    for (var fieldReference in includes) {
      willDisplay = willDisplay && fieldIncludes(fieldReference);
    }

    return willDisplay;
  }

  Map<String, dynamic> getFieldFromReference(String fieldName) {
    return _template['fields'][_reference[fieldName]!.$1][_reference[fieldName]!.$2];
  }

  Map<String, dynamic> toJson({bool asUpload = false}) {
    return {
      '${asUpload ? 'p_' : ''}id': id,
      '${asUpload ? 'p_' : ''}template_id': templateId,
      if (!asUpload) 'filler': filler,
      '${asUpload ? 'p_' : ''}status': status,
      '${asUpload ? 'p_' : ''}content': content,
      '${asUpload ? 'p_' : ''}filled_at': filledAt.toIso8601String(),
    };
  }

  factory ServiceForm.fromJson(Map<String, dynamic> json) {
    return ServiceForm(
      json['id'],
      json['template_id'],
      json['filler'],
      DateTime.parse(json['filled_at']),
      json['content'],
      json['status'],
    );
  }

  bool get canDeleteForm => status == 0 || Settings.instance.role >= 1;

  bool get canEditForm => status == 0;

  bool get canSaveForm =>
      canEditForm &&
      edited &&
      _content.values.any((c) => c?.isNotEmpty == true);

  bool get canFinishForm => canEditForm && errors.isEmpty;

  String get statusName {
    switch (status) {
      case 2:
        return "Sincronizado";
      case 1:
        return "Finalizado";
      case 0:
      default:
        return "Borrador";
    }
  }

  Color get statusColor {
    switch (status) {
      case 2:
        return CupertinoColors.systemGreen;
      case 1:
        return CupertinoColors.systemOrange;
      case 0:
        return Settings.instance.colors.primary;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 2:
        return CupertinoIcons.checkmark_alt_circle;
      case 1:
        return CupertinoIcons.clock;
      case 0:
        return CupertinoIcons.doc;
      default:
        return CupertinoIcons.question;
    }
  }

  List<String> get tags => _content.values
      .whereType<String>()
      .where((t) => t.isNotEmpty && !t.startsWith('data:image'))
      .toList();
}
