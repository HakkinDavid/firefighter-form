import 'package:bomberos/models/settings.dart' show Settings;
import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class PredictiveTextSelectField extends InputField {
  const PredictiveTextSelectField({
    super.key,
    required super.field,
    required super.value,
    required super.formSet,
    required super.setFormState,
    required super.canEditForm,
    required super.formatOptions,
  });

  @override
  State<InputField> createState() => _PredictiveTextSelectFieldState();
}

class _PredictiveTextSelectFieldState extends InputFieldState {
  final _searchController = TextEditingController();
  late final List<dynamic> options;

  String _normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[ñ]'), 'n');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  @override
  void initState() {
    super.initState();
    options = widget.formatOptions(widget.field['options'] as List<dynamic>?) ?? const [];
  }

  bool matchesInput(dynamic option) {
    final searchText = _normalize(_searchController.text);
    if (searchText.isEmpty) return true;
    final optionText = _normalize(option.toString());
    return optionText.contains(searchText);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  await showCupertinoModalPopup(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Container(
                        color: Settings.instance.colors.primary,
                        height: 400,
                        child: Column(
                          children: [
                            CupertinoTextField(
                              style: TextStyle(
                              color: Settings.instance.colors.primary,
                              ),
                              placeholderStyle: TextStyle(
                                color: Settings.instance.colors.disabled,
                              ),
                              controller: _searchController,
                              placeholder: label,
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
                              onChanged: (value) => setState(() {}),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  ...options.where(matchesInput).map((opt) {
                                    return CupertinoButton(
                                      onPressed: () async {
                                        widget.setFormState(() {
                                          widget.formSet(
                                            widget.field['name'],
                                            opt,
                                          );
                                        });
                                        if (!mounted) return;
                                        Navigator.of(context).pop();
                                      },
                                      padding: EdgeInsets.zero,
                                      child: Text(
                                        opt.toString(),
                                        style: TextStyle(
                                          color: Settings.instance.colors.primaryContrast,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
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
                    widget.formSet(widget.field['name'], null);
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
