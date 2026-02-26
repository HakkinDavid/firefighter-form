import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/dynamic_field_renderer.dart';
import 'package:flutter/cupertino.dart';

class ServiceTemplateMaker extends StatefulWidget {
  const ServiceTemplateMaker({super.key});

  @override
  State<ServiceTemplateMaker> createState() => _ServiceTemplateMakerState();
}

class _ServiceTemplateMakerState extends State<ServiceTemplateMaker> {
  Map<String, dynamic>? _template;
  String? _loadError;
  int? _selectedFieldIndex;
  String? _selectedSectionKey;

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
      final template = fetched.$2();
      setState(() {
        _template = template;
        _selectedFieldIndex = null;
        _selectedSectionKey = null;
      });
    } catch (_) {
      setState(() {
        _loadError = "Plantilla no disponible.";
      });
    }
  }

  Future<void> _submitTemplate() async {}

  List<String> _orderedSections() {
    final fields = _template!['fields'] as Map<String, dynamic>;
    final keys = fields.keys.toList();
    final order = _template!['order'] as Map<String, dynamic>? ?? {};
    keys.sort((a, b) => (order[a] ?? 0).compareTo(order[b] ?? 0));
    return keys;
  }

  String _nextFieldName() {
    final fields = _template!['fields'] as Map<String, dynamic>;
    final existing = <String>{};
    for (final sectionFields in fields.values) {
      for (final field in (sectionFields as List<dynamic>)) {
        final name = field['name'];
        if (name is String) existing.add(name);
      }
    }
    int suffix = existing.length + 1;
    while (existing.contains('campo_$suffix')) {
      suffix++;
    }
    return 'campo_$suffix';
  }

  void _addField(String sectionKey, String fieldType) {
    final sectionFields = _template!['fields'][sectionKey] as List<dynamic>;
    final fieldName = _nextFieldName();

    late final Map<String, dynamic> field;
    if (fieldType == 'input') {
      field = {
        'name': fieldName,
        'label': 'Nuevo campo',
        'type': 'input',
        'inputType': 'text',
      };
    } else if (fieldType == 'select') {
      field = {
        'name': fieldName,
        'label': 'Nuevo campo',
        'type': 'select',
        'options': ['Opcion 1'],
      };
    } else if (fieldType == 'textarea') {
      field = {
        'name': fieldName,
        'label': 'Nuevo campo',
        'type': 'textarea',
        'rows': 3,
      };
    } else if (fieldType == 'multiple') {
      field = {
        'name': fieldName,
        'label': 'Nuevo campo',
        'type': 'multiple',
        'inputType': 'radio',
        'options': ['Opcion 1'],
      };
    } else if (fieldType == 'drawingboard') {
      field = {
        'name': fieldName,
        'label': '',
        'secondaryLabel': 'Firma / Dibujo',
        'text': '',
        'type': 'drawingboard',
      };
    } else if (fieldType == 'tuple') {
      field = {
        'name': fieldName,
        'label': 'Lista',
        'type': 'tuple',
        'tuple': <dynamic>[],
      };
    } else {
      field = {'name': fieldName, 'type': 'text', 'text': 'Nuevo texto'};
    }

    sectionFields.add(field);
    _previewForm.ensureFieldValue(field);
    setState(() {
      _selectedSectionKey = sectionKey;
      _selectedFieldIndex = sectionFields.length - 1;
    });
  }

  void _deleteField(String sectionKey, int index) {
    final sectionFields = _template!['fields'][sectionKey] as List<dynamic>;
    final field = sectionFields[index] as Map<String, dynamic>;
    sectionFields.removeAt(index);
    _previewForm.content.remove(field['name']);
    setState(() {
      if (_selectedSectionKey == sectionKey && _selectedFieldIndex == index) {
        _selectedFieldIndex = null;
        _selectedSectionKey = null;
      } else if (_selectedSectionKey == sectionKey &&
          _selectedFieldIndex != null &&
          _selectedFieldIndex! > index) {
        _selectedFieldIndex = _selectedFieldIndex! - 1;
      }
    });
  }

  void _moveField(String sectionKey, int index, int direction) {
    final sectionFields = _template!['fields'][sectionKey] as List<dynamic>;
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= sectionFields.length) return;
    final tmp = sectionFields[index];
    sectionFields[index] = sectionFields[newIndex];
    sectionFields[newIndex] = tmp;
    setState(() {
      if (_selectedSectionKey == sectionKey && _selectedFieldIndex == index) {
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
          for (final fieldType in const [
            'input',
            'select',
            'textarea',
            'multiple',
            'drawingboard',
            'tuple',
            'text',
          ])
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _addField(sectionKey, fieldType);
              },
              child: Text(fieldType),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _showEditFieldPopup(Map<String, dynamic> field) async {
    final nameController = TextEditingController(
      text: (field['name'] ?? '').toString(),
    );
    final labelController = TextEditingController(
      text: (field['label'] ?? '').toString(),
    );
    final inputTypeController = TextEditingController(
      text: (field['inputType'] ?? '').toString(),
    );
    final optionsController = TextEditingController(
      text: (field['options'] is List<dynamic>)
          ? (field['options'] as List<dynamic>)
                .map((e) => e.toString())
                .join('\n')
          : '',
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          height: 440,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar campo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              CupertinoTextField(
                controller: nameController,
                placeholder: 'name',
              ),
              SizedBox(height: 8),
              CupertinoTextField(
                controller: labelController,
                placeholder: 'label',
              ),
              if ((field['type'] ?? '') == 'input') ...[
                SizedBox(height: 8),
                CupertinoTextField(
                  controller: inputTypeController,
                  placeholder: 'inputType',
                ),
              ],
              if ((field['type'] ?? '') == 'select' ||
                  (field['type'] ?? '') == 'multiple' ||
                  (field['type'] ?? '') == 'input' ||
                  field['options'] is List<dynamic>) ...[
                SizedBox(height: 8),
                CupertinoTextField(
                  controller: optionsController,
                  placeholder: 'options (una por linea)',
                  maxLines: 5,
                ),
              ],
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        final oldName = field['name']?.toString() ?? '';
                        final newName = nameController.text.trim();
                        field['name'] = newName.isEmpty ? oldName : newName;
                        field['label'] = labelController.text;
                        if ((field['type'] ?? '') == 'input' &&
                            inputTypeController.text.trim().isNotEmpty) {
                          field['inputType'] = inputTypeController.text.trim();
                        }
                        if ((field['type'] ?? '') == 'select' ||
                            (field['type'] ?? '') == 'multiple' ||
                            (field['type'] ?? '') == 'input' ||
                            field['options'] is List<dynamic>) {
                          final options = optionsController.text
                              .split('\n')
                              .map((line) => line.trim())
                              .where((line) => line.isNotEmpty)
                              .toList();
                          field['options'] = options;
                        }
                        if (oldName != field['name'] &&
                            _previewForm.content.containsKey(oldName)) {
                          _previewForm.content[field['name']] = _previewForm
                              .content
                              .remove(oldName);
                        }
                        _previewForm.ensureFieldValue(
                          field,
                          resetIfExists: true,
                        );
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text('Guardar'),
                    ),
                  ),
                  SizedBox(width: 8),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    nameController.dispose();
    labelController.dispose();
    inputTypeController.dispose();
    optionsController.dispose();
  }

  List<dynamic>? _formatOptions(List<dynamic>? originalOptions) {
    return originalOptions;
  }

  IconData _sectionIcon(String section) {
    switch (section) {
      case 'Servicio':
        return CupertinoIcons.plus_square;
      case 'Paciente':
        return CupertinoIcons.person;
      case 'Primaria':
        return CupertinoIcons.bag_badge_plus;
      case 'Secundaria':
        return CupertinoIcons.bag_badge_minus;
      case 'Tratamiento':
        return CupertinoIcons.bandage;
      case 'Resultados':
        return CupertinoIcons.doc_chart;
      default:
        return CupertinoIcons.square_list;
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

    final sectionKeys = _orderedSections();
    return CupertinoTabScaffold(
      backgroundColor: Settings.instance.colors.background,
      tabBar: CupertinoTabBar(
        inactiveColor: Settings.instance.colors.primaryContrastDark,
        activeColor: Settings.instance.colors.primaryContrast,
        backgroundColor: Settings.instance.colors.primary,
        items: [
          for (final section in sectionKeys)
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(_sectionIcon(section)),
              ),
              label: section,
            ),
        ],
      ),
      tabBuilder: (context, index) {
        final sectionKey = sectionKeys[index];
        final fields = _template!['fields'][sectionKey] as List<dynamic>;
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Settings.instance.colors.primary,
            automaticBackgroundVisibility: false,
            middle: Text(
              'Editor de plantilla',
              style: TextStyle(color: Settings.instance.colors.textOverPrimary),
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.only(bottom: 6),
              alignment: AlignmentGeometry.centerRight,
              onPressed: () => Navigator.pop(context),
              child: Icon(
                CupertinoIcons.clear,
                size: 28,
                color: Settings.instance.colors.primaryContrast,
              ),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.only(bottom: 6),
              alignment: AlignmentGeometry.centerLeft,
              onPressed: _submitTemplate,
              child: Icon(
                CupertinoIcons.cloud_upload,
                size: 28,
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
                        child: Text('Añadir campo'),
                      ),
                    );
                  }

                  final field = fields[idx] as Map<String, dynamic>;
                  _previewForm.ensureFieldValue(field);
                  final isSelected =
                      _selectedSectionKey == sectionKey &&
                      _selectedFieldIndex == idx;

                  return EditorFieldWrapper(
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedSectionKey = sectionKey;
                        _selectedFieldIndex = idx;
                      });
                      _showEditFieldPopup(field);
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
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const EditorFieldWrapper({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
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
  final Map<String, dynamic> _previewContent = {};
  final Map<String, Set<String>> _previewErrors = {};

  _TemplatePreviewForm() : super(null, -1, '', DateTime.now(), {}, 0);

  @override
  Map<String, dynamic> get content => _previewContent;

  @override
  Map<String, dynamic> get errors => _previewErrors;

  @override
  bool get canEditForm => false;

  @override
  bool shouldDisplay(Map<String, dynamic> field) => true;

  @override
  void set(String fieldName, dynamic newValue) {
    _previewContent[fieldName] = newValue;
  }

  void ensureFieldValue(
    Map<String, dynamic> field, {
    bool resetIfExists = false,
  }) {
    final name = field['name'];
    if (name == null) return;
    if (!resetIfExists && _previewContent.containsKey(name)) return;
    _previewContent[name] = _defaultValueForField(field);
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
