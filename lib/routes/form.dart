import 'package:bomberos/models/form.dart';
import 'package:bomberos/viewmodels/fields/checkbox_multiple_field.dart';
import 'package:bomberos/viewmodels/fields/date_input_field.dart';
import 'package:bomberos/viewmodels/fields/drawing_board_field.dart';
import 'package:bomberos/viewmodels/fields/multiple_input_field.dart';
import 'package:bomberos/viewmodels/fields/number_input_field.dart';
import 'package:bomberos/viewmodels/fields/options_input_field.dart';
import 'package:bomberos/viewmodels/fields/radio_multiple_field.dart';
import 'package:bomberos/viewmodels/fields/select_field.dart';
import 'package:bomberos/viewmodels/fields/text_display_field.dart';
import 'package:bomberos/viewmodels/fields/text_input_field.dart';
import 'package:bomberos/viewmodels/fields/textarea_field.dart';
import 'package:bomberos/viewmodels/fields/time_input_field.dart';
import 'package:bomberos/viewmodels/fields/tuple_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:bomberos/models/settings.dart';

class DynamicFormPage extends StatefulWidget {
  final ServiceForm form;

  const DynamicFormPage({super.key, required this.form});

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends State<DynamicFormPage> {
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

  String? loadError;

  bool _sectionHasErrors(String sectionKey) {
    final sectionFields = widget.form.sections[sectionKey] as List<dynamic>;
    for (final field in sectionFields) {
      final name = field['name'];
      if (name != null &&
          widget.form.errors.containsKey(name) &&
          widget.form.errors[name]!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Widget _sectionBarItemIcon(String section, {bool active = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(_sectionIcon(section, active: active)),
        if (_sectionHasErrors(section))
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Settings.instance.colors.attentionBadge,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  void _exitForm() {
    Navigator.pop(context);
  }

  Future<void> _saveForm({bool shouldSetAsFinished = false}) async {
    await widget.form.save(shouldSetAsFinished: shouldSetAsFinished);
    _exitForm();
  }

  Future<void> _finishForm() async {
    await _saveForm(shouldSetAsFinished: true);
  }

  Future<void> _loadForm() async {
    try {
      await widget.form.load();
      setState(() {});
    } catch (exception) {
      setState(() {
        loadError = !exception.toString().contains("Postgrest")
            ? "Formulario no disponible, conéctate a Internet."
            : "Plantilla no disponible.";
      });
    }
  }

  List<dynamic>? formatOptions(List<dynamic>? originalOptions) {
    if (originalOptions == null) return null;
    final options = List<dynamic>.from(originalOptions);
    for (int i = 0; i < options.length; i++) {
      if (options[i] is String) {
        options[i] = (options[i] as String).replaceAll(
          '{filler}',
          Settings.instance.getUserOrFail(widget.form.filler).fullName,
        );
      }
    }
    return options;
  }

  Widget buildField(Map<String, dynamic> field) {
    final String type = field['type'];
    final dynamic value = widget.form.content[field['name']];
    final Set<String> errors = widget.form.errors[field['name']] ?? <String>{};

    if (!widget.form.shouldDisplay(field)) return SizedBox.shrink();

    Widget fieldWidget;

    if (type == 'input') {
      if (field['inputType'] == 'date') {
        fieldWidget = DateInputField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['inputType'] == 'time') {
        fieldWidget = TimeInputField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['multiple'] == true) {
        fieldWidget = MultipleInputField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['inputType'] == 'number') {
        fieldWidget = NumberInputField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['options'] != null &&
          field['options'] is List<dynamic> &&
          field['options'].isNotEmpty) {
        fieldWidget = OptionsInputField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else {
        fieldWidget = TextInputField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      }
    } else if (type == 'select') {
      fieldWidget = SelectField(
        field: field,
        value: value,
        formSet: widget.form.set,
        canEditForm: widget.form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'textarea') {
      fieldWidget = TextAreaField(
        field: field,
        value: value,
        formSet: widget.form.set,
        canEditForm: widget.form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'multiple') {
      if (field['inputType'] == 'checkbox') {
        fieldWidget = CheckboxMultipleField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['inputType'] == 'radio') {
        fieldWidget = RadioMultipleField(
          field: field,
          value: value,
          formSet: widget.form.set,
          canEditForm: widget.form.canEditForm,
          formatOptions: formatOptions,
        );
      } else {
        fieldWidget = SizedBox.shrink();
      }
    } else if (type == 'drawingboard') {
      fieldWidget = DrawingBoardField(
        field: field,
        value: value,
        formSet: widget.form.set,
        canEditForm: widget.form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'tuple') {
      fieldWidget = TupleField(
        field: field,
        value: value,
        formSet: widget.form.set,
        canEditForm: widget.form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'text') {
      fieldWidget = TextDisplayField(
        field: field,
        value: value,
        formSet: widget.form.set,
        canEditForm: widget.form.canEditForm,
        formatOptions: formatOptions,
      );
    } else {
      fieldWidget = SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        fieldWidget,
        if (errors.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errors
                  .map(
                    (e) => Text(
                      e,
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadError != null) {
      return CupertinoPageScaffold(
        child: CupertinoAlertDialog(
          title: Text("No disponible"),
          content: Text(loadError!),
          actions: [
            CupertinoDialogAction(
              child: Text("De acuerdo"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else if (!widget.form.isLoaded) {
      return CupertinoPageScaffold(
        child: CupertinoAlertDialog(
          title: Text("Cargando..."),
          content: Text("Esto está demorando demasiado..."),
          actions: [
            CupertinoDialogAction(
              child: Text("Salir"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    // Aplica restricciones en cada build
    widget.form.handleFieldRestrictions();

    return Form(
      canPop: false,
      child: CupertinoTabScaffold(
        backgroundColor: Settings.instance.colors.background,
        tabBar: CupertinoTabBar(
          inactiveColor: Settings.instance.colors.primaryContrastDark,
          activeColor: Settings.instance.colors.primaryContrast,
          backgroundColor: Settings.instance.colors.primary,
          items: [
            for (final section in widget.form.sectionKeys)
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsetsGeometry.only(top: 6),
                  child: _sectionBarItemIcon(section),
                ),
                activeIcon: Padding(
                  padding: EdgeInsetsGeometry.only(top: 6),
                  child: _sectionBarItemIcon(section, active: true),
                ),
                label: section,
              ),
          ],
        ),
        tabBuilder: (context, index) {
          final currentSection = widget.form.sectionKeys[index];
          final fields = widget.form.sections[currentSection] as List<dynamic>;
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              backgroundColor: Settings.instance.colors.primary,
              automaticBackgroundVisibility: false,
              padding: EdgeInsetsDirectional.only(bottom: 6),
              middle: Column(
                children: [
                  Text(
                    "FRAP",
                    style: TextStyle(
                      fontSize: 20,
                      color: Settings.instance.colors.textOverPrimary,
                    ),
                  ),
                  Text(
                    widget.form.id.substring(14),
                    style: TextStyle(
                      fontSize: 10,
                      color: Settings.instance.colors.textOverPrimary,
                    ),
                  ),
                ],
              ),
              leading: CupertinoButton(
                padding: EdgeInsets.only(bottom: 6),
                alignment: AlignmentGeometry.centerRight,
                onPressed: widget.form.canSaveForm ? _saveForm : _exitForm,
                child: Icon(
                  widget.form.canSaveForm
                      ? CupertinoIcons.back
                      : CupertinoIcons.clear,
                  size: 28,
                  color: Settings.instance.colors.primaryContrast,
                ),
              ),
              trailing: widget.form.canFinishForm
                  ? CupertinoButton(
                      padding: EdgeInsets.only(bottom: 6),
                      alignment: AlignmentGeometry.centerLeft,
                      onPressed: _finishForm,
                      child: Icon(
                        CupertinoIcons.cloud_upload,
                        size: 28,
                        color: Settings.instance.colors.primaryContrast,
                      ),
                    )
                  : (!widget.form.canEditForm && Settings.instance.role >= 1
                        ? CupertinoButton(
                            padding: EdgeInsets.only(bottom: 6),
                            alignment: AlignmentGeometry.centerLeft,
                            onPressed: () => {
                              setState(() {
                                widget.form.editOverride = true;
                              }),
                            },
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: 28,
                              color: Settings.instance.colors.primaryContrast,
                            ),
                          )
                        : null),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: fields.length,
                  itemBuilder: (context, idx) {
                    final field = fields[idx];
                    return buildField(field);
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
