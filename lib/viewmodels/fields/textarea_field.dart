import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class TextAreaField extends InputField {
  const TextAreaField({
    super.key,
    required super.field,
    required super.value,
    required super.formSet,
    required super.setFormState,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends InputFieldState {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        CupertinoTextField(
          placeholder: label,
          controller: TextEditingController(text: widget.value)
            ..selection = TextSelection.collapsed(offset: widget.value.length),
          maxLines: widget.field['rows'] ?? 3,
          onChanged: (val) {
            widget.setFormState(() {
              widget.formSet(widget.field['name'], val);
            });
          },
        ),
      ],
    );
  }
}
