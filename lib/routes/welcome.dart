import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: Header(),
      backgroundColor: Settings().colors.primary,
      child: CupertinoActivityIndicator(),
    );
  }
}