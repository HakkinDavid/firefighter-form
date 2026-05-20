import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';

class StatisticsPanel extends StatefulWidget {
  const StatisticsPanel({super.key});

  @override
  State<StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends State<StatisticsPanel> {
  // Hardcoded for now until we can fetch from BD
  final List<Map<String, dynamic>> _tableData = [
    {
      'material': 'BOLSA VÁLVULA MASCARILLA ADULTA',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'FILTRO VIRAL PARA BVM',
      'count': 2,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'CANULAS NASOFARÍNGEA #9',
      'count': 3,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'GEL LUBRICANTE HIDROSOLUBLE',
      'count': 100,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'OXÍGENO DE TANQUE TIPO D 360 L',
      'count': 16,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'CANULA RÍGIDA DE SUCCIÓN',
      'count': 24,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'LÍNEA DE SUCCIÓN',
      'count': 32,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'PARCHES ADULTO PARA DAE',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'TIJERAS DE USO RUDO',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'GUANTES DE NITRILO L',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'CUBRE BOCAS SIMPLES',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'CUBRE BOCAS N#95',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'SOLUCIÓN SALINA 0.9% DE 250 CC',
      'count': 1,
      'lastModified': '19-05-2026',
    },
    {
      'material': 'NORMOGOTERO',
      'count': 1,
      'lastModified': '20-05-2026',
    },
    {
      'material': 'CÁTETER INTRAVENOSO # 18',
      'count': 1,
      'lastModified': '20-05-2026',
    },
    {
      'material': 'LIGADURA',
      'count': 1,
      'lastModified': '20-05-2026',
    },
  ];

  @override
  void dispose() {
    super.dispose();
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
              versionString: ServiceReliabilityEngineer.appVersion,
            ),
            // Title
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'ESTADÍSTICAS DE INSUMOS',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            // Table
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Settings.instance.colors.primaryContrastDark,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Settings.instance.colors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Material',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Cantidad',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Última Modificación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Body
                    Expanded(
                      child: ListView.builder(
                        itemCount: _tableData.length,
                        itemBuilder: (context, index) {
                          final item = _tableData[index];
                          final isLastItem = index == _tableData.length - 1;
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: isLastItem
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: Settings.instance.colors.primaryContrastDark,
                                        width: 0.5,
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item['material'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    item['count'].toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: CupertinoColors.black,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item['lastModified'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: CupertinoColors.black,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}