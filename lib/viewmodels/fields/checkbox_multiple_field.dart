import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class CheckboxMultipleField extends InputField {
  const CheckboxMultipleField({
    super.key,
    required super.field,
    required super.value,
    required super.formSet,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends InputFieldState {
  late final List<dynamic> options;

  @override
  void initState() {
    super.initState();

    options = widget.formatOptions(widget.field['options'] as List<dynamic>?);
  }

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
                  setState(() {
                    if (val) {
                      widget.value.add(opt);
                    } else {
                      widget.value.remove(opt);
                    }
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
