import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class RadioMultipleField extends InputField {
  const RadioMultipleField({
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
        ...options.map(
          (opt) => GestureDetector(
            onTap: () {
              setState(() {
                widget.formSet(widget.field['name'], opt);
              });
            },
            child: Row(
              children: [
                Icon(
                  widget.value == opt
                      ? CupertinoIcons.circle_filled
                      : CupertinoIcons.circle,
                  color: widget.value == opt
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.inactiveGray,
                ),
                SizedBox(width: 8),
                Text(opt),
              ],
            ),
          ),
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
    );
  }
}
