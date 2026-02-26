import 'package:bomberos/models/settings.dart' show Settings;
import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class DateInputField extends InputField {
  const DateInputField({
    super.key,
    required super.field,
    required super.value,
    required super.formSet,
    required super.setFormState,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends InputFieldState {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.value == ''
                    ? 'Sin seleccionar'
                    : widget.value.toString(),
              ),
            ),
            CupertinoButton(
              child: Text(widget.value == '' ? 'Seleccionar fecha' : 'Cambiar'),
              onPressed: () async {
                if (!widget.canEditForm) return;
                DateTime now = DateTime.now();
                DateTime initial = now;
                if (widget.value != '') {
                  initial = DateTime.tryParse(widget.value) ?? now;
                }
                DateTime pickedDate = initial;
                await showCupertinoModalPopup(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Container(
                      color: Settings.instance.colors.primary,
                      height: 300,
                      child: Column(
                        children: [
                          Expanded(
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.date,
                              initialDateTime: initial,
                              minimumYear: 1900,
                              maximumYear: now.year,
                              maximumDate: now,
                              onDateTimeChanged: (picked) {
                                pickedDate = picked;
                              },
                            ),
                          ),
                          CupertinoButton(
                            child: Text(
                              'Confirmar',
                              style: TextStyle(
                                color: Settings.instance.colors.primaryContrast,
                              ),
                            ),
                            onPressed: () {
                              widget.setFormState(() {
                                widget.formSet(
                                  widget.field['name'],
                                  pickedDate.toIso8601String().split('T')[0],
                                );
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (widget.value != '' && widget.canEditForm)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.clear, size: 20),
                onPressed: () {
                  widget.setFormState(() {
                    widget.formSet(widget.field['name'], '');
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
