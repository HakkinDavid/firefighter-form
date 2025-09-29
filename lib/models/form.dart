class ServiceForm {
  Map<String, dynamic> template = {};
  Map<String, dynamic> data = {};
  List<String> sectionKeys = [];
  Map<String, List<String>> errors = {};

  ServiceForm({this.template = const {}, this.data = const {}}) {
    load();
  }

  void load() {
    final sections = template['fields'] as Map<String, dynamic>;
    sectionKeys = sections.keys.toList();
    for (var section in sectionKeys) {
      for (var field in sections[section]) {
        data[field['name']] ??= getDefaultValue(field);
      }
    }
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
    if (template['restrictions'] == null) return;
    template['restrictions'].forEach((key, items) {
      for (final field in items) {
        final fieldName = field['name'];
        final value = data[fieldName];
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
          errors[fieldName] = (errors[fieldName] ?? [])..add(msg);
        }
      }
    });
  }
}
