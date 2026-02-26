import 'package:bomberos/models/settings.dart' show Settings;
import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Card;

class TupleField extends InputField {
  const TupleField({
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
  @override
  Widget build(BuildContext context) {
    final tupleFields = widget.field['tuple'] as List<dynamic>? ?? [];
    final tupleList = widget.value.isEmpty
        ? List.from(<dynamic>[])
        : widget.value as List<dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label != '' ? label : 'Lista',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        ...List.generate(
          tupleList.length,
          (i) => Card(
            color: CupertinoColors.white,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  ...tupleFields.map((subfield) {
                    final subValue = tupleList[i][subfield['name']] ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subfield['label'] ?? subfield['name'],
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (subfield['type'] == 'input' &&
                            subfield['inputType'] == 'time')
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  subValue == ''
                                      ? 'Sin seleccionar'
                                      : subValue.toString(),
                                ),
                              ),
                              CupertinoButton(
                                child: Icon(CupertinoIcons.clock_solid),
                                onPressed: () async {
                                  Duration initialDuration = subValue != ''
                                      ? Duration(
                                          hours:
                                              int.tryParse(
                                                subValue.split(":")[0],
                                              ) ??
                                              0,
                                          minutes:
                                              int.tryParse(
                                                subValue.split(":")[1],
                                              ) ??
                                              0,
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
                                                mode:
                                                    CupertinoTimerPickerMode.hm,
                                                initialTimerDuration:
                                                    initialDuration,
                                                onTimerDurationChanged:
                                                    (duration) {
                                                      pickedDuration = duration;
                                                    },
                                              ),
                                            ),
                                            CupertinoButton(
                                              child: Text(
                                                'Confirmar',
                                                style: TextStyle(
                                                  color: Settings
                                                      .instance
                                                      .colors
                                                      .primaryContrast,
                                                ),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  tupleList[i][subfield['name']] =
                                                      "${pickedDuration.inHours.toString().padLeft(2, '0')}:${(pickedDuration.inMinutes % 60).toString().padLeft(2, '0')}";
                                                  widget.formSet(
                                                    widget.field['name'],
                                                    tupleList,
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
                            ],
                          )
                        else
                          CupertinoTextField(
                            placeholder: subfield['label'] ?? subfield['name'],
                            controller: TextEditingController(text: subValue)
                              ..selection = TextSelection.collapsed(
                                offset: subValue.length,
                              ),
                            onChanged: (val) {
                              setState(() {
                                tupleList[i][subfield['name']] = val;
                                widget.formSet(widget.field['name'], tupleList);
                              });
                            },
                          ),
                      ],
                    );
                  }),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.delete, size: 20),
                    onPressed: () {
                      setState(() {
                        tupleList.removeAt(i);
                        widget.formSet(widget.field['name'], tupleList);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        CupertinoButton(
          child: Text('Agregar'),
          onPressed: () {
            setState(() {
              tupleList.add({
                for (var sub in tupleFields) sub['name'].toString(): '',
              });
              widget.formSet(widget.field['name'], tupleList);
            });
          },
        ),
      ],
    );
  }
}
