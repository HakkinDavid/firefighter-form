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

  @override
  Widget build(BuildContext context) {
    final String type = field['type'];
    final Set<String> errors = form.errors[field['name']] ?? <String>{};

    if (!form.shouldDisplay(field)) return SizedBox.shrink();

    Widget fieldWidget;

    if (type == 'input') {
      if (field['inputType'] == 'date') {
        fieldWidget = DateInputField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['inputType'] == 'time') {
        fieldWidget = TimeInputField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['multiple'] == true) {
        fieldWidget = MultipleInputField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['inputType'] == 'number') {
        fieldWidget = NumberInputField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['options'] != null &&
          field['options'] is List<dynamic> &&
          field['options'].isNotEmpty) {
        fieldWidget = OptionsInputField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else {
        fieldWidget = TextInputField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      }
    } else if (type == 'select') {
      fieldWidget = SelectField(
        field: field,
        value: form.content[field['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'textarea') {
      fieldWidget = TextAreaField(
        field: field,
        value: form.content[field['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'multiple') {
      if (field['inputType'] == 'checkbox') {
        fieldWidget = CheckboxMultipleField(
          field: field,
          value: form.content[field['name']],
          formSet: form.set,
          setFormState: setFormState,
          canEditForm: form.canEditForm,
          formatOptions: formatOptions,
        );
      } else if (field['inputType'] == 'radio') {
        fieldWidget = RadioMultipleField(
          field: field,
          value: form.content[field['name']],
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
        field: field,
        value: form.content[field['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'tuple') {
      fieldWidget = TupleField(
        field: field,
        value: form.content[field['name']],
        formSet: form.set,
        setFormState: setFormState,
        canEditForm: form.canEditForm,
        formatOptions: formatOptions,
      );
    } else if (type == 'text') {
      fieldWidget = TextDisplayField(
        field: field,
        value: form.content[field['name']],
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
