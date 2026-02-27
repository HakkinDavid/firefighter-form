import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/dynamic_field_renderer.dart';
import 'package:flutter/cupertino.dart';

/*
FRAP TEMPLATE DSL (derived from assets/frap.json + lib/routes/form.dart +
lib/viewmodels/dynamic_field_renderer.dart)

Top-level object:
- formname: String
- fields: Map<String, List<Field>>
- order: Map<String, int> (section ordering for tabs)
- restrictions: Map<String, List<RestrictionItem>>

Sectioning / ordering behavior:
- Sections are rendered as tabs in order sorted by order[section] ascending.
- If a section key is missing in order, runtime fallback behaves like 0.
- Each section value is an ordered array of fields; array position is render order.

All field objects must contain:
- name: String
- type: String enum:
  input | select | textarea | multiple | drawingboard | tuple | text

Observed optional field keys (global superset):
- label, text, inputType, options, multiple, rows, displayOn,
  background, aspect_ratio, secondaryLabel, tuple

displayOn conditional visibility:
- Optional key: displayOn
- displayOn keys supported by runtime:
  notEmpty, isEmpty, equalTo, includes
- Each key maps to a List of references:
  notEmpty/isEmpty items: {name}
  equalTo/includes items: {name, value}

Renderer dispatch contract:
- input: date -> time -> multiple==true -> number -> options -> text input
- select -> SelectField
- textarea -> TextAreaField
- multiple: checkbox/radio only
- drawingboard -> DrawingBoardField
- tuple -> TupleField
- text -> TextDisplayField

Restrictions object:
- rules: notEmpty, lessThan, greaterThan, regexOnlyLetters,
  regexOnlyNumbers, regexPhoneNumber, regexEmail, regexAlphanumeric
- item keys observed: name, value, message, subname
*/

const List<String> _dslFieldTypes = <String>[
  'input',
  'select',
  'textarea',
  'multiple',
  'drawingboard',
  'tuple',
  'text',
];

const List<String> _dslInputTypes = <String>['text', 'number', 'date', 'time'];
const List<String> _dslMultipleInputTypes = <String>['radio', 'checkbox'];

const List<String> _dslRestrictionRules = <String>[
  'notEmpty',
  'lessThan',
  'greaterThan',
  'regexOnlyLetters',
  'regexOnlyNumbers',
  'regexPhoneNumber',
  'regexEmail',
  'regexAlphanumeric',
];

class ServiceTemplateMaker extends StatefulWidget {
  const ServiceTemplateMaker({super.key});

  @override
  State<ServiceTemplateMaker> createState() => _ServiceTemplateMakerState();
}

class _ServiceTemplateMakerState extends State<ServiceTemplateMaker> {
  Map<String, dynamic>? _template;
  String? _loadError;

  String? _selectedSection;
  int? _selectedFieldIndex;

  late final _TemplatePreviewForm _previewForm;

  @override
  void initState() {
    super.initState();
    _previewForm = _TemplatePreviewForm();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final fetched = await Settings.instance.fetchTemplate();
      final loaded = fetched.$2();
      _normalizeTemplateInPlace(loaded);
      setState(() {
        _template = loaded;
      });
    } catch (_) {
      setState(() {
        _loadError = 'Plantilla no disponible.';
      });
    }
  }

  Future<void> _validateTemplate() async {
    if (_template == null) return;
    _normalizeTemplateInPlace(_template!);
    setState(() {});
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Plantilla válida'),
        content: Text('La estructura actual cumple con el DSL de FRAP.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _normalizeTemplateInPlace(Map<String, dynamic> template) {
    template['formname'] = (template['formname'] ?? 'Nueva plantilla')
        .toString();

    if (template['fields'] is! Map<String, dynamic>) {
      template['fields'] = <String, dynamic>{};
    }
    if (template['order'] is! Map<String, dynamic>) {
      template['order'] = <String, dynamic>{};
    }
    if (template['restrictions'] is! Map<String, dynamic>) {
      template['restrictions'] = <String, dynamic>{};
    }

    final fields = template['fields'] as Map<String, dynamic>;
    final order = template['order'] as Map<String, dynamic>;
    final restrictions = template['restrictions'] as Map<String, dynamic>;

    final sectionKeys = fields.keys.toList();
    for (final key in sectionKeys) {
      if (fields[key] is! List<dynamic>) {
        fields[key] = <dynamic>[];
      }
    }

    order.removeWhere((key, _) => !fields.containsKey(key));

    final orderedSections = fields.keys.toList();
    orderedSections.sort((a, b) {
      final av = order[a];
      final bv = order[b];
      final ai = av is num ? av.toInt() : 1 << 20;
      final bi = bv is num ? bv.toInt() : 1 << 20;
      return ai.compareTo(bi);
    });
    for (int i = 0; i < orderedSections.length; i++) {
      order[orderedSections[i]] = i;
    }

    final usedNames = <String>{};
    for (final section in orderedSections) {
      final sectionFields = fields[section] as List<dynamic>;
      for (int i = 0; i < sectionFields.length; i++) {
        if (sectionFields[i] is! Map<String, dynamic>) {
          sectionFields[i] = _newFieldByType(
            'text',
            _generateUniqueFieldName(usedNames),
          );
        }
        final field = sectionFields[i] as Map<String, dynamic>;
        _normalizeFieldInPlace(field);

        final candidate = _sanitizeName(field['name']?.toString() ?? '');
        field['name'] = _ensureUniqueName(
          candidate.isEmpty ? 'campo' : candidate,
          used: usedNames,
        );
      }
    }

    for (final rule in _dslRestrictionRules) {
      if (restrictions[rule] is! List<dynamic>) {
        restrictions[rule] = <dynamic>[];
      }
      final items = restrictions[rule] as List<dynamic>;
      for (int i = 0; i < items.length; i++) {
        if (items[i] is! Map<String, dynamic>) {
          items[i] = <String, dynamic>{};
        }
        final item = items[i] as Map<String, dynamic>;
        item['name'] = (item['name'] ?? '').toString();
        item['message'] = (item['message'] ?? 'Campo inválido').toString();
        if (_ruleNeedsValue(rule)) {
          item['value'] = (item['value'] ?? '').toString();
        } else {
          item.remove('value');
        }
        if ((item['subname'] ?? '').toString().trim().isEmpty) {
          item.remove('subname');
        }
      }
    }

    _previewForm.syncFromTemplate(template);
  }

  void _normalizeFieldInPlace(Map<String, dynamic> field) {
    String type = (field['type'] ?? 'text').toString();
    if (!_dslFieldTypes.contains(type)) type = 'text';
    field['type'] = type;

    field['name'] = (field['name'] ?? '').toString();

    if (field['displayOn'] is! Map<String, dynamic>) {
      field.remove('displayOn');
    } else {
      final displayOn = field['displayOn'] as Map<String, dynamic>;
      for (final key in ['notEmpty', 'isEmpty', 'equalTo', 'includes']) {
        if (displayOn[key] is! List<dynamic>) {
          displayOn[key] = <dynamic>[];
        }
      }
      displayOn.removeWhere(
        (key, _) =>
            key != 'notEmpty' &&
            key != 'isEmpty' &&
            key != 'equalTo' &&
            key != 'includes',
      );
    }

    switch (type) {
      case 'input':
        final inputType = (field['inputType'] ?? 'text').toString();
        field['inputType'] = _dslInputTypes.contains(inputType)
            ? inputType
            : 'text';
        field['label'] = (field['label'] ?? '').toString();
        if (field.containsKey('multiple') && field['multiple'] is! bool) {
          field['multiple'] = false;
        }
        if (field.containsKey('options') &&
            field['options'] is! List<dynamic>) {
          field.remove('options');
        }
        break;
      case 'select':
        field['label'] = (field['label'] ?? '').toString();
        if (field['options'] is! List<dynamic>) {
          field['options'] = <dynamic>['Opcion 1'];
        }
        if ((field['options'] as List<dynamic>).isEmpty) {
          (field['options'] as List<dynamic>).add('Opcion 1');
        }
        break;
      case 'textarea':
        field['label'] = (field['label'] ?? '').toString();
        if (field.containsKey('rows')) {
          final rows = field['rows'];
          if (rows is num) {
            field['rows'] = rows.toInt();
          } else {
            field.remove('rows');
          }
        }
        break;
      case 'multiple':
        field['label'] = (field['label'] ?? '').toString();
        final multipleType = (field['inputType'] ?? 'radio').toString();
        field['inputType'] = _dslMultipleInputTypes.contains(multipleType)
            ? multipleType
            : 'radio';
        if (field['options'] is! List<dynamic>) {
          field['options'] = <dynamic>['Opcion 1'];
        }
        if ((field['options'] as List<dynamic>).isEmpty) {
          (field['options'] as List<dynamic>).add('Opcion 1');
        }
        break;
      case 'drawingboard':
        field['label'] = (field['label'] ?? '').toString();
        if (field.containsKey('text')) {
          field['text'] = (field['text'] ?? '').toString();
        }
        if (field.containsKey('secondaryLabel')) {
          field['secondaryLabel'] = (field['secondaryLabel'] ?? '').toString();
        }
        if (field.containsKey('background')) {
          field['background'] = (field['background'] ?? '').toString();
        }
        if (field.containsKey('aspect_ratio')) {
          final ratio = field['aspect_ratio'];
          if (ratio is! num) field.remove('aspect_ratio');
        }
        break;
      case 'tuple':
        field['label'] = (field['label'] ?? 'Lista').toString();
        if (field['tuple'] is! List<dynamic>) {
          field['tuple'] = <dynamic>[];
        }
        final tuple = field['tuple'] as List<dynamic>;
        final usedSubNames = <String>{};
        for (int i = 0; i < tuple.length; i++) {
          if (tuple[i] is! Map<String, dynamic>) {
            tuple[i] = <String, dynamic>{
              'name': _ensureUniqueName('subcampo', used: usedSubNames),
              'type': 'input',
              'inputType': 'text',
              'label': '',
            };
          }
          final sub = tuple[i] as Map<String, dynamic>;
          _normalizeTupleSubfieldInPlace(sub);
          final candidate = _sanitizeName(sub['name']?.toString() ?? '');
          sub['name'] = _ensureUniqueName(
            candidate.isEmpty ? 'subcampo' : candidate,
            used: usedSubNames,
          );
        }
        break;
      case 'text':
        field['text'] = (field['text'] ?? '').toString();
        if (field.containsKey('label')) {
          field['label'] = (field['label'] ?? '').toString();
        }
        break;
    }
  }

  void _normalizeTupleSubfieldInPlace(Map<String, dynamic> sub) {
    var type = (sub['type'] ?? 'input').toString();
    if (type != 'input' && type != 'multiple' && type != 'text') {
      type = 'input';
    }
    sub['type'] = type;
    sub['name'] = (sub['name'] ?? '').toString();

    if (type == 'input') {
      final inputType = (sub['inputType'] ?? 'text').toString();
      sub['inputType'] = _dslInputTypes.contains(inputType)
          ? inputType
          : 'text';
      sub['label'] = (sub['label'] ?? '').toString();
      if (sub.containsKey('options') && sub['options'] is! List<dynamic>) {
        sub.remove('options');
      }
    } else if (type == 'multiple') {
      final inputType = (sub['inputType'] ?? 'radio').toString();
      sub['inputType'] = _dslMultipleInputTypes.contains(inputType)
          ? inputType
          : 'radio';
      sub['label'] = (sub['label'] ?? '').toString();
      if (sub['options'] is! List<dynamic>) {
        sub['options'] = <dynamic>['Opcion 1'];
      }
      if ((sub['options'] as List<dynamic>).isEmpty) {
        (sub['options'] as List<dynamic>).add('Opcion 1');
      }
    } else {
      sub['text'] = (sub['text'] ?? '').toString();
      if (sub.containsKey('label')) {
        sub['label'] = (sub['label'] ?? '').toString();
      }
      sub.remove('inputType');
      sub.remove('options');
    }
  }

  String _sanitizeName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '_');
  }

  String _ensureUniqueName(String base, {required Set<String> used}) {
    var candidate = base;
    int i = 1;
    while (used.contains(candidate) || candidate.isEmpty) {
      candidate = '${base}_$i';
      i++;
    }
    used.add(candidate);
    return candidate;
  }

  String _generateUniqueFieldName(Set<String> used, [String base = 'campo']) {
    var idx = 1;
    var candidate = '${base}_$idx';
    while (used.contains(candidate)) {
      idx++;
      candidate = '${base}_$idx';
    }
    used.add(candidate);
    return candidate;
  }

  Set<String> _collectFieldNames() {
    final result = <String>{};
    if (_template == null) return result;
    final fields = _template!['fields'] as Map<String, dynamic>;
    for (final sectionFields in fields.values) {
      for (final field in (sectionFields as List<dynamic>)) {
        if (field is Map<String, dynamic>) {
          final name = (field['name'] ?? '').toString();
          if (name.isNotEmpty) result.add(name);
        }
      }
    }
    return result;
  }

  String _nextFieldName({String prefix = 'campo'}) {
    final used = _collectFieldNames();
    return _generateUniqueFieldName(used, prefix);
  }

  List<String> _orderedSections() {
    if (_template == null) return <String>[];
    final fields = _template!['fields'] as Map<String, dynamic>;
    final order = _template!['order'] as Map<String, dynamic>;

    final keys = fields.keys.toList();
    keys.sort((a, b) {
      final av = order[a];
      final bv = order[b];
      final ai = av is num ? av.toInt() : 0;
      final bi = bv is num ? bv.toInt() : 0;
      return ai.compareTo(bi);
    });
    return keys;
  }

  void _rebuildOrderFromSections(List<String> sections) {
    final order = _template!['order'] as Map<String, dynamic>;
    order.clear();
    for (int i = 0; i < sections.length; i++) {
      order[sections[i]] = i;
    }
  }

  Future<String?> _promptText({
    required String title,
    String? initial,
    String? placeholder,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    String? result;

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              result = controller.text.trim();
              Navigator.pop(context);
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<void> _showTemplateEditor() async {
    if (_template == null) return;

    final formNameController = TextEditingController(
      text: (_template!['formname'] ?? '').toString(),
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) {
            final sections = _orderedSections();
            return Container(
              height: 560,
              color: CupertinoColors.systemBackground.resolveFrom(context),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plantilla',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  CupertinoTextField(
                    controller: formNameController,
                    placeholder: 'formname',
                    onChanged: (value) {
                      _template!['formname'] = value;
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Sections / order',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          final name = await _promptText(
                            title: 'Nueva sección',
                            placeholder: 'Nombre de sección',
                          );
                          if (name == null || name.trim().isEmpty) return;
                          final fields =
                              _template!['fields'] as Map<String, dynamic>;
                          var sectionName = name.trim();
                          int suffix = 1;
                          while (fields.containsKey(sectionName)) {
                            sectionName = '${name.trim()} $suffix';
                            suffix++;
                          }
                          fields[sectionName] = <dynamic>[];
                          final newOrder = _orderedSections()..add(sectionName);
                          _rebuildOrderFromSections(newOrder);
                          setState(() {});
                          setModalState(() {});
                        },
                        child: Text('+ Add Section'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sections.length,
                      itemBuilder: (context, idx) {
                        final section = sections[idx];
                        return Container(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: CupertinoColors.systemGrey6.resolveFrom(
                              context,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(section)),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: idx == 0
                                    ? null
                                    : () {
                                        final ordered = _orderedSections();
                                        final tmp = ordered[idx - 1];
                                        ordered[idx - 1] = ordered[idx];
                                        ordered[idx] = tmp;
                                        _rebuildOrderFromSections(ordered);
                                        setState(() {});
                                        setModalState(() {});
                                      },
                                child: Icon(CupertinoIcons.chevron_up),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: idx == sections.length - 1
                                    ? null
                                    : () {
                                        final ordered = _orderedSections();
                                        final tmp = ordered[idx + 1];
                                        ordered[idx + 1] = ordered[idx];
                                        ordered[idx] = tmp;
                                        _rebuildOrderFromSections(ordered);
                                        setState(() {});
                                        setModalState(() {});
                                      },
                                child: Icon(CupertinoIcons.chevron_down),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () async {
                                  final renamed = await _promptText(
                                    title: 'Renombrar sección',
                                    initial: section,
                                  );
                                  if (renamed == null ||
                                      renamed.trim().isEmpty) {
                                    return;
                                  }

                                  final fields =
                                      _template!['fields']
                                          as Map<String, dynamic>;
                                  final order =
                                      _template!['order']
                                          as Map<String, dynamic>;
                                  var newName = renamed.trim();
                                  int suffix = 1;
                                  while (newName != section &&
                                      fields.containsKey(newName)) {
                                    newName = '${renamed.trim()} $suffix';
                                    suffix++;
                                  }

                                  final value = fields.remove(section);
                                  fields[newName] = value;

                                  final oldOrder = order.remove(section);
                                  order[newName] = oldOrder ?? idx;
                                  _rebuildOrderFromSections(_orderedSections());

                                  if (_selectedSection == section) {
                                    _selectedSection = newName;
                                  }

                                  setState(() {});
                                  setModalState(() {});
                                },
                                child: Icon(CupertinoIcons.pencil),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  final fields =
                                      _template!['fields']
                                          as Map<String, dynamic>;
                                  final removed =
                                      fields.remove(section)
                                          as List<dynamic>? ??
                                      <dynamic>[];
                                  final order =
                                      _template!['order']
                                          as Map<String, dynamic>;
                                  order.remove(section);
                                  _rebuildOrderFromSections(_orderedSections());

                                  for (final item in removed) {
                                    if (item is Map<String, dynamic>) {
                                      final name = (item['name'] ?? '')
                                          .toString();
                                      if (name.isNotEmpty) {
                                        _previewForm.removeField(name);
                                      }
                                    }
                                  }

                                  if (_selectedSection == section) {
                                    _selectedSection = null;
                                    _selectedFieldIndex = null;
                                  }

                                  setState(() {});
                                  setModalState(() {});
                                },
                                child: Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      CupertinoButton(
                        onPressed: () async {
                          await _showRestrictionsEditor();
                          setModalState(() {});
                        },
                        child: Text('Edit Restrictions'),
                      ),
                      Spacer(),
                      CupertinoButton.filled(
                        onPressed: () {
                          _template!['formname'] = formNameController.text;
                          _normalizeTemplateInPlace(_template!);
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text('Done'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    formNameController.dispose();
  }

  Future<void> _showRestrictionsEditor() async {
    if (_template == null) return;
    final restrictions = _template!['restrictions'] as Map<String, dynamic>;
    for (final rule in _dslRestrictionRules) {
      restrictions[rule] ??= <dynamic>[];
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 560,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restrictions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _dslRestrictionRules.length,
                    itemBuilder: (context, idx) {
                      final rule = _dslRestrictionRules[idx];
                      final items = restrictions[rule] as List<dynamic>;
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('$rule (${items.length})')),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                await _showRestrictionRuleEditor(rule, items);
                                setModalState(() {});
                              },
                              child: Text('Edit'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton.filled(
                    onPressed: () {
                      _normalizeTemplateInPlace(_template!);
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRestrictionRuleEditor(
    String rule,
    List<dynamic> items,
  ) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 560,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rule: $rule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx] as Map<String, dynamic>;
                      final name = (item['name'] ?? '').toString();
                      final message = (item['message'] ?? '').toString();
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name.isEmpty
                                    ? '(sin name)'
                                    : '$name - $message',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: idx == 0
                                  ? null
                                  : () {
                                      final tmp = items[idx - 1];
                                      items[idx - 1] = items[idx];
                                      items[idx] = tmp;
                                      setState(() {});
                                      setModalState(() {});
                                    },
                              child: Icon(CupertinoIcons.chevron_up),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: idx == items.length - 1
                                  ? null
                                  : () {
                                      final tmp = items[idx + 1];
                                      items[idx + 1] = items[idx];
                                      items[idx] = tmp;
                                      setState(() {});
                                      setModalState(() {});
                                    },
                              child: Icon(CupertinoIcons.chevron_down),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                await _showRestrictionItemEditor(rule, item);
                                setState(() {});
                                setModalState(() {});
                              },
                              child: Icon(CupertinoIcons.pencil),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                items.removeAt(idx);
                                setState(() {});
                                setModalState(() {});
                              },
                              child: Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: () async {
                        final newItem = <String, dynamic>{
                          'name': '',
                          'message': 'Campo inválido',
                        };
                        if (_ruleNeedsValue(rule)) newItem['value'] = '';
                        items.add(newItem);
                        await _showRestrictionItemEditor(rule, newItem);
                        setState(() {});
                        setModalState(() {});
                      },
                      child: Text('+ Add Restriction'),
                    ),
                    Spacer(),
                    CupertinoButton.filled(
                      onPressed: () {
                        _normalizeTemplateInPlace(_template!);
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRestrictionItemEditor(
    String rule,
    Map<String, dynamic> item,
  ) async {
    final nameController = TextEditingController(
      text: (item['name'] ?? '').toString(),
    );
    final messageController = TextEditingController(
      text: (item['message'] ?? '').toString(),
    );
    final subnameController = TextEditingController(
      text: (item['subname'] ?? '').toString(),
    );
    final valueController = TextEditingController(
      text: (item['value'] ?? '').toString(),
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          height: 340,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit restriction item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'name',
              ),
              SizedBox(height: 8),
              if (_ruleNeedsValue(rule)) ...[
                CupertinoTextField(
                  controller: valueController,
                  placeholder: 'value',
                ),
                SizedBox(height: 8),
              ],
              CupertinoTextField(
                controller: messageController,
                placeholder: 'message',
              ),
              SizedBox(height: 8),
              CupertinoTextField(
                controller: subnameController,
                placeholder: 'subname (optional)',
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        item['name'] = nameController.text.trim();
                        item['message'] = messageController.text.trim().isEmpty
                            ? 'Campo inválido'
                            : messageController.text.trim();
                        if (_ruleNeedsValue(rule)) {
                          item['value'] = valueController.text.trim();
                        } else {
                          item.remove('value');
                        }
                        if (subnameController.text.trim().isEmpty) {
                          item.remove('subname');
                        } else {
                          item['subname'] = subnameController.text.trim();
                        }
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text('Save'),
                    ),
                  ),
                  SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    nameController.dispose();
    messageController.dispose();
    subnameController.dispose();
    valueController.dispose();
  }

  bool _ruleNeedsValue(String rule) {
    return rule == 'lessThan' || rule == 'greaterThan';
  }

  void _addField(String sectionKey, String type) {
    final fields = _template!['fields'] as Map<String, dynamic>;
    final sectionFields = fields[sectionKey] as List<dynamic>;
    final name = _nextFieldName();
    final field = _newFieldByType(type, name);
    sectionFields.add(field);
    _normalizeFieldInPlace(field);
    _previewForm.syncFromTemplate(_template!);

    setState(() {
      _selectedSection = sectionKey;
      _selectedFieldIndex = sectionFields.length - 1;
    });
  }

  Map<String, dynamic> _newFieldByType(String type, String name) {
    switch (type) {
      case 'input':
        return <String, dynamic>{
          'name': name,
          'type': 'input',
          'label': '',
          'inputType': 'text',
        };
      case 'select':
        return <String, dynamic>{
          'name': name,
          'type': 'select',
          'label': '',
          'options': <dynamic>['Opcion 1'],
        };
      case 'textarea':
        return <String, dynamic>{
          'name': name,
          'type': 'textarea',
          'label': '',
          'rows': 3,
        };
      case 'multiple':
        return <String, dynamic>{
          'name': name,
          'type': 'multiple',
          'label': '',
          'inputType': 'radio',
          'options': <dynamic>['Opcion 1'],
        };
      case 'drawingboard':
        return <String, dynamic>{
          'name': name,
          'type': 'drawingboard',
          'label': '',
          'secondaryLabel': 'Firma / Dibujo',
          'text': '',
        };
      case 'tuple':
        return <String, dynamic>{
          'name': name,
          'type': 'tuple',
          'label': 'Lista',
          'tuple': <dynamic>[],
        };
      case 'text':
      default:
        return <String, dynamic>{
          'name': name,
          'type': 'text',
          'text': 'Nuevo texto',
        };
    }
  }

  void _deleteField(String sectionKey, int index) {
    final sectionFields =
        (_template!['fields'] as Map<String, dynamic>)[sectionKey]
            as List<dynamic>;
    final field = sectionFields[index] as Map<String, dynamic>;
    final name = (field['name'] ?? '').toString();

    sectionFields.removeAt(index);
    if (name.isNotEmpty) {
      _previewForm.removeField(name);
    }

    setState(() {
      if (_selectedSection == sectionKey && _selectedFieldIndex == index) {
        _selectedFieldIndex = null;
        _selectedSection = null;
      } else if (_selectedSection == sectionKey &&
          _selectedFieldIndex != null &&
          _selectedFieldIndex! > index) {
        _selectedFieldIndex = _selectedFieldIndex! - 1;
      }
    });
  }

  void _moveField(String sectionKey, int index, int direction) {
    final sectionFields =
        (_template!['fields'] as Map<String, dynamic>)[sectionKey]
            as List<dynamic>;
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= sectionFields.length) return;

    final tmp = sectionFields[index];
    sectionFields[index] = sectionFields[newIndex];
    sectionFields[newIndex] = tmp;

    setState(() {
      if (_selectedSection == sectionKey && _selectedFieldIndex == index) {
        _selectedFieldIndex = newIndex;
      }
    });
  }

  Future<void> _showAddFieldActionSheet(String sectionKey) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Agregar campo'),
        actions: [
          for (final type in _dslFieldTypes)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _addField(sectionKey, type);
              },
              child: Text(type),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _showFieldEditor(Map<String, dynamic> field) async {
    final oldName = (field['name'] ?? '').toString();
    final draft = _deepCopyMap(field);
    _normalizeFieldInPlace(draft);

    var draftType = (draft['type'] ?? 'text').toString();
    var draftInputType = (draft['inputType'] ?? 'text').toString();
    var draftMultiple = draft['multiple'] == true;

    final nameController = TextEditingController(
      text: (draft['name'] ?? '').toString(),
    );
    final labelController = TextEditingController(
      text: (draft['label'] ?? '').toString(),
    );
    final textController = TextEditingController(
      text: (draft['text'] ?? '').toString(),
    );
    final rowsController = TextEditingController(
      text: (draft['rows'] ?? '').toString(),
    );
    final secondaryLabelController = TextEditingController(
      text: (draft['secondaryLabel'] ?? '').toString(),
    );
    final backgroundController = TextEditingController(
      text: (draft['background'] ?? '').toString(),
    );
    final ratioController = TextEditingController(
      text: (draft['aspect_ratio'] ?? '').toString(),
    );

    List<dynamic> draftOptions = draft['options'] is List<dynamic>
        ? List<dynamic>.from(draft['options'] as List<dynamic>)
        : <dynamic>[];

    Map<String, dynamic> draftDisplayOn =
        draft['displayOn'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(draft['displayOn'] as Map<String, dynamic>)
        : <String, dynamic>{};

    List<dynamic> draftTuple = draft['tuple'] is List<dynamic>
        ? List<dynamic>.from(draft['tuple'] as List<dynamic>)
        : <dynamic>[];

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 640,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Field Editor',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'name',
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    await showCupertinoModalPopup<void>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: Text('type'),
                        actions: [
                          for (final type in _dslFieldTypes)
                            CupertinoActionSheetAction(
                              onPressed: () {
                                draftType = type;
                                draft['type'] = draftType;
                                _normalizeFieldInPlace(draft);
                                draftInputType = (draft['inputType'] ?? 'text')
                                    .toString();
                                draftMultiple = draft['multiple'] == true;
                                labelController.text = (draft['label'] ?? '')
                                    .toString();
                                textController.text = (draft['text'] ?? '')
                                    .toString();
                                rowsController.text = (draft['rows'] ?? '')
                                    .toString();
                                secondaryLabelController.text =
                                    (draft['secondaryLabel'] ?? '').toString();
                                backgroundController.text =
                                    (draft['background'] ?? '').toString();
                                ratioController.text =
                                    (draft['aspect_ratio'] ?? '').toString();
                                draftOptions = draft['options'] is List<dynamic>
                                    ? List<dynamic>.from(
                                        draft['options'] as List<dynamic>,
                                      )
                                    : <dynamic>[];
                                draftTuple = draft['tuple'] is List<dynamic>
                                    ? List<dynamic>.from(
                                        draft['tuple'] as List<dynamic>,
                                      )
                                    : <dynamic>[];
                                setModalState(() {});
                                Navigator.pop(context);
                              },
                              child: Text(type),
                            ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('type: $draftType'),
                        Icon(CupertinoIcons.chevron_down),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                if (draftType != 'text' || draft.containsKey('label'))
                  CupertinoTextField(
                    controller: labelController,
                    placeholder: 'label',
                  ),
                if (draftType == 'text' || draftType == 'drawingboard') ...[
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: textController,
                    placeholder: 'text',
                    maxLines: draftType == 'drawingboard' ? 5 : 3,
                  ),
                ],
                if (draftType == 'input' || draftType == 'multiple') ...[
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final choices = draftType == 'input'
                          ? _dslInputTypes
                          : _dslMultipleInputTypes;
                      await showCupertinoModalPopup<void>(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: Text('inputType'),
                          actions: [
                            for (final inputType in choices)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  draftInputType = inputType;
                                  setModalState(() {});
                                  Navigator.pop(context);
                                },
                                child: Text(inputType),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar'),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('inputType: $draftInputType'),
                          Icon(CupertinoIcons.chevron_down),
                        ],
                      ),
                    ),
                  ),
                ],
                if (draftType == 'input') ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('multiple'),
                      Spacer(),
                      CupertinoSwitch(
                        value: draftMultiple,
                        onChanged: (value) {
                          draftMultiple = value;
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ],
                if (draftType == 'textarea') ...[
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: rowsController,
                    placeholder: 'rows',
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (draftType == 'drawingboard') ...[
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: secondaryLabelController,
                    placeholder: 'secondaryLabel',
                  ),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: ratioController,
                    placeholder: 'aspect_ratio (optional)',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: backgroundController,
                    placeholder: 'background (optional)',
                    maxLines: 3,
                  ),
                ],
                SizedBox(height: 8),
                if (draftType == 'input' ||
                    draftType == 'select' ||
                    draftType == 'multiple')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await _showOptionsEditor(
                        draftOptions,
                        requiredAtLeastOne:
                            draftType == 'select' || draftType == 'multiple',
                        title: 'options',
                      );
                      setModalState(() {});
                    },
                    child: Text('Edit options (${draftOptions.length})'),
                  ),
                if (draftType == 'tuple')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await _showTupleEditor(draftTuple);
                      setModalState(() {});
                    },
                    child: Text('Edit tuple (${draftTuple.length})'),
                  ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await _showDisplayOnEditor(draftDisplayOn);
                    setModalState(() {});
                  },
                  child: Text(
                    'Edit displayOn (${_displayOnCount(draftDisplayOn)})',
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          draft['name'] = _sanitizeName(nameController.text);
                          if ((draft['name'] ?? '').toString().isEmpty) {
                            draft['name'] = _nextFieldName();
                          }

                          draft['type'] = draftType;
                          if ((labelController.text).isNotEmpty) {
                            draft['label'] = labelController.text;
                          } else {
                            draft.remove('label');
                          }

                          if (draftType == 'text' ||
                              draftType == 'drawingboard') {
                            draft['text'] = textController.text;
                          } else {
                            draft.remove('text');
                          }

                          if (draftType == 'input' || draftType == 'multiple') {
                            draft['inputType'] = draftInputType;
                          } else {
                            draft.remove('inputType');
                          }

                          if (draftType == 'input') {
                            if (draftMultiple) {
                              draft['multiple'] = true;
                            } else {
                              draft.remove('multiple');
                            }
                          } else {
                            draft.remove('multiple');
                          }

                          if (draftType == 'textarea') {
                            final rows = int.tryParse(
                              rowsController.text.trim(),
                            );
                            if (rows != null) {
                              draft['rows'] = rows;
                            } else {
                              draft.remove('rows');
                            }
                          } else {
                            draft.remove('rows');
                          }

                          if (draftType == 'drawingboard') {
                            if (secondaryLabelController.text
                                .trim()
                                .isNotEmpty) {
                              draft['secondaryLabel'] =
                                  secondaryLabelController.text;
                            } else {
                              draft.remove('secondaryLabel');
                            }

                            final ratio = double.tryParse(
                              ratioController.text.trim(),
                            );
                            if (ratio != null) {
                              draft['aspect_ratio'] = ratio;
                            } else {
                              draft.remove('aspect_ratio');
                            }

                            if (backgroundController.text.trim().isNotEmpty) {
                              draft['background'] = backgroundController.text;
                            } else {
                              draft.remove('background');
                            }
                          } else {
                            draft.remove('secondaryLabel');
                            draft.remove('aspect_ratio');
                            draft.remove('background');
                          }

                          if (draftType == 'input' ||
                              draftType == 'select' ||
                              draftType == 'multiple') {
                            draft['options'] = List<dynamic>.from(draftOptions);
                          } else {
                            draft.remove('options');
                          }

                          if (draftType == 'tuple') {
                            draft['tuple'] = List<dynamic>.from(draftTuple);
                          } else {
                            draft.remove('tuple');
                          }

                          final displayOnClean = <String, dynamic>{};
                          for (final key in [
                            'notEmpty',
                            'isEmpty',
                            'equalTo',
                            'includes',
                          ]) {
                            final list = draftDisplayOn[key];
                            if (list is List<dynamic> && list.isNotEmpty) {
                              displayOnClean[key] = list;
                            }
                          }
                          if (displayOnClean.isEmpty) {
                            draft.remove('displayOn');
                          } else {
                            draft['displayOn'] = displayOnClean;
                          }

                          _normalizeFieldInPlace(draft);

                          final used = _collectFieldNames();
                          used.remove(oldName);
                          final uniqueName = _ensureUniqueName(
                            _sanitizeName((draft['name'] ?? '').toString()),
                            used: used,
                          );
                          draft['name'] = uniqueName;

                          field
                            ..clear()
                            ..addAll(draft);

                          if (oldName != uniqueName && oldName.isNotEmpty) {
                            _previewForm.renameField(oldName, uniqueName);
                          }
                          _normalizeTemplateInPlace(_template!);
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: Text('Save'),
                      ),
                    ),
                    SizedBox(width: 8),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    labelController.dispose();
    textController.dispose();
    rowsController.dispose();
    secondaryLabelController.dispose();
    backgroundController.dispose();
    ratioController.dispose();
  }

  Future<void> _showOptionsEditor(
    List<dynamic> options, {
    required bool requiredAtLeastOne,
    required String title,
  }) async {
    final controllers = options
        .map((o) => TextEditingController(text: o.toString()))
        .toList();
    if (controllers.isEmpty) {
      controllers.add(TextEditingController(text: 'Opcion 1'));
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 520,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: controllers.length,
                    itemBuilder: (context, idx) => Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            controller: controllers[idx],
                            placeholder: 'Opcion ${idx + 1}',
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: idx == 0
                              ? null
                              : () {
                                  setModalState(() {
                                    final c = controllers.removeAt(idx);
                                    controllers.insert(idx - 1, c);
                                  });
                                },
                          child: Icon(CupertinoIcons.chevron_up),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: idx == controllers.length - 1
                              ? null
                              : () {
                                  setModalState(() {
                                    final c = controllers.removeAt(idx);
                                    controllers.insert(idx + 1, c);
                                  });
                                },
                          child: Icon(CupertinoIcons.chevron_down),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (requiredAtLeastOne && controllers.length <= 1) {
                              return;
                            }
                            setModalState(() {
                              final removed = controllers.removeAt(idx);
                              removed.dispose();
                            });
                          },
                          child: Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: () {
                        setModalState(() {
                          controllers.add(TextEditingController());
                        });
                      },
                      child: Text('+ Add Option'),
                    ),
                    Spacer(),
                    CupertinoButton.filled(
                      onPressed: () {
                        options
                          ..clear()
                          ..addAll(
                            controllers
                                .map((c) => c.text.trim())
                                .where((v) => v.isNotEmpty),
                          );
                        if (requiredAtLeastOne && options.isEmpty) {
                          options.add('Opcion 1');
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final c in controllers) {
      c.dispose();
    }
  }

  int _displayOnCount(Map<String, dynamic> displayOn) {
    int total = 0;
    for (final key in ['notEmpty', 'isEmpty', 'equalTo', 'includes']) {
      final list = displayOn[key];
      if (list is List<dynamic>) total += list.length;
    }
    return total;
  }

  Future<void> _showDisplayOnEditor(Map<String, dynamic> displayOn) async {
    for (final key in ['notEmpty', 'isEmpty', 'equalTo', 'includes']) {
      displayOn[key] ??= <dynamic>[];
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 500,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'displayOn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDisplayRow(
                        keyName: 'notEmpty',
                        displayOn: displayOn,
                        onEdited: () => setModalState(() {}),
                      ),
                      _buildDisplayRow(
                        keyName: 'isEmpty',
                        displayOn: displayOn,
                        onEdited: () => setModalState(() {}),
                      ),
                      _buildDisplayRow(
                        keyName: 'equalTo',
                        displayOn: displayOn,
                        onEdited: () => setModalState(() {}),
                      ),
                      _buildDisplayRow(
                        keyName: 'includes',
                        displayOn: displayOn,
                        onEdited: () => setModalState(() {}),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton.filled(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayRow({
    required String keyName,
    required Map<String, dynamic> displayOn,
    required VoidCallback onEdited,
  }) {
    final list = displayOn[keyName] as List<dynamic>;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text('$keyName (${list.length})')),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () async {
              await _showDisplayConditionEditor(
                keyName: keyName,
                refs: list,
                requiresValue: keyName == 'equalTo' || keyName == 'includes',
              );
              onEdited();
            },
            child: Text('Edit'),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              list.clear();
              onEdited();
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDisplayConditionEditor({
    required String keyName,
    required List<dynamic> refs,
    required bool requiresValue,
  }) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 540,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: refs.length,
                    itemBuilder: (context, idx) {
                      final ref = refs[idx] as Map<String, dynamic>;
                      final text = requiresValue
                          ? '${ref['name'] ?? ''} = ${ref['value'] ?? ''}'
                          : '${ref['name'] ?? ''}';
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(text)),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                await _showDisplayRefItemEditor(
                                  ref: ref,
                                  requiresValue: requiresValue,
                                );
                                setModalState(() {});
                              },
                              child: Icon(CupertinoIcons.pencil),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                refs.removeAt(idx);
                                setModalState(() {});
                              },
                              child: Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: () async {
                        final ref = <String, dynamic>{'name': ''};
                        if (requiresValue) ref['value'] = '';
                        refs.add(ref);
                        await _showDisplayRefItemEditor(
                          ref: ref,
                          requiresValue: requiresValue,
                        );
                        setModalState(() {});
                      },
                      child: Text('+ Add Condition'),
                    ),
                    Spacer(),
                    CupertinoButton.filled(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDisplayRefItemEditor({
    required Map<String, dynamic> ref,
    required bool requiresValue,
  }) async {
    final nameController = TextEditingController(
      text: (ref['name'] ?? '').toString(),
    );
    final valueController = TextEditingController(
      text: (ref['value'] ?? '').toString(),
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Condition item',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'name',
              ),
              if (requiresValue) ...[
                SizedBox(height: 8),
                CupertinoTextField(
                  controller: valueController,
                  placeholder: 'value',
                ),
              ],
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        ref['name'] = nameController.text.trim();
                        if (requiresValue) {
                          ref['value'] = valueController.text.trim();
                        } else {
                          ref.remove('value');
                        }
                        Navigator.pop(context);
                      },
                      child: Text('Save'),
                    ),
                  ),
                  SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    nameController.dispose();
    valueController.dispose();
  }

  Future<void> _showTupleEditor(List<dynamic> tupleFields) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 560,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tuple',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: tupleFields.length,
                    itemBuilder: (context, idx) {
                      final sub = tupleFields[idx] as Map<String, dynamic>;
                      final name = (sub['name'] ?? '').toString();
                      final type = (sub['type'] ?? '').toString();
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('$name [$type]')),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: idx == 0
                                  ? null
                                  : () {
                                      final tmp = tupleFields[idx - 1];
                                      tupleFields[idx - 1] = tupleFields[idx];
                                      tupleFields[idx] = tmp;
                                      setModalState(() {});
                                    },
                              child: Icon(CupertinoIcons.chevron_up),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: idx == tupleFields.length - 1
                                  ? null
                                  : () {
                                      final tmp = tupleFields[idx + 1];
                                      tupleFields[idx + 1] = tupleFields[idx];
                                      tupleFields[idx] = tmp;
                                      setModalState(() {});
                                    },
                              child: Icon(CupertinoIcons.chevron_down),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                await _showTupleSubfieldEditor(sub);
                                setModalState(() {});
                              },
                              child: Icon(CupertinoIcons.pencil),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                tupleFields.removeAt(idx);
                                setModalState(() {});
                              },
                              child: Icon(
                                CupertinoIcons.delete,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      onPressed: () async {
                        final used = <String>{};
                        for (final item in tupleFields) {
                          if (item is Map<String, dynamic>) {
                            final n = (item['name'] ?? '').toString();
                            if (n.isNotEmpty) used.add(n);
                          }
                        }
                        final sub = <String, dynamic>{
                          'name': _ensureUniqueName('subcampo', used: used),
                          'type': 'input',
                          'label': '',
                          'inputType': 'text',
                        };
                        tupleFields.add(sub);
                        await _showTupleSubfieldEditor(sub);
                        setModalState(() {});
                      },
                      child: Text('+ Add Subfield'),
                    ),
                    Spacer(),
                    CupertinoButton.filled(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTupleSubfieldEditor(Map<String, dynamic> subfield) async {
    final draft = _deepCopyMap(subfield);
    _normalizeTupleSubfieldInPlace(draft);

    var subType = (draft['type'] ?? 'input').toString();
    var subInputType = (draft['inputType'] ?? 'text').toString();
    var draftOptions = draft['options'] is List<dynamic>
        ? List<dynamic>.from(draft['options'] as List<dynamic>)
        : <dynamic>[];

    final nameController = TextEditingController(
      text: (draft['name'] ?? '').toString(),
    );
    final labelController = TextEditingController(
      text: (draft['label'] ?? '').toString(),
    );
    final textController = TextEditingController(
      text: (draft['text'] ?? '').toString(),
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: 540,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tuple subfield',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'name',
                ),
                SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    await showCupertinoModalPopup<void>(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: Text('type'),
                        actions: [
                          for (final t in ['input', 'multiple', 'text'])
                            CupertinoActionSheetAction(
                              onPressed: () {
                                subType = t;
                                if (subType == 'input') {
                                  subInputType =
                                      _dslInputTypes.contains(subInputType)
                                      ? subInputType
                                      : 'text';
                                } else if (subType == 'multiple') {
                                  subInputType =
                                      _dslMultipleInputTypes.contains(
                                        subInputType,
                                      )
                                      ? subInputType
                                      : 'radio';
                                }
                                setModalState(() {});
                                Navigator.pop(context);
                              },
                              child: Text(t),
                            ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('type: $subType'),
                        Icon(CupertinoIcons.chevron_down),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                CupertinoTextField(
                  controller: labelController,
                  placeholder: 'label',
                ),
                if (subType == 'text') ...[
                  SizedBox(height: 8),
                  CupertinoTextField(
                    controller: textController,
                    placeholder: 'text',
                  ),
                ],
                if (subType == 'input' || subType == 'multiple') ...[
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final choices = subType == 'input'
                          ? _dslInputTypes
                          : _dslMultipleInputTypes;
                      await showCupertinoModalPopup<void>(
                        context: context,
                        builder: (context) => CupertinoActionSheet(
                          title: Text('inputType'),
                          actions: [
                            for (final choice in choices)
                              CupertinoActionSheetAction(
                                onPressed: () {
                                  subInputType = choice;
                                  setModalState(() {});
                                  Navigator.pop(context);
                                },
                                child: Text(choice),
                              ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancelar'),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('inputType: $subInputType'),
                          Icon(CupertinoIcons.chevron_down),
                        ],
                      ),
                    ),
                  ),
                ],
                if (subType == 'input' || subType == 'multiple')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await _showOptionsEditor(
                        draftOptions,
                        requiredAtLeastOne: subType == 'multiple',
                        title: 'options',
                      );
                      setModalState(() {});
                    },
                    child: Text('Edit options (${draftOptions.length})'),
                  ),
                Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          draft['name'] = _sanitizeName(nameController.text);
                          draft['type'] = subType;
                          if (labelController.text.trim().isEmpty) {
                            draft.remove('label');
                          } else {
                            draft['label'] = labelController.text.trim();
                          }

                          if (subType == 'text') {
                            draft['text'] = textController.text;
                            draft.remove('inputType');
                            draft.remove('options');
                          } else {
                            draft.remove('text');
                            draft['inputType'] = subInputType;
                            draft['options'] = draftOptions;
                          }

                          _normalizeTupleSubfieldInPlace(draft);

                          subfield
                            ..clear()
                            ..addAll(draft);

                          Navigator.pop(context);
                        },
                        child: Text('Save'),
                      ),
                    ),
                    SizedBox(width: 8),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    labelController.dispose();
    textController.dispose();
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> map) {
    final copy = <String, dynamic>{};
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        copy[entry.key] = _deepCopyMap(value);
      } else if (value is List<dynamic>) {
        copy[entry.key] = _deepCopyList(value);
      } else {
        copy[entry.key] = value;
      }
    }
    return copy;
  }

  List<dynamic> _deepCopyList(List<dynamic> list) {
    return list.map((value) {
      if (value is Map<String, dynamic>) {
        return _deepCopyMap(value);
      }
      if (value is List<dynamic>) {
        return _deepCopyList(value);
      }
      return value;
    }).toList();
  }

  List<dynamic>? _formatOptions(List<dynamic>? originalOptions) {
    return originalOptions;
  }

  IconData _sectionIcon(String section, {bool active = false}) {
    switch (section) {
      case 'Servicio':
        return active
            ? CupertinoIcons.plus_square_fill
            : CupertinoIcons.plus_square;
      case 'Paciente':
        return active ? CupertinoIcons.person_fill : CupertinoIcons.person;
      case 'Primaria':
        return active
            ? CupertinoIcons.bag_fill_badge_plus
            : CupertinoIcons.bag_badge_plus;
      case 'Secundaria':
        return active
            ? CupertinoIcons.bag_fill_badge_minus
            : CupertinoIcons.bag_badge_minus;
      case 'Tratamiento':
        return active ? CupertinoIcons.bandage_fill : CupertinoIcons.bandage;
      case 'Resultados':
        return active
            ? CupertinoIcons.doc_chart_fill
            : CupertinoIcons.doc_chart;
      default:
        return active
            ? CupertinoIcons.square_list_fill
            : CupertinoIcons.square_list;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return CupertinoPageScaffold(
        child: CupertinoAlertDialog(
          title: Text('No disponible'),
          content: Text(_loadError!),
          actions: [
            CupertinoDialogAction(
              child: Text('De acuerdo'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    if (_template == null) {
      return CupertinoPageScaffold(
        child: CupertinoAlertDialog(
          title: Text('Cargando...'),
          content: Text('Descargando plantilla'),
          actions: [
            CupertinoDialogAction(
              child: Text('Salir'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }

    _normalizeTemplateInPlace(_template!);
    final sections = _orderedSections();

    if (sections.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Template Maker'),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showTemplateEditor,
            child: Icon(CupertinoIcons.slider_horizontal_3),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: CupertinoButton.filled(
              onPressed: _showTemplateEditor,
              child: Text('Agregar primera sección'),
            ),
          ),
        ),
      );
    }

    return CupertinoTabScaffold(
      backgroundColor: Settings.instance.colors.background,
      tabBar: CupertinoTabBar(
        inactiveColor: Settings.instance.colors.primaryContrastDark,
        activeColor: Settings.instance.colors.primaryContrast,
        backgroundColor: Settings.instance.colors.primary,
        items: [
          for (final section in sections)
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(_sectionIcon(section)),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(_sectionIcon(section, active: true)),
              ),
              label: section,
            ),
        ],
      ),
      tabBuilder: (context, index) {
        final sectionKey = sections[index];
        final fields =
            (_template!['fields'] as Map<String, dynamic>)[sectionKey]
                as List<dynamic>;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Settings.instance.colors.primary,
            automaticBackgroundVisibility: false,
            middle: Text(
              sectionKey,
              style: TextStyle(color: Settings.instance.colors.textOverPrimary),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showTemplateEditor,
              child: Icon(
                CupertinoIcons.slider_horizontal_3,
                color: Settings.instance.colors.primaryContrast,
              ),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _validateTemplate,
              child: Icon(
                CupertinoIcons.check_mark_circled,
                color: Settings.instance.colors.primaryContrast,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: fields.length + 1,
                itemBuilder: (context, idx) {
                  if (idx == fields.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CupertinoButton.filled(
                        onPressed: () => _showAddFieldActionSheet(sectionKey),
                        child: Text('+ Add Field'),
                      ),
                    );
                  }

                  final field = fields[idx] as Map<String, dynamic>;
                  final isSelected =
                      _selectedSection == sectionKey &&
                      _selectedFieldIndex == idx;

                  return EditorFieldWrapper(
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedSection = sectionKey;
                        _selectedFieldIndex = idx;
                      });
                    },
                    onEdit: () async {
                      setState(() {
                        _selectedSection = sectionKey;
                        _selectedFieldIndex = idx;
                      });
                      await _showFieldEditor(field);
                    },
                    onDelete: () => _deleteField(sectionKey, idx),
                    onMoveUp: () => _moveField(sectionKey, idx, -1),
                    onMoveDown: () => _moveField(sectionKey, idx, 1),
                    child: DynamicFieldRenderer(
                      field: field,
                      form: _previewForm,
                      setFormState: setState,
                      formatOptions: _formatOptions,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class EditorFieldWrapper extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const EditorFieldWrapper({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onMoveUp,
                  child: Icon(CupertinoIcons.chevron_up),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onMoveDown,
                  child: Icon(CupertinoIcons.chevron_down),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onEdit,
                  child: Icon(CupertinoIcons.pencil),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                  child: Icon(
                    CupertinoIcons.delete,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _TemplatePreviewForm extends ServiceForm {
  final Map<String, dynamic> _previewContent = <String, dynamic>{};
  final Map<String, Set<String>> _previewErrors = <String, Set<String>>{};
  final Map<String, Map<String, dynamic>> _fieldIndex =
      <String, Map<String, dynamic>>{};

  _TemplatePreviewForm()
    : super(null, -1, '', DateTime.now(), <String, dynamic>{}, 0);

  @override
  Map<String, dynamic> get content => _previewContent;

  @override
  Map<String, dynamic> get errors => _previewErrors;

  @override
  bool get canEditForm => true;

  @override
  void set(String fieldName, dynamic newValue) {
    _previewContent[fieldName] = newValue;
    _previewErrors.remove(fieldName);
  }

  void syncFromTemplate(Map<String, dynamic> template) {
    _fieldIndex.clear();

    final fields = template['fields'] as Map<String, dynamic>;
    for (final sectionFields in fields.values) {
      for (final item in (sectionFields as List<dynamic>)) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] ?? '').toString();
        if (name.isEmpty) continue;
        _fieldIndex[name] = item;
        _previewContent[name] ??= _defaultValueForField(item);
      }
    }

    final knownNames = _fieldIndex.keys.toSet();
    _previewContent.removeWhere((key, _) => !knownNames.contains(key));
    _previewErrors.removeWhere((key, _) => !knownNames.contains(key));

    _evaluateRestrictions(template);
  }

  void renameField(String oldName, String newName) {
    if (oldName == newName || oldName.isEmpty || newName.isEmpty) return;
    if (_previewContent.containsKey(oldName)) {
      _previewContent[newName] = _previewContent.remove(oldName);
    }
    if (_previewErrors.containsKey(oldName)) {
      _previewErrors[newName] = _previewErrors.remove(oldName)!;
    }
  }

  void removeField(String name) {
    _previewContent.remove(name);
    _previewErrors.remove(name);
  }

  @override
  bool shouldDisplay(Map<String, dynamic> field) {
    final List<dynamic> notEmpty =
        field['displayOn']?['notEmpty'] ?? <dynamic>[];
    final List<dynamic> isEmpty = field['displayOn']?['isEmpty'] ?? <dynamic>[];
    final List<dynamic> equalTo = field['displayOn']?['equalTo'] ?? <dynamic>[];
    final List<dynamic> includes =
        field['displayOn']?['includes'] ?? <dynamic>[];

    var visible = true;
    for (final item in notEmpty) {
      final refName = item['name'];
      visible =
          visible &&
          ((_previewContent[refName]?.toString().isNotEmpty) ?? false);
    }
    for (final item in isEmpty) {
      final refName = item['name'];
      visible =
          visible && ((_previewContent[refName]?.toString().isEmpty) ?? true);
    }
    for (final item in equalTo) {
      final refName = item['name'];
      final value = item['value'];
      visible = visible && (_previewContent[refName] == value);
    }
    for (final item in includes) {
      final refName = item['name'];
      final value = item['value'];
      final target = _previewContent[refName];
      if (target is Iterable) {
        visible = visible && target.contains(value);
      } else if (target is String) {
        visible = visible && target.contains(value?.toString() ?? '');
      } else {
        visible = false;
      }
    }
    return visible;
  }

  void _evaluateRestrictions(Map<String, dynamic> template) {
    _previewErrors.clear();
    final restrictions = template['restrictions'] as Map<String, dynamic>?;
    if (restrictions == null) return;

    for (final entry in restrictions.entries) {
      final rule = entry.key;
      final list = entry.value;
      if (list is! List<dynamic>) continue;

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;
        final fieldName = (item['name'] ?? '').toString();
        if (fieldName.isEmpty) continue;

        final field = _fieldIndex[fieldName];
        if (field == null) continue;
        if (!shouldDisplay(field)) {
          _previewErrors.remove(fieldName);
          continue;
        }

        final value = _previewContent[fieldName];
        var passed = true;

        switch (rule) {
          case 'notEmpty':
            passed = value != null && value.toString().trim().isNotEmpty;
            break;
          case 'lessThan':
            final limit = double.tryParse((item['value'] ?? '').toString());
            final actual = value == null
                ? null
                : double.tryParse(value.toString());
            passed = (actual == null || limit == null) ? true : actual < limit;
            break;
          case 'greaterThan':
            final limit = double.tryParse((item['value'] ?? '').toString());
            final actual = value == null
                ? null
                : double.tryParse(value.toString());
            passed = (actual == null || limit == null) ? true : actual > limit;
            break;
          case 'regexOnlyLetters':
            if (value != null && value.toString().isNotEmpty) {
              passed = RegExp(
                r'^[A-Za-zÁÉÍÓÚáéíóúÜüÑñ\s]+$',
              ).hasMatch(value.toString());
            }
            break;
          case 'regexOnlyNumbers':
            if (value != null && value.toString().isNotEmpty) {
              passed = RegExp(r'^[0-9]+$').hasMatch(value.toString());
            }
            break;
          case 'regexPhoneNumber':
            if (value != null && value.toString().isNotEmpty) {
              passed = RegExp(r'^\d{10}$').hasMatch(value.toString());
            }
            break;
          case 'regexEmail':
            if (value != null && value.toString().isNotEmpty) {
              passed = RegExp(
                r'^[\w\.\-]+@([\w\-]+\.)+[A-Za-z]{2,4}$',
              ).hasMatch(value.toString());
            }
            break;
          case 'regexAlphanumeric':
            if (value != null && value.toString().isNotEmpty) {
              passed = RegExp(
                r'^[A-Za-zÁÉÍÓÚáéíóúÜüÑñ0-9\s.,#°\-]+$',
              ).hasMatch(value.toString());
            }
            break;
          default:
            passed = true;
        }

        if (!passed) {
          final message = (item['message'] ?? 'Campo inválido').toString();
          (_previewErrors[fieldName] ??= <String>{}).add(message);
        }
      }
    }
  }

  dynamic _defaultValueForField(Map<String, dynamic> field) {
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
      return null;
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
}
