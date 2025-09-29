import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' show Colors, Card;
import 'package:bomberos/models/settings.dart';

class DynamicFormPage extends StatefulWidget {
  const DynamicFormPage({super.key});

  @override
  State<DynamicFormPage> createState() => _DynamicFormPageState();
}

class _DynamicFormPageState extends State<DynamicFormPage> {
  Map<String, dynamic>? formJson;
  Map<String, dynamic> formData = {};
  List<String> sectionKeys = [];
  Map<String, List<String>> fieldErrors = {};

  @override
  void initState() {
    super.initState();
    loadFormJson();
  }

  Future<void> loadFormJson() async {
    final jsonStr = await rootBundle.loadString('assets/frap.json');
    final loadedJson = json.decode(jsonStr);
    final sections = loadedJson['fields'] as Map<String, dynamic>;
    setState(() {
      formJson = loadedJson;
      sectionKeys = sections.keys.toList();
      formData = {};
      for (var section in sectionKeys) {
        for (var field in sections[section]) {
          formData[field['name']] = getDefaultValue(field);
        }
      }
    });
  }

  dynamic getDefaultValue(Map<String, dynamic> field) {
    if (field['type'] == 'multiple' && field['inputType'] == 'checkbox') {
      return <String>[];
    }
    if (field['type'] == 'multiple' && field['inputType'] == 'radio') {
      return '';
    }
    if (field['type'] == 'select') {
      return '';
    }
    if (field['type'] == 'textarea') {
      return '';
    }
    if (field['type'] == 'drawingboard') {
      return null; // Canvas data
    }
    if (field['type'] == 'tuple') {
      return <Map<String, dynamic>>[];
    }
    if (field['type'] == 'input') {
      if (field['multiple'] == true) return <String>[];
      if (field['inputType'] == 'number') return '';
      if (field['inputType'] == 'date') return '';
      if (field['inputType'] == 'time') return '';
      return '';
    }
    return '';
  }

  void _saveForm() {
    print("Implementar guardado...");
    Navigator.pop(context);
  }

  // Restriction handler (minimal Dart port)
  Map<String, List<String>> handleFieldRestrictions(Map<String, dynamic> data, Map<String, dynamic>? restrictions) {
    if (restrictions == null) return {};
    final fieldErrors = <String, List<String>>{};
    restrictions.forEach((key, items) {
      for (final field in items) {
        final fieldName = field['name'];
        final value = data[fieldName];
        bool passed = true;
        switch (key) {
          case 'notEmpty':
            passed = value != null && value.toString().trim().isNotEmpty;
            break;
          case 'lessThan':
            passed = value != null && value != '' && double.tryParse(value.toString()) != null
              ? double.parse(value.toString()) < field['value']
              : true;
            break;
          case 'greaterThan':
            passed = value != null && value != '' && double.tryParse(value.toString()) != null
              ? double.parse(value.toString()) > field['value']
              : true;
            break;
          // ...add more cases as needed...
          default:
            passed = true;
        }
        if (!passed) {
          final msg = field['message'] ?? 'Campo inválido';
          fieldErrors[fieldName] = (fieldErrors[fieldName] ?? [])..add(msg);
        }
      }
    });
    return fieldErrors;
  }

  Widget buildField(Map<String, dynamic> field) {
    final type = field['type'];
    final label = field['label'] ?? '';
    final value = formData[field['name']];
    final options = field['options'] as List<dynamic>?;
    final errors = fieldErrors[field['name']] ?? [];
    final isRequired = errors.isNotEmpty;

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
                Expanded(child: Text(value == '' ? 'Sin seleccionar' : value.toString())),
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
                                    formData[field['name']] = pickedDate.toIso8601String().split('T')[0];
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
                        formData[field['name']] = '';
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
                  child: Text(value == '' ? 'Sin seleccionar' : value.toString()),
                ),
                CupertinoButton(
                  child: Icon(CupertinoIcons.clock_solid),
                  onPressed: () async {
                    Duration initialDuration = value != ''
                      ? Duration(
                          hours: int.tryParse(value.split(":")[0]) ?? 0,
                          minutes: int.tryParse(value.split(":")[1]) ?? 0)
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
                                    formData[field['name']] =
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
                if (!isRequired && value != '')
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        formData[field['name']] = '';
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
            ...List.generate((value as List).length, (i) => Row(
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
            )),
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
                  formData[field['name']] = val;
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
                                    scrollController: FixedExtentScrollController(initialItem: selected),
                                    onSelectedItemChanged: (i) {
                                      pickedIndex = i;
                                    },
                                    children: options.map((o) => Text(o.toString())).toList(),
                                  ),
                                ),
                                CupertinoButton(
                                  child: Text('Confirmar'),
                                  onPressed: () {
                                    setState(() {
                                      formData[field['name']] = options[pickedIndex];
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
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(value == '' ? 'Sin seleccionar' : value.toString(), style: TextStyle(fontSize: 16)),
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
                        formData[field['name']] = '';
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
                  formData[field['name']] = val;
                });
              },
            ),
          ],
        );
      }
    }
    else if (type == 'select') {
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
                                  scrollController: FixedExtentScrollController(initialItem: selected),
                                  onSelectedItemChanged: (i) {
                                    setState(() {
                                      formData[field['name']] = options[i];
                                    });
                                  },
                                  children: options!.map((o) => Text(o.toString())).toList(),
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
                      border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(value == '' ? 'Sin seleccionar' : value.toString(), style: TextStyle(fontSize: 16)),
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
                      formData[field['name']] = '';
                    });
                  },
                ),
            ],
          ),
        ],
      );
    }
    else if (type == 'textarea') {
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
                formData[field['name']] = val;
              });
            },
          ),
        ],
      );
    }
    else if (type == 'multiple') {
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
                    formData[field['name']] = opt;
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
                    formData[field['name']] = '';
                  });
                },
              ),
          ],
        );
      } else {
        fieldWidget = SizedBox.shrink();
      }
    }
    else if (type == 'drawingboard') {
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label != '' ? label : (field['secondaryLabel'] ?? 'Firma / Dibujo'), style: TextStyle(fontWeight: FontWeight.w500)),
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
                  formData[field['name']] = null;
                });
              },
            ),
        ],
      );
    }
    else if (type == 'tuple') {
      final tupleFields = field['tuple'] as List<dynamic>? ?? [];
      final tupleList = value as List<dynamic>;
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label != '' ? label : 'Lista', style: TextStyle(fontWeight: FontWeight.w500)),
          ...List.generate(tupleList.length, (i) => Card(
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
                        Text(subfield['label'] ?? subfield['name'], style: TextStyle(fontWeight: FontWeight.w500)),
                        if (subfield['type'] == 'input' && subfield['inputType'] == 'time')
                          Row(
                            children: [
                              Expanded(
                                child: Text(subValue == '' ? 'Sin seleccionar' : subValue.toString()),
                              ),
                              CupertinoButton(
                                child: Icon(CupertinoIcons.clock_solid),
                                onPressed: () async {
                                  Duration initialDuration = subValue != ''
                                    ? Duration(
                                        hours: int.tryParse(subValue.split(":")[0]) ?? 0,
                                        minutes: int.tryParse(subValue.split(":")[1]) ?? 0)
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
                            placeholder: subfield['label'] ?? subfield['name'],
                            controller: TextEditingController(text: subValue)
                              ..selection = TextSelection.collapsed(offset: subValue.length),
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
          )),
          CupertinoButton(
            child: Text('Agregar'),
            onPressed: () {
              setState(() {
                tupleList.add({for (var sub in tupleFields) sub['name']: ''});
              });
            },
          ),
        ],
      );
    }
    else if (type == 'text') {
      fieldWidget = Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          field['text'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }
    else {
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
              children: errors.map((e) => Text(
                e,
                style: TextStyle(color: CupertinoColors.systemRed, fontSize: 12),
              )).toList(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (formJson == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Cargando...'),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    final formname = formJson!['formname'] ?? 'Formulario';
    final sections = formJson!['fields'] as Map<String, dynamic>;

    // Aplica restricciones en cada build
    fieldErrors = handleFieldRestrictions(formData, formJson!['restrictions']);

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          for (final section in sectionKeys)
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_list),
              label: section,
            ),
        ],
      ),
      tabBuilder: (context, index) {
        final currentSection = sectionKeys[index];
        final fields = sections[currentSection] as List<dynamic>;
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(formname),
            trailing: CupertinoButton(onPressed: _saveForm, child: Icon(CupertinoIcons.check_mark_circled_solid)),
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