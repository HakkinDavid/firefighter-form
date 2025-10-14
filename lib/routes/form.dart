import 'package:bomberos/models/form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Card;
import 'package:bomberos/models/settings.dart';

class DynamicFormPage extends StatefulWidget {
  final ServiceForm form;

  const DynamicFormPage({super.key, required this.form});

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends State<DynamicFormPage> {
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  void _exitForm() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _saveForm() async {
    await Settings.instance.enqueueForm(widget.form);
    _exitForm();
  }

  Future<void> _loadForm() async {
    try {
      await widget.form.load();
      setState(() {});
    } catch (exception) {
      setState(() {
        loadError = !exception.toString().contains("Postgrest")
            ? "Formulario no disponible, conéctate a Internet."
            : "Plantilla no disponible.";
      });
    }
  }

  Widget buildField(Map<String, dynamic> field) {
    final String type = field['type'];
    final String label = field['label'] ?? '';
    final dynamic value = widget.form.content[field['name']];
    final List<dynamic>? options = field['options'] as List<dynamic>?;
    final Set<String> errors = widget.form.errors[field['name']] ?? <String>{};
    final bool isRequired = errors.isNotEmpty;

    Widget fieldWidget;

    if (type == 'input') {
      if (field['inputType'] == 'date') {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value == '' ? 'Sin seleccionar' : value.toString(),
                  ),
                ),
                CupertinoButton(
                  child: Text(value == '' ? 'Seleccionar fecha' : 'Cambiar'),
                  onPressed: () async {
                    DateTime now = DateTime.now();
                    DateTime initial = now;
                    if (value != '') {
                      initial = DateTime.tryParse(value) ?? now;
                    }
                    DateTime pickedDate = initial;
                    await showCupertinoModalPopup(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Container(
                          color: Settings.instance.colors.primaryContrast,
                          height: 300,
                          child: Column(
                            children: [
                              Expanded(
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: initial,
                                  minimumYear: 1900,
                                  maximumYear: 2100,
                                  onDateTimeChanged: (picked) {
                                    pickedDate = picked;
                                  },
                                ),
                              ),
                              CupertinoButton(
                                child: Text('Confirmar'),
                                onPressed: () {
                                  setState(() {
                                    widget.form.set(
                                      field['name'],
                                      pickedDate.toIso8601String().split(
                                        'T',
                                      )[0],
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
                if (!isRequired && value != '')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        widget.form.set(field['name'], '');
                      });
                    },
                  ),
              ],
            ),
          ],
        );
      } else if (field['inputType'] == 'time') {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value == '' ? 'Sin seleccionar' : value.toString(),
                  ),
                ),
                CupertinoButton(
                  child: Icon(CupertinoIcons.clock_solid),
                  onPressed: () async {
                    Duration initialDuration = value != ''
                        ? Duration(
                            hours: int.tryParse(value.split(":")[0]) ?? 0,
                            minutes: int.tryParse(value.split(":")[1]) ?? 0,
                          )
                        : Duration();
                    Duration pickedDuration = initialDuration;
                    await showCupertinoModalPopup(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Container(
                          color: Settings.instance.colors.primaryContrast,
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
                                child: Text('Confirmar'),
                                onPressed: () {
                                  setState(() {
                                    widget.form.set(
                                      field['name'],
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
                if (!isRequired && value != '')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        widget.form.set(field['name'], '');
                      });
                    },
                  ),
              ],
            ),
          ],
        );
      } else if (field['multiple'] == true) {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            ...List.generate(
              (value as List).length,
              (i) => Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      placeholder: "$label ${i + 1}",
                      controller: TextEditingController(text: value[i] ?? ''),
                      onChanged: (val) {
                        setState(() {
                          value[i] = val;
                        });
                      },
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.delete, size: 20),
                    onPressed: () {
                      setState(() {
                        value.removeAt(i);
                      });
                    },
                  ),
                ],
              ),
            ),
            CupertinoButton(
              child: Text('Agregar'),
              onPressed: () {
                setState(() {
                  value.add('');
                });
              },
            ),
          ],
        );
      } else if (field['inputType'] == 'number') {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            CupertinoTextField(
              placeholder: label,
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                setState(() {
                  widget.form.set(field['name'], val);
                });
              },
            ),
          ],
        );
      } else if (options != null && options.isNotEmpty) {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      int selected = options.indexOf(value);
                      int pickedIndex = selected;
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Container(
                            color: Settings.instance.colors.primaryContrast,
                            height: 250,
                            child: Column(
                              children: [
                                Expanded(
                                  child: CupertinoPicker(
                                    itemExtent: 32,
                                    scrollController:
                                        FixedExtentScrollController(
                                          initialItem: selected,
                                        ),
                                    onSelectedItemChanged: (i) {
                                      pickedIndex = i;
                                    },
                                    children: options
                                        .map((o) => Text(o.toString()))
                                        .toList(),
                                  ),
                                ),
                                CupertinoButton(
                                  child: Text('Confirmar'),
                                  onPressed: () {
                                    setState(() {
                                      widget.form.set(
                                        field['name'],
                                        options[pickedIndex],
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
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: CupertinoColors.separator),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            value == '' ? 'Sin seleccionar' : value.toString(),
                            style: TextStyle(fontSize: 16),
                          ),
                          Icon(CupertinoIcons.chevron_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isRequired && value != '')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        widget.form.set(field['name'], '');
                      });
                    },
                  ),
              ],
            ),
          ],
        );
      } else {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            CupertinoTextField(
              placeholder: label,
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              onChanged: (val) {
                setState(() {
                  widget.form.set(field['name'], val);
                });
              },
            ),
          ],
        );
      }
    } else if (type == 'select') {
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    int selected = options?.indexOf(value) ?? 0;
                    await showCupertinoModalPopup(
                      context: context,
                      builder: (_) => SafeArea(
                        child: Container(
                          color: Settings.instance.colors.primaryContrast,
                          height: 250,
                          child: Column(
                            children: [
                              Expanded(
                                child: CupertinoPicker(
                                  itemExtent: 32,
                                  scrollController: FixedExtentScrollController(
                                    initialItem: selected,
                                  ),
                                  onSelectedItemChanged: (i) {
                                    setState(() {
                                      widget.form.set(
                                        field['name'],
                                        options[i],
                                      );
                                    });
                                  },
                                  children: options!
                                      .map((o) => Text(o.toString()))
                                      .toList(),
                                ),
                              ),
                              CupertinoButton(
                                child: Text('Confirmar'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
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
                        Text(
                          value == '' ? 'Sin seleccionar' : value.toString(),
                          style: TextStyle(fontSize: 16),
                        ),
                        Icon(CupertinoIcons.chevron_down, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isRequired && value != '')
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      widget.form.set(field['name'], '');
                    });
                  },
                ),
            ],
          ),
        ],
      );
    } else if (type == 'textarea') {
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          CupertinoTextField(
            placeholder: label,
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            maxLines: field['rows'] ?? 3,
            onChanged: (val) {
              setState(() {
                widget.form.set(field['name'], val);
              });
            },
          ),
        ],
      );
    } else if (type == 'multiple') {
      if (field['inputType'] == 'checkbox') {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            ...options!.map(
              (opt) => Row(
                children: [
                  CupertinoSwitch(
                    value: value.contains(opt),
                    onChanged: (val) {
                      setState(() {
                        if (val) {
                          value.add(opt);
                        } else {
                          value.remove(opt);
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
      } else if (field['inputType'] == 'radio') {
        fieldWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            ...options!.map(
              (opt) => GestureDetector(
                onTap: () {
                  setState(() {
                    widget.form.set(field['name'], opt);
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      value == opt
                          ? CupertinoIcons.circle_filled
                          : CupertinoIcons.circle,
                      color: value == opt
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.inactiveGray,
                    ),
                    SizedBox(width: 8),
                    Text(opt),
                  ],
                ),
              ),
            ),
            if (!isRequired && value != '')
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    widget.form.set(field['name'], '');
                  });
                },
              ),
          ],
        );
      } else {
        fieldWidget = SizedBox.shrink();
      }
    } else if (type == 'drawingboard') {
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label != '' ? label : (field['secondaryLabel'] ?? 'Firma / Dibujo'),
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              border: Border.all(color: CupertinoColors.separator),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('Canvas aquí (no implementado)')),
          ),
          if (!isRequired)
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.clear, size: 20),
              onPressed: () {
                setState(() {
                  widget.form.set(field['name'], null);
                });
              },
            ),
        ],
      );
    } else if (type == 'tuple') {
      final tupleFields = field['tuple'] as List<dynamic>? ?? [];
      final tupleList = value as List<Map<String, dynamic>>;
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label != '' ? label : 'Lista',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          ...List.generate(
            tupleList.length,
            (i) => Card(
              color: Colors.white,
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
                                          color: Settings
                                              .instance
                                              .colors
                                              .primaryContrast,
                                          height: 300,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: CupertinoTimerPicker(
                                                  mode: CupertinoTimerPickerMode
                                                      .hm,
                                                  initialTimerDuration:
                                                      initialDuration,
                                                  onTimerDurationChanged:
                                                      (duration) {
                                                        pickedDuration =
                                                            duration;
                                                      },
                                                ),
                                              ),
                                              CupertinoButton(
                                                child: Text('Confirmar'),
                                                onPressed: () {
                                                  setState(() {
                                                    tupleList[i][subfield['name']] =
                                                        "${pickedDuration.inHours.toString().padLeft(2, '0')}:${(pickedDuration.inMinutes % 60).toString().padLeft(2, '0')}";
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
                              placeholder:
                                  subfield['label'] ?? subfield['name'],
                              controller: TextEditingController(text: subValue)
                                ..selection = TextSelection.collapsed(
                                  offset: subValue.length,
                                ),
                              onChanged: (val) {
                                setState(() {
                                  tupleList[i][subfield['name']] = val;
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
              });
            },
          ),
        ],
      );
    } else if (type == 'text') {
      fieldWidget = Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          field['text'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      fieldWidget = SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadError != null) {
      return CupertinoPageScaffold(
        child: CupertinoAlertDialog(
          title: Text("No disponible"),
          content: Text(loadError!),
          actions: [
            CupertinoDialogAction(
              child: Text("De acuerdo"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else if (!widget.form.isLoaded) {
      return CupertinoActivityIndicator();
    }
    // Aplica restricciones en cada build
    widget.form.handleFieldRestrictions();

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          for (final section in widget.form.sectionKeys)
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_list),
              label: section,
            ),
        ],
      ),
      tabBuilder: (context, index) {
        final currentSection = widget.form.sectionKeys[index];
        final fields = widget.form.sections[currentSection] as List<dynamic>;
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(widget.form.name),
            trailing: CupertinoButton(
              onPressed: widget.form.canSaveForm ? _saveForm : _exitForm,
              child: Icon(
                widget.form.canSaveForm
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.clear,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, idx) {
                  final field = fields[idx];
                  return buildField(field);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
