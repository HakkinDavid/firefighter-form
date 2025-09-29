import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  //final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void _createForm() {
    Navigator.pushNamed(context, '/form');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      backgroundColor: Settings.instance.colors.primaryContrast,
      child: SafeArea(
        child: Column(
          children: [
            Header(
              username: Settings.instance.self?.fullName,
              adminUsername: Settings.instance.watcher?.fullName,
            ),
            Expanded(
              child: Container(
                color: Settings.instance.colors.background,
                child: Center(
                  child: CupertinoButton(
                    onPressed: _createForm,
                    color: Settings.instance.colors.primaryContrast,
                    borderRadius: BorderRadius.circular(48),
                    child: Icon(CupertinoIcons.add, color: Settings.instance.colors.primary, size: 36,),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
