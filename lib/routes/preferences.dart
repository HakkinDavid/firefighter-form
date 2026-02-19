import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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

  final List<Map<String, dynamic>> optionsTemplate = [
    {
      "title": "Refrescar plantillas",
      "type": "button",
      "icon": CupertinoIcons.refresh_circled_solid,
      "action": () => ServiceReliabilityEngineer.instance.enqueueTasks([
        "RefreshTemplates",
      ]),
      "status": () => false,
      "available": () => true,
    },
    {
      "title": "Modo depuración",
      "type": "switch",
      "action": (v) =>
          Settings.instance.allowDebugging = !Settings.instance.allowDebugging,
      "status": () => Settings.instance.allowDebugging,
      "route": () => Settings.instance.allowDebugging ? "/console" : null,
      "available": () => true,
    },
    {
      "title": "Editor de plantilla",
      "type": "menu",
      "icon": CupertinoIcons.square_pencil_fill,
      "route": () => "/maker",
      "available": () =>
          Settings.instance.role == 2 &&
          kDebugMode, // TODO: Una vez terminadas estas secciones del app, remover la bandera de modo Debug para acceder
    },
    {
      "title": "Panel de usuarios",
      "type": "menu",
      "icon": CupertinoIcons.person_fill,
      "route": () => "/user_panel",
      "available": () =>
          true &&
          kDebugMode, // TODO: Una vez terminadas estas secciones del app, remover la bandera de modo Debug para acceder
    },
    {
      "title": "Estadísticas",
      "type": "menu",
      "icon": CupertinoIcons.graph_square_fill,
      "route": () => "/statistics",
      "available": () =>
          Settings.instance.role >= 1 &&
          kDebugMode, // TODO: Una vez terminadas estas secciones del app, remover la bandera de modo Debug para acceder
    },
  ];

  List<Map<String, dynamic>> options = const [];

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
                        options[idx]['title'],
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
                if (options[idx]['type'] == 'button')
                  options[idx]['status']()
                      ? CupertinoActivityIndicator()
                      : CupertinoButton(
                          onPressed: () {
                            setState(() {
                              options[idx]['status'] = () => true;
                              options[idx]['action']();
                              options[idx]['status'] = () => false;
                            });
                          },
                          padding: EdgeInsets.all(6),
                          minimumSize: Size(0, 0),
                          child: Icon(
                            options[idx]['icon'],
                            size: 40,
                            color: Settings.instance.colors.primaryContrast,
                          ),
                        ),
                if (options[idx]['type'] == 'switch')
                  CupertinoSwitch(
                    value: options[idx]['status'](),
                    onChanged: (v) {
                      setState(() {
                        options[idx]['action'](v);
                      });
                    },
                  ),
                if (options[idx]['type'] == 'menu')
                  Icon(
                    options[idx]['icon'],
                    size: 40,
                    color: Settings.instance.colors.primaryContrast,
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
    if (options.isEmpty) {
      options = List.of(optionsTemplate.where((x) => x['available']()));
    }
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
                  itemCount: options.length,
                  itemBuilder: (context, idx) {
                    if (options[idx]['route'] is Function &&
                        options[idx]['route']() != null) {
                      return CupertinoButton(
                        onPressed: () {
                          Navigator.pushNamed(context, options[idx]['route']());
                        },
                        padding: EdgeInsets.zero,
                        child: buildField(idx),
                      );
                    } else {
                      return buildField(idx);
                    }
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
