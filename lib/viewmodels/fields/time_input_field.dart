import 'package:bomberos/models/settings.dart' show Settings;
import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class TimeInputField extends InputField {
  const TimeInputField({
    super.key,
    required super.field,
    required super.value,
    required super.formSet,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends InputFieldState {
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
              child: Icon(CupertinoIcons.clock_solid),
              onPressed: () async {
                Duration initialDuration = widget.value != ''
                    ? Duration(
                        hours: int.tryParse(widget.value.split(":")[0]) ?? 0,
                        minutes: int.tryParse(widget.value.split(":")[1]) ?? 0,
                      )
                    : Duration();
                Duration pickedDuration = initialDuration;
                await showCupertinoModalPopup(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Container(
                      color: Settings.instance.colors.primary,
                      height: 300,
                      child: Column(
                        children: [
                          Expanded(
                            child: CupertinoTimerPicker(
                              mode: CupertinoTimerPickerMode.hm,
                              initialTimerDuration: initialDuration,
                              onTimerDurationChanged: (duration) {
                                pickedDuration = duration;
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
                              setState(() {
                                widget.formSet(
                                  widget.field['name'],
                                  "${pickedDuration.inHours.toString().padLeft(2, '0')}:${(pickedDuration.inMinutes % 60).toString().padLeft(2, '0')}",
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
                  setState(() {
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
