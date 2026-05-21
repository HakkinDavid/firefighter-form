import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class CheckboxMultipleField extends InputField {
  const CheckboxMultipleField({
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
  List<dynamic> get options => widget.formatOptions(widget.field['options'] as List<dynamic>?) ?? const [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        ...options.map(
          (opt) => Row(
            children: [
              CupertinoSwitch(
                value: widget.value.contains(opt),
                onChanged: (val) {
                  if (!widget.canEditForm) return;
                  widget.setFormState(() {
                    if (val) {
                      widget.value.add(opt);
                    } else {
                      widget.value.remove(opt);
                    }
                    widget.formSet(widget.field['name'], widget.value);
                  });
                },
              ),
              SizedBox(width: 8),
              Text(opt),
            ],
          ),
        ),
      ],
    );
  }
}
