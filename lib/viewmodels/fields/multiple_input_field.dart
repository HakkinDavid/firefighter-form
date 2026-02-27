import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class MultipleInputField extends InputField {
  const MultipleInputField({
    super.key,
    required super.field,
    required super.value,
    required super.formSet,
    required super.setFormState,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _MultipleInputFieldState();
}

class _MultipleInputFieldState extends InputFieldState {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        ...List.generate(
          (widget.value as List).length,
          (i) => Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  readOnly: !widget.canEditForm,
                  placeholder: "$label ${i + 1}",
                  controller: TextEditingController(text: widget.value[i] ?? '')
                    ..selection = TextSelection.collapsed(
                      offset: widget.value[i].length,
                    ),
                  onChanged: (val) {
                    if (!widget.canEditForm) return;
                    widget.setFormState(() {
                      widget.value[i] = val;
                      widget.formSet(widget.field['name'], widget.value);
                    });
                  },
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.delete, size: 20),
                onPressed: () {
                  if (!widget.canEditForm) return;
                  widget.setFormState(() {
                    widget.value.removeAt(i);
                    widget.formSet(widget.field['name'], widget.value);
                  });
                },
              ),
            ],
          ),
        ),
        CupertinoButton(
          child: Text('Agregar'),
          onPressed: () {
            if (!widget.canEditForm) return;
            widget.setFormState(() {
              widget.value.add('');
              widget.formSet(widget.field['name'], widget.value);
            });
          },
        ),
      ],
    );
  }
}
