import 'package:bomberos/models/settings.dart' show Settings;
import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class SelectField extends InputField {
  const SelectField({
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
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  if (!widget.canEditForm) return;
                  int selected = options.indexOf(widget.value);
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
                                scrollController: FixedExtentScrollController(
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
                              child: Text(
                                'Confirmar',
                                style: TextStyle(
                                  color:
                                      Settings.instance.colors.primaryContrast,
                                ),
                              ),
                              onPressed: () async {
                                widget.setFormState(() {
                                  widget.formSet(
                                    widget.field['name'],
                                    options[pickedIndex],
                                  );
                                });
                                if (!mounted) return;
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
                        widget.value == ''
                            ? 'Sin seleccionar'
                            : widget.value.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(CupertinoIcons.chevron_down, size: 20),
                    ],
                  ),
                ),
              ),
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
