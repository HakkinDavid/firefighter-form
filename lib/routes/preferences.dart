import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';

class Preferences extends StatefulWidget {
  const Preferences({super.key});

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  @override
  void dispose() {
    super.dispose();
  }

  final List<Map<String, dynamic>> fields = [
    {
      "title": "Refrescar plantillas",
      "type": "button",
      "icon": CupertinoIcons.refresh_circled_solid,
      "action": () => ServiceReliabilityEngineer.instance.enqueueTasks([
        "RefreshTemplates",
      ]),
      "status": () => false,
    },
    {
      "title": "Modo depuración",
      "type": "switch",
      "action": (v) =>
          Settings.instance.allowDebugging = !Settings.instance.allowDebugging,
      "status": () => Settings.instance.allowDebugging,
      "route": () => Settings.instance.allowDebugging ? "/console" : null,
    },
  ];

  Widget buildField(int idx) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fields[idx]['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                if (fields[idx]['type'] == 'button')
                  fields[idx]['status']()
                      ? CupertinoActivityIndicator()
                      : CupertinoButton(
                          onPressed: () {
                            setState(() {
                              fields[idx]['status'] = () => true;
                              fields[idx]['action']();
                              fields[idx]['status'] = () => false;
                            });
                          },
                          padding: EdgeInsets.all(6),
                          minimumSize: Size(0, 0),
                          child: Icon(
                            fields[idx]['icon'],
                            size: 40,
                            color: Settings.instance.colors.primaryContrast,
                          ),
                        ),
                if (fields[idx]['type'] == 'switch')
                  CupertinoSwitch(
                    value: fields[idx]['status'](),
                    onChanged: (v) {
                      setState(() {
                        fields[idx]['action'](v);
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
                color: Settings.instance.colors.background,
                child: ListView.builder(
                  itemCount: fields.length,
                  itemBuilder: (context, idx) {
                    return CupertinoButton(
                      onPressed: () {
                        if (fields[idx]['route'] is Function &&
                            fields[idx]['route']() != null) {
                          Navigator.pushNamed(context, fields[idx]['route']());
                        }
                      },
                      padding: EdgeInsets.zero,
                      child: buildField(idx),
                    );
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
