import 'package:bomberos/models/form.dart';
import 'package:bomberos/viewmodels/fields/checkbox_multiple_field.dart';
import 'package:bomberos/viewmodels/fields/date_input_field.dart';
import 'package:bomberos/viewmodels/fields/drawing_board_field.dart';
import 'package:bomberos/viewmodels/fields/multiple_input_field.dart';
import 'package:bomberos/viewmodels/fields/number_input_field.dart';
import 'package:bomberos/viewmodels/fields/options_input_field.dart';
import 'package:bomberos/viewmodels/fields/predictive_text_select_field.dart';
import 'package:bomberos/viewmodels/fields/radio_multiple_field.dart';
import 'package:bomberos/viewmodels/fields/select_field.dart';
import 'package:bomberos/viewmodels/fields/text_display_field.dart';
import 'package:bomberos/viewmodels/fields/text_input_field.dart';
import 'package:bomberos/viewmodels/fields/textarea_field.dart';
import 'package:bomberos/viewmodels/fields/time_input_field.dart';
import 'package:bomberos/viewmodels/fields/tuple_field.dart';
import 'package:flutter/cupertino.dart';

class DynamicFieldRenderer extends StatelessWidget {
  final Map<String, dynamic> field;
  final ServiceForm form;
  final StateSetter setFormState;
  final List<dynamic>? Function(List<dynamic>?) formatOptions;

  const DynamicFieldRenderer({
    super.key,
    required this.field,
    required this.form,
    required this.setFormState,
    required this.formatOptions,
  });

  Map<String, dynamic> _resolveFieldOptions(Map<String, dynamic> originalField) {
    final resolvedField = Map<String, dynamic>.from(originalField);

    // 1. Resolve top-level field optionsFrom
    if (resolvedField.containsKey('optionsFrom')) {
      final catalogKey = resolvedField['optionsFrom'];
      final catalog = form.template['options']?[catalogKey];
      if (catalog is List) {
        resolvedField['options'] = catalog
            .map((item) => (item is Map) ? (item['name']?.toString() ?? '') : item.toString())
            .toList();
      }
    }

    // 2. Resolve nested tuple subfield optionsFrom
    if (resolvedField['type'] == 'tuple' && resolvedField['tuple'] is List) {
      final originalSubfields = resolvedField['tuple'] as List;
      final resolvedSubfields = [];
      for (final sub in originalSubfields) {
        if (sub is Map) {
          final resolvedSub = Map<String, dynamic>.from(sub);
          if (resolvedSub.containsKey('optionsFrom')) {
            final catalogKey = resolvedSub['optionsFrom'];
            final catalog = form.template['options']?[catalogKey];
            if (catalog is List) {
              resolvedSub['options'] = catalog
                  .map((item) => (item is Map) ? (item['name']?.toString() ?? '') : item.toString())
                  .toList();
            }
          }
          resolvedSubfields.add(resolvedSub);
        } else {
          resolvedSubfields.add(sub);
        }
      }
      resolvedField['tuple'] = resolvedSubfields;
    }

    return resolvedField;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> resolvedField = _resolveFieldOptions(field);
    final String type = resolvedField['type'];
    final Set<String> errors = form.errors[resolvedField['name']] ?? <String>{};

    if (!form.shouldDisplay(resolvedField)) return SizedBox.shrink();

    Widget fieldWidget;

    if (type == 'input') {
      if (resolvedField['inputType'] == 'date') {
        fieldWidget = DateInputField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (resolvedField['inputType'] == 'time') {
        fieldWidget = TimeInputField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (resolvedField['multiple'] == true) {
        fieldWidget = MultipleInputField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (resolvedField['inputType'] == 'number') {
        fieldWidget = NumberInputField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (resolvedField['options'] != null &&
          resolvedField['options'] is List<dynamic> &&
          resolvedField['options'].isNotEmpty) {
        fieldWidget = OptionsInputField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else {
        fieldWidget = TextInputField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      }
    } else if (type == 'select') {
      if (resolvedField['inputType'] == 'text') {
        fieldWidget = PredictiveTextSelectField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else {
        fieldWidget = SelectField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      }
    } else if (type == 'textarea') {
      fieldWidget = TextAreaField(
        field: resolvedField,
        value: form.content[resolvedField['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'multiple') {
      if (resolvedField['inputType'] == 'checkbox') {
        fieldWidget = CheckboxMultipleField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (resolvedField['inputType'] == 'radio') {
        fieldWidget = RadioMultipleField(
          field: resolvedField,
          value: form.content[resolvedField['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else {
        fieldWidget = SizedBox.shrink();
      }
    } else if (type == 'drawingboard') {
      fieldWidget = DrawingBoardField(
        field: resolvedField,
        value: form.content[resolvedField['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'tuple') {
      fieldWidget = TupleField(
        field: resolvedField,
        value: form.content[resolvedField['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'text') {
      fieldWidget = TextDisplayField(
        field: resolvedField,
        value: form.content[resolvedField['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
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
}
