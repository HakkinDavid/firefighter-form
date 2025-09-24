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
      navigationBar: null,
      backgroundColor: Settings().colors.primary,
      child: SafeArea(
        child: Column(
          children: [
            Header(username: "Blaner", adminUsername: "Villegas"),
            Expanded(
              child: Center(
                child: CupertinoButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, "/home"),
                  color: Settings().colors.primaryContrast,
                  child: Text("Entrar"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
