import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/logging.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';

class Console extends StatefulWidget {
  const Console({super.key});

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      backgroundColor: Settings.instance.colors.primary,
      child: SafeArea(
        child: Column(
          children: [
            Header(
              username: Settings.instance.self?.fullName,
              adminUsername: Settings.instance.watcher?.fullName,
              versionString: ServiceReliabilityEngineer.appVersion,
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                color: Settings.instance.colors.primary,
                child: ListView.builder(
                  itemCount: Logging.logs.length,
                  itemBuilder: (context, idx) {
                    return Text(Logging.logs[idx],style: TextStyle(color: Settings.instance.colors.primaryContrast, fontSize: 8),);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
