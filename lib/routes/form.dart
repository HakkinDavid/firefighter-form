import 'package:bomberos/models/form.dart';
import 'package:bomberos/viewmodels/canvas.dart';
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
  IconData _sectionIcon(String section, {bool active = false}) {
    switch (section) {
      case 'Servicio':
        return active
            ? CupertinoIcons.plus_square_fill
            : CupertinoIcons.plus_square;
      case 'Paciente':
        return active ? CupertinoIcons.person_fill : CupertinoIcons.person;
      case 'Primaria':
        return active
            ? CupertinoIcons.bag_fill_badge_plus
            : CupertinoIcons.bag_badge_plus;
      case 'Secundaria':
        return active
            ? CupertinoIcons.bag_fill_badge_minus
            : CupertinoIcons.bag_badge_minus;
      case 'Tratamiento':
        return active ? CupertinoIcons.bandage_fill : CupertinoIcons.bandage;
      case 'Resultados':
        return active
            ? CupertinoIcons.doc_chart_fill
            : CupertinoIcons.doc_chart;
      default:
        return active
            ? CupertinoIcons.square_list_fill
            : CupertinoIcons.square_list;
    }
  }

  String? loadError;

  bool _sectionHasErrors(String sectionKey) {
    final sectionFields = widget.form.sections[sectionKey] as List<dynamic>;
    for (final field in sectionFields) {
      final name = field['name'];
      if (name != null &&
          widget.form.errors.containsKey(name) &&
          widget.form.errors[name]!.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Widget _sectionBarItemIcon(String section, {bool active = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(_sectionIcon(section, active: active)),
        if (_sectionHasErrors(section))
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Settings.instance.colors.attentionBadge,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  void _exitForm() {
    Navigator.pop(context);
  }

  Future<void> _saveForm({bool shouldSetAsFinished = false}) async {
    await widget.form.save(shouldSetAsFinished: shouldSetAsFinished);
    _exitForm();
  }

  Future<void> _finishForm() async {
    await _saveForm(shouldSetAsFinished: true);
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
                    if (value != '' && widget.form.canEditForm) {
                      initial = DateTime.tryParse(value) ?? now;
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
                if (value != '' && widget.form.canEditForm)
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
                if (value != '' && widget.form.canEditForm)
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
                            color: Settings.instance.colors.primary,
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
                if (value != '' && widget.form.canEditForm)
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
                          color: Settings.instance.colors.primary,
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
              if (value != '' && widget.form.canEditForm)
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
            if (value != '' && widget.form.canEditForm)
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
      final myCanvasController = ServiceCanvasController();
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label != '' ? label : (field['secondaryLabel'] ?? 'Firma / Dibujo'),
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          ServiceCanvas(
            readOnly: !widget.form.canEditForm,
            controller: myCanvasController,
            defaultData: value,
            backgroundData: field['background'],
          ),
          if (widget.form.canEditForm)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.clear, size: 20),
                  onPressed: () {
                    myCanvasController.clear();
                    setState(() {
                      widget.form.set(field['name'], null);
                    });
                  },
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(CupertinoIcons.check_mark, size: 20),
                  onPressed: () async {
                    final data = await myCanvasController.exportAsSvg();
                    setState(() {
                      widget.form.set(field['name'], data);
                    });
                  },
                ),
              ],
            ),
        ],
      );
    } else if (type == 'tuple') {
      final tupleFields = field['tuple'] as List<dynamic>? ?? [];
      final tupleList = value.isEmpty
          ? List.from(<Map<String, dynamic>>[])
          : value as List<Map<String, dynamic>>;
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
                                          color:
                                              Settings.instance.colors.primary,
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
        SizedBox(height: 8),
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
        SizedBox(height: 8),
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
      return CupertinoPageScaffold(
        child: CupertinoAlertDialog(
          title: Text("Cargando..."),
          content: Text("Esto está demorando demasiado..."),
          actions: [
            CupertinoDialogAction(
              child: Text("Salir"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    // Aplica restricciones en cada build
    widget.form.handleFieldRestrictions();

    return CupertinoTabScaffold(
      backgroundColor: Settings.instance.colors.background,
      tabBar: CupertinoTabBar(
        inactiveColor: Settings.instance.colors.primary,
        activeColor: Settings.instance.colors.primaryBright,
        backgroundColor: Settings.instance.colors.primaryContrast,
        items: [
          for (final section in widget.form.sectionKeys)
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsetsGeometry.only(top: 6),
                child: _sectionBarItemIcon(section),
              ),
              activeIcon: Padding(
                padding: EdgeInsetsGeometry.only(top: 6),
                child: _sectionBarItemIcon(section, active: true),
              ),
              label: section,
            ),
        ],
      ),
      tabBuilder: (context, index) {
        final currentSection = widget.form.sectionKeys[index];
        final fields = widget.form.sections[currentSection] as List<dynamic>;
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Settings.instance.colors.primary,
            automaticBackgroundVisibility: false,
            padding: EdgeInsetsDirectional.only(bottom: 6),
            middle: Column(
              children: [
                Text(
                  "FRAP",
                  style: TextStyle(
                    fontSize: 20,
                    color: Settings.instance.colors.textOverPrimary,
                  ),
                ),
                Text(
                  widget.form.id.substring(14),
                  style: TextStyle(
                    fontSize: 10,
                    color: Settings.instance.colors.textOverPrimary,
                  ),
                ),
              ],
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.only(bottom: 6),
              alignment: AlignmentGeometry.centerRight,
              onPressed: widget.form.canSaveForm ? _saveForm : _exitForm,
              child: Icon(
                widget.form.canSaveForm
                    ? CupertinoIcons.back
                    : CupertinoIcons.clear,
                size: 28,
                color: Settings.instance.colors.primaryContrast,
              ),
            ),
            trailing: widget.form.canFinishForm
                ? CupertinoButton(
                    padding: EdgeInsets.only(bottom: 6),
                    alignment: AlignmentGeometry.centerLeft,
                    onPressed: _finishForm,
                    child: Icon(
                      CupertinoIcons.cloud_upload,
                      size: 28,
                      color: Settings.instance.colors.primaryContrast,
                    ),
                  )
                : (!widget.form.canEditForm && Settings.instance.role >= 1
                      ? CupertinoButton(
                          padding: EdgeInsets.only(bottom: 6),
                          alignment: AlignmentGeometry.centerLeft,
                          onPressed: () => {
                            setState(() {
                              widget.form.editOverride = true;
                            }),
                          },
                          child: Icon(
                            CupertinoIcons.pencil,
                            size: 28,
                            color: Settings.instance.colors.primaryContrast,
                          ),
                        )
                      : null),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
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
