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
    required super.setFormState,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _TupleFieldState();
}

class _TupleFieldState extends InputFieldState {
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
                        if (subfield['type'] == 'select')
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    if (!widget.canEditForm) return;
                                    await showCupertinoModalPopup(
                                      context: context,
                                      builder: (_) {
                                        String searchText = '';
                                        return StatefulBuilder(
                                          builder: (BuildContext context, StateSetter popupState) {
                                            final searchLower = searchText.trim().replaceAll(' ', '').toLowerCase();
                                            final rawOptions = subfield['options'] as List<dynamic>? ?? [];
                                            final formattedOptions = widget.formatOptions(rawOptions);
                                            final filteredOptions = formattedOptions.where((opt) {
                                              final optText = opt.toString().replaceAll(' ', '').toLowerCase();
                                              return searchLower.isNotEmpty && optText.contains(searchLower);
                                            }).toList();

                                            return SafeArea(
                                              child: Container(
                                                color: Settings.instance.colors.primary,
                                                height: 400,
                                                padding: EdgeInsets.all(16),
                                                child: Column(
                                                  children: [
                                                    CupertinoTextField(
                                                      style: TextStyle(
                                                        color: Settings.instance.colors.primary,
                                                      ),
                                                      placeholderStyle: TextStyle(
                                                        color: Settings.instance.colors.disabled,
                                                      ),
                                                      placeholder: subfield['label'] ?? subfield['name'],
                                                      decoration: BoxDecoration(
                                                        color: Settings.instance.colors.background,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: Settings.instance.colors.disabled,
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets.all(12),
                                                      autofocus: true,
                                                      autocorrect: false,
                                                      onChanged: (val) {
                                                        popupState(() {
                                                          searchText = val;
                                                        });
                                                      },
                                                    ),
                                                    SizedBox(height: 12),
                                                    Expanded(
                                                      child: ListView(
                                                        children: filteredOptions.map((opt) {
                                                          return CupertinoButton(
                                                            onPressed: () {
                                                              widget.setFormState(() {
                                                                tupleList[i][subfield['name']] = opt.toString();
                                                                widget.formSet(
                                                                  widget.field['name'],
                                                                  tupleList,
                                                                );
                                                              });
                                                              Navigator.of(context).pop();
                                                            },
                                                            alignment: Alignment.centerLeft,
                                                            padding: EdgeInsets.symmetric(vertical: 12),
                                                            child: Text(
                                                              opt.toString(),
                                                              style: TextStyle(
                                                                color: Settings.instance.colors.primaryContrast,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: CupertinoColors.separator),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            subValue == ''
                                                ? 'Sin seleccionar'
                                                : subValue.toString(),
                                            style: TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(CupertinoIcons.chevron_down, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (subValue != '' && widget.canEditForm)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Icon(CupertinoIcons.clear, size: 20),
                                  onPressed: () {
                                    widget.setFormState(() {
                                      tupleList[i][subfield['name']] = '';
                                      widget.formSet(widget.field['name'], tupleList);
                                    });
                                  },
                                ),
                            ],
                          )
                        else if (subfield['type'] == 'input' &&
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
                                  if (!widget.canEditForm) return;
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
                                                widget.setFormState(() {
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
                            readOnly: !widget.canEditForm,
                            placeholder: subfield['label'] ?? subfield['name'],
                            controller: TextEditingController(text: subValue)
                              ..selection = TextSelection.collapsed(
                                offset: subValue.length,
                              ),
                            onChanged: (val) {
                              if (!widget.canEditForm) return;
                              widget.setFormState(() {
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
                      if (!widget.canEditForm) return;
                      widget.setFormState(() {
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
            if (!widget.canEditForm) return;
            widget.setFormState(() {
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
