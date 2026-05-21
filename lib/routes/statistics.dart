import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/pdf_renderer.dart';
import 'package:bomberos/viewmodels/canvas.dart';
import 'package:flutter/cupertino.dart';

class StatisticsPanel extends StatefulWidget {
  const StatisticsPanel({super.key});

  @override
  State<StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends State<StatisticsPanel> {
  bool _loading = true;
  Map<String, dynamic> _options = {};
  String? _selectedCatalogKey;
  String? _selectedFilterField; // e.g. field internal name
  String? _selectedFilterValue = 'Todos';
  final Map<String, int> _initialStock = {};
  List<Map<String, dynamic>> _filterFieldsList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final forms = Settings.instance.formsList;
      // Ensure all templates are loaded
      await Future.wait(
        forms.map((f) => f.isLoaded ? Future.value() : f.load()),
      );


      // Extract catalogs options map from first available form template
      if (forms.isNotEmpty) {
        final template = forms.first.template;
        if (template['options'] is Map<String, dynamic>) {
          _options = Map<String, dynamic>.from(template['options'] as Map<String, dynamic>);
        }
      }

      if (_options.keys.isNotEmpty) {
        _selectedCatalogKey = _options.keys.contains('supplies') ? 'supplies' : _options.keys.first;
      }

      // Collect eligible filter fields (standard non-tuple non-drawing fields with labels)
      final Set<String> addedFields = {};
      _filterFieldsList = [];
      if (forms.isNotEmpty) {
        final template = forms.first.template;
        final fieldsMap = template['fields'] as Map<String, dynamic>? ?? {};
        for (final section in fieldsMap.keys) {
          for (final field in fieldsMap[section]) {
            final String name = (field['name'] ?? '').toString();
            final String label = (field['label'] ?? '').toString();
            final String type = (field['type'] ?? '').toString();
            if (name.isNotEmpty &&
                label.isNotEmpty &&
                type != 'tuple' &&
                type != 'drawingboard') {
              if (!addedFields.contains(name)) {
                addedFields.add(name);
                _filterFieldsList.add({
                  'name': name,
                  'label': label,
                });
              }
            }
          }
        }
      }

      _selectedFilterField = null; // default to no filter
      _selectedFilterValue = 'Todos';
    } catch (_) {}

    setState(() => _loading = false);
  }

  List<String> _getFilterValues() {
    if (_selectedFilterField == null) return ['Todos'];
    final Set<String> unique = {'Todos'};
    final forms = Settings.instance.formsList;
    for (final form in forms) {
      final val = form.content[_selectedFilterField!];
      if (val != null && val.toString().trim().isNotEmpty) {
        unique.add(val.toString().trim());
      }
    }
    final list = unique.toList();
    list.sort();
    return list;
  }

  Map<String, double> _calculateAggregatedCounts() {
    final forms = Settings.instance.formsList;
    final Map<String, double> counts = {};

    if (_selectedCatalogKey == null) return counts;

    // Pre-initialize counts for all items in the selected catalog to 0
    final catalogItems = _options[_selectedCatalogKey!] as List<dynamic>? ?? [];
    for (final item in catalogItems) {
      final String name = (item is Map) ? (item['name'] ?? '').toString() : item.toString();
      if (name.isNotEmpty) {
        counts[name] = 0.0;
      }
    }

    // Filter forms according to selectedFilterField and selectedFilterValue
    final List<ServiceForm> filteredForms = forms.where((form) {
      if (_selectedFilterField == null || _selectedFilterValue == 'Todos') {
        return true;
      }
      final val = form.content[_selectedFilterField];
      return val?.toString().trim() == _selectedFilterValue;
    }).toList();

    // Sum quantities from tuple numeric subfields or count regular fields
    for (final form in filteredForms) {
      final template = form.template;
      final fields = template['fields'] as Map<String, dynamic>? ?? {};
      for (final section in fields.keys) {
        for (final field in fields[section]) {
          if (field['type'] == 'tuple') {
            final tupleName = field['name'];
            final List<dynamic> rows =
                form.content[tupleName] is List ? form.content[tupleName] as List : [];

            // Check if any subfield links to the current selectedCatalogKey
            String? selectSubfieldName;
            for (final sf in field['tuple']) {
              if (sf['optionsFrom'] == _selectedCatalogKey) {
                selectSubfieldName = sf['name'];
                break;
              }
            }

            if (selectSubfieldName != null) {
              // Try to find if any numeric subfield exists in this tuple
              String? numericSubfieldName;
              for (final sf in field['tuple']) {
                if (sf['type'] == 'input' && sf['inputType'] == 'number') {
                  numericSubfieldName = sf['name'];
                  break;
                }
              }

              for (final row in rows) {
                if (row is Map) {
                  final itemVal = (row[selectSubfieldName] ?? '').toString();
                  if (itemVal.isNotEmpty) {
                    double amt = 1.0;
                    if (numericSubfieldName != null) {
                      amt = double.tryParse(row[numericSubfieldName].toString()) ?? 0.0;
                    }
                    counts[itemVal] = (counts[itemVal] ?? 0.0) + amt;
                  }
                }
              }
            }
          } else {
            // Standard field linking
            if (field['optionsFrom'] == _selectedCatalogKey) {
              final fieldVal = form.content[field['name']];
              if (fieldVal is List) {
                for (final item in fieldVal) {
                  final str = item.toString();
                  if (str.isNotEmpty) {
                    counts[str] = (counts[str] ?? 0.0) + 1.0;
                  }
                }
              } else if (fieldVal != null) {
                final str = fieldVal.toString();
                if (str.isNotEmpty) {
                  counts[str] = (counts[str] ?? 0.0) + 1.0;
                }
              }
            }
          }
        }
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return CupertinoPageScaffold(
        backgroundColor: Settings.instance.colors.primaryContrast,
        child: const Center(
          child: CupertinoActivityIndicator(radius: 16),
        ),
      );
    }

    final countsMap = _calculateAggregatedCounts();
    final countsList = countsMap.entries.toList();
    // Sort descending by value (or alphabetically if zero)
    countsList.sort((a, b) {
      final comp = b.value.compareTo(a.value);
      if (comp != 0) return comp;
      return a.key.compareTo(b.key);
    });

    final totalCount = countsList.fold<double>(0.0, (sum, entry) => sum + entry.value);
    final isSupplies = _selectedCatalogKey == 'supplies';

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
            // Header Title and Export Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isSupplies ? 'INVENTARIO DE INSUMOS' : 'ANÁLISIS DE CATÁLOGO',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    color: Settings.instance.colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: countsList.isEmpty ? null : _exportPdfReport,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(CupertinoIcons.share_up, size: 18),
                        SizedBox(width: 6),
                        Text('Exportar PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // General Filter Controls Section (Card)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: Target Catalog Key selector
                  Row(
                    children: [
                      const Text(
                        'Catálogo objetivo: ',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          final keys = _options.keys.toList();
                          await showCupertinoModalPopup<void>(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              title: const Text('Seleccionar catálogo objetivo'),
                              actions: keys.map((key) {
                                return CupertinoActionSheetAction(
                                  onPressed: () {
                                    setState(() {
                                      _selectedCatalogKey = key;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text(key.toUpperCase()),
                                );
                              }).toList(),
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(
                                (_selectedCatalogKey ?? 'NINGUNO').toUpperCase(),
                                style: TextStyle(
                                  color: Settings.instance.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_down, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: Filter Field
                  Row(
                    children: [
                      const Text(
                        'Filtrar por campo: ',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await showCupertinoModalPopup<void>(
                            context: context,
                            builder: (context) => CupertinoActionSheet(
                              title: const Text('Seleccionar campo para filtrar'),
                              actions: [
                                CupertinoActionSheetAction(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFilterField = null;
                                      _selectedFilterValue = 'Todos';
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('NINGUNO (Todos los registros)'),
                                ),
                                ..._filterFieldsList.map((f) {
                                  return CupertinoActionSheetAction(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFilterField = f['name'];
                                        _selectedFilterValue = 'Todos';
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text(f['label']),
                                  );
                                }),
                              ],
                              cancelButton: CupertinoActionSheetAction(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedFilterField == null
                                    ? 'SIN FILTRO'
                                    : (_filterFieldsList.firstWhere(
                                        (f) => f['name'] == _selectedFilterField,
                                        orElse: () => {'label': _selectedFilterField},
                                      )['label']),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(CupertinoIcons.chevron_down, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedFilterField != null) ...[
                    const SizedBox(height: 10),
                    // Row 3: Filter Value selector
                    Row(
                      children: [
                        const Text(
                          'Valor del filtro: ',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            final vals = _getFilterValues();
                            await showCupertinoModalPopup<void>(
                              context: context,
                              builder: (context) => CupertinoActionSheet(
                                title: const Text('Seleccionar valor de filtro'),
                                actions: vals.map((v) {
                                  return CupertinoActionSheetAction(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFilterValue = v;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text(v),
                                  );
                                }).toList(),
                                cancelButton: CupertinoActionSheetAction(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _selectedFilterValue ?? 'Todos',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Icon(CupertinoIcons.chevron_down, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Aggregated Statistics Table View
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
                    // Table Header Column Labels
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Settings.instance.colors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              isSupplies ? 'Material / Insumo' : 'Elemento de Catálogo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              isSupplies ? 'Consumido' : 'Frecuencia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          if (isSupplies) ...[
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Stock Inicial',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Settings.instance.colors.textOverPrimary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Existencia',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Settings.instance.colors.textOverPrimary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Porcentaje (%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Settings.instance.colors.textOverPrimary,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Table Scrollable Items List
                    Expanded(
                      child: countsList.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay datos registrados para este catálogo.',
                                style: TextStyle(color: CupertinoColors.secondaryLabel),
                              ),
                            )
                          : ListView.builder(
                              itemCount: countsList.length,
                              itemBuilder: (context, index) {
                                final entry = countsList[index];
                                final itemName = entry.key;
                                final countVal = entry.value;
                                final isLastItem = index == countsList.length - 1;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                      // Item name
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          itemName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoColors.black,
                                          ),
                                        ),
                                      ),
                                      // Consumido / Frecuencia count
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          countVal.toStringAsFixed(
                                            countVal == countVal.toInt() ? 0 : 1,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      if (isSupplies) ...[
                                        // Editable Initial Stock Cell
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: GestureDetector(
                                              onTap: () => _editInitialStock(itemName),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: CupertinoColors.systemGrey6
                                                      .resolveFrom(context),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      (_initialStock[itemName] ?? 0).toString(),
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: CupertinoColors.activeBlue,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      CupertinoIcons.pencil,
                                                      size: 12,
                                                      color: CupertinoColors.activeBlue,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Calculated stock existence cell
                                        Expanded(
                                          flex: 2,
                                          child: () {
                                            final currentStock = _initialStock[itemName] ?? 0;
                                            final remaining = currentStock - countVal;
                                            final isNegative = remaining < 0;
                                            return Text(
                                              remaining.toStringAsFixed(
                                                remaining == remaining.toInt() ? 0 : 1,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isNegative
                                                    ? CupertinoColors.systemRed
                                                    : CupertinoColors.systemGreen,
                                              ),
                                              textAlign: TextAlign.right,
                                            );
                                          }(),
                                        ),
                                      ] else ...[
                                        // Percentages
                                        Expanded(
                                          flex: 2,
                                          child: () {
                                            final pct =
                                                totalCount > 0 ? (countVal / totalCount) * 100 : 0.0;
                                            return Text(
                                              '${pct.toStringAsFixed(1)}%',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: CupertinoColors.secondaryLabel,
                                              ),
                                              textAlign: TextAlign.right,
                                            );
                                          }(),
                                        ),
                                      ],
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

  Future<void> _editInitialStock(String itemName) async {
    final currentStockStr = (_initialStock[itemName] ?? 0).toString();
    final controller = TextEditingController(text: currentStockStr);

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Editar Stock Inicial'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            placeholder: 'ej. 10',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final newStock = int.tryParse(controller.text) ?? 0;
              setState(() {
                _initialStock[itemName] = newStock;
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _exportPdfReport() async {
    if (_selectedCatalogKey == null) return;

    final canvasController = ServiceCanvasController();
    String? signatureSvg;
    bool isConfirmed = false;

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Firma del Responsable'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Por favor dibuje su firma a continuación para autorizar el reporte.',
                style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Settings.instance.colors.disabled),
                  borderRadius: BorderRadius.circular(8),
                  color: CupertinoColors.white,
                ),
                child: ServiceCanvas(
                  controller: canvasController,
                  readOnly: false,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Limpiar Firma', style: TextStyle(color: CupertinoColors.destructiveRed)),
                onPressed: () {
                  canvasController.clear();
                },
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              signatureSvg = await canvasController.exportAsSvg();
              isConfirmed = true;
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmar y Exportar'),
          ),
        ],
      ),
    );

    if (!isConfirmed) return;

    final countsMap = _calculateAggregatedCounts();
    final countsList = countsMap.entries.toList();
    countsList.sort((a, b) {
      final comp = b.value.compareTo(a.value);
      if (comp != 0) return comp;
      return a.key.compareTo(b.key);
    });

    final totalCount = countsList.fold<double>(0.0, (sum, entry) => sum + entry.value);
    final isSupplies = _selectedCatalogKey == 'supplies';

    final title = isSupplies ? 'Reporte de Consumo e Inventario' : 'Reporte de Frecuencias de Catálogo';
    final List<String> headers = isSupplies
        ? ['MATERIAL / INSUMO', 'CONSUMIDO', 'STOCK INICIAL', 'EXISTENCIA ACTUAL']
        : ['ELEMENTO', 'FRECUENCIA', 'PORCENTAJE (%)'];

    final List<List<String>> rows = [];
    for (final entry in countsList) {
      final itemName = entry.key;
      final val = entry.value;
      final valStr = val.toStringAsFixed(val == val.toInt() ? 0 : 1);

      if (isSupplies) {
        final initial = _initialStock[itemName] ?? 0;
        final current = initial - val;
        final currentStr = current.toStringAsFixed(current == current.toInt() ? 0 : 1);
        rows.add([itemName, valStr, initial.toString(), currentStr]);
      } else {
        final pct = totalCount > 0 ? (val / totalCount) * 100 : 0.0;
        rows.add([itemName, valStr, '${pct.toStringAsFixed(1)}%']);
      }
    }

    final Map<String, String> filters = {
      'Catálogo Objetivo': _selectedCatalogKey!.toUpperCase(),
    };
    if (_selectedFilterField != null) {
      final fieldLabel = _filterFieldsList.firstWhere(
        (f) => f['name'] == _selectedFilterField,
        orElse: () => {'label': _selectedFilterField},
      )['label'];
      filters['Filtrado Por'] = fieldLabel;
      filters['Valor del Filtro'] = _selectedFilterValue ?? 'Todos';
    }

    await ServicePDF.generateInventoryReport(
      title: title,
      headers: headers,
      rows: rows,
      filters: filters,
      signatureSvg: signatureSvg,
    );
  }
}