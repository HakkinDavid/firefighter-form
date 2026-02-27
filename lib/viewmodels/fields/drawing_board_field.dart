import 'package:bomberos/viewmodels/canvas.dart';
import 'package:bomberos/viewmodels/fields/input_field.dart';
import 'package:flutter/cupertino.dart';

class DrawingBoardField extends InputField {
  const DrawingBoardField({
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
  @override
  Widget build(BuildContext context) {
    final myCanvasController = ServiceCanvasController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label != ''
              ? label
              : (widget.field['secondaryLabel'] ?? 'Firma / Dibujo'),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        if (widget.field['text'] != null)
          Text(
            widget.field['text'] != '' ? widget.field['text'] : "",
            style: TextStyle(fontWeight: FontWeight.w200),
          ),
        SizedBox(height: 8),
        ServiceCanvas(
          readOnly: !widget.canEditForm,
          controller: myCanvasController,
          defaultData: widget.value,
          backgroundData: widget.field['background'],
        ),
        if (widget.canEditForm)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.clear, size: 20),
                onPressed: () {
                  myCanvasController.clear();
                  widget.setFormState(() {
                    widget.formSet(widget.field['name'], null);
                  });
                },
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.check_mark, size: 20),
                onPressed: () async {
                  final data = await myCanvasController.exportAsSvg();
                  widget.setFormState(() {
                    widget.formSet(widget.field['name'], data);
                  });
                },
              ),
            ],
          ),
      ],
    );
  }
}
