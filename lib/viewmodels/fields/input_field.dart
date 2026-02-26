import 'package:flutter/cupertino.dart';

abstract class InputField extends StatefulWidget {
  final Map<String, dynamic> field;
  final dynamic value;
  final Function formSet;
  final Function formatOptions;
  final bool canEditForm;
  const InputField({
    super.key,
    required this.field,
    required this.value,
    required this.formSet,
    required this.formatOptions,
    required this.canEditForm,
  });

  @override
  State<InputField> createState() => InputFieldState();
}

class InputFieldState extends State<InputField> {
  // late final String type;
  late final String label;

  @override
  void initState() {
    super.initState();
    // type = widget.field['type'];
    label = widget.field['label'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
