import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/pdf_renderer.dart';
import 'package:bomberos/viewmodels/canvas.dart';
import 'package:flutter/cupertino.dart';

enum ChartType { bar, pie, none }

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
  final Set<String> _selectedFilterValues = {'Todos'};
  List<Map<String, dynamic>> _filterFieldsList = [];
  ChartType _selectedChartType = ChartType.bar;

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
        _selectedCatalogKey = _options.keys.contains('insumos') ? 'insumos' : _options.keys.first;
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
      _selectedFilterValues.clear();
      _selectedFilterValues.add('Todos');
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

  String _normalize(String input) {
    var s = input.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[ñ]'), 'n');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  Future<void> _showPredictiveSelector({
    required String title,
    required List<Map<String, dynamic>> items,
    required bool isMultiSelect,
    required Set<dynamic> currentSelection,
    required ValueChanged<Set<dynamic>> onSelectionChanged,
  }) async {
    final searchController = TextEditingController();
    final tempSelection = Set<dynamic>.from(currentSelection);

    await showCupertinoModalPopup<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text;
            final normalizedQuery = _normalize(query);

            final filteredItems = items.where((item) {
              if (normalizedQuery.isEmpty) return true;
              final normalizedLabel = _normalize(item['label'] ?? '');
              return normalizedLabel.contains(normalizedQuery);
            }).toList();

            final primaryColor = Settings.instance.colors.primary;
            final contrastColor = Settings.instance.colors.primaryContrast;

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: BoxDecoration(
                  color: contrastColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Modal Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.black,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (isMultiSelect) {
                                onSelectionChanged(tempSelection);
                              }
                              Navigator.pop(context);
                            },
                            child: Text(
                              isMultiSelect ? 'Hecho' : 'Cerrar',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: CupertinoSearchTextField(
                        controller: searchController,
                        placeholder: 'Buscar...',
                        onChanged: (val) {
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Items List
                    Expanded(
                      child: filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron resultados',
                                style: TextStyle(color: CupertinoColors.secondaryLabel),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final itemId = item['id'];
                                final itemLabel = item['label'] as String;
                                final isSelected = tempSelection.contains(itemId);

                                return CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    if (isMultiSelect) {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelection.remove(itemId);
                                        } else {
                                          tempSelection.add(itemId);
                                        }
                                      });
                                    } else {
                                      onSelectionChanged({itemId});
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: CupertinoColors.systemGrey6,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (isMultiSelect) ...[
                                          Icon(
                                            isSelected
                                                ? CupertinoIcons.checkmark_square_fill
                                                : CupertinoIcons.square,
                                            color: isSelected ? primaryColor : CupertinoColors.systemGrey4,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          child: Text(
                                            itemLabel,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: CupertinoColors.black,
                                            ),
                                          ),
                                        ),
                                        if (!isMultiSelect && isSelected)
                                          Icon(
                                            CupertinoIcons.checkmark,
                                            color: primaryColor,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
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

    // Filter forms according to selectedFilterField and selectedFilterValues
    final List<ServiceForm> filteredForms = forms.where((form) {
      if (_selectedFilterField == null ||
          _selectedFilterValues.contains('Todos') ||
          _selectedFilterValues.isEmpty) {
        return true;
      }
      final val = form.content[_selectedFilterField];
      return _selectedFilterValues.contains(val?.toString().trim());
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
    final isSupplies = _selectedCatalogKey == 'insumos';

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
                      children: [
                        Icon(CupertinoIcons.share_up, size: 18, color: Settings.instance.colors.textOverPrimary),
                        const SizedBox(width: 6),
                        Text('Exportar PDF', style: TextStyle(fontWeight: FontWeight.w600, color: Settings.instance.colors.textOverPrimary)),
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
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
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
                          final items = keys.map((k) => {'id': k, 'label': k.toUpperCase()}).toList();
                          await _showPredictiveSelector(
                            title: 'Seleccionar catálogo objetivo',
                            items: items,
                            isMultiSelect: false,
                            currentSelection: _selectedCatalogKey != null ? {_selectedCatalogKey} : {},
                            onSelectionChanged: (newSelection) {
                              if (newSelection.isNotEmpty) {
                                setState(() {
                                  _selectedCatalogKey = newSelection.first as String;
                                  _selectedFilterField = null;
                                  _selectedFilterValues.clear();
                                  _selectedFilterValues.add('Todos');
                                });
                              }
                            },
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
                          final items = <Map<String, dynamic>>[
                            {'id': null, 'label': 'NINGUNO (Todos los registros)'}
                          ];
                          items.addAll(_filterFieldsList.map((f) => {'id': f['name'], 'label': f['label']}));

                          await _showPredictiveSelector(
                            title: 'Seleccionar campo para filtrar',
                            items: items,
                            isMultiSelect: false,
                            currentSelection: {_selectedFilterField},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                _selectedFilterField = newSelection.first;
                                _selectedFilterValues.clear();
                                _selectedFilterValues.add('Todos');
                              });
                            },
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
                    // Row 3: Filter Value selector (Multi-select)
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
                            final items = vals.map((v) => {'id': v, 'label': v}).toList();

                            await _showPredictiveSelector(
                              title: 'Seleccionar valores de filtro',
                              items: items,
                              isMultiSelect: true,
                              currentSelection: _selectedFilterValues,
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  final set = newSelection.map((e) => e.toString()).toSet();
                                  if (set.contains('Todos') && !_selectedFilterValues.contains('Todos')) {
                                    _selectedFilterValues.clear();
                                    _selectedFilterValues.add('Todos');
                                  } else {
                                    _selectedFilterValues.clear();
                                    _selectedFilterValues.addAll(set);
                                    if (_selectedFilterValues.length > 1 &&
                                        _selectedFilterValues.contains('Todos')) {
                                      _selectedFilterValues.remove('Todos');
                                    }
                                    if (_selectedFilterValues.isEmpty) {
                                      _selectedFilterValues.add('Todos');
                                    }
                                  }
                                });
                              },
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
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    _selectedFilterValues.contains('Todos')
                                        ? 'Todos'
                                        : _selectedFilterValues.join(', '),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                  ],
                ],
              ),
            ),
            // Chart Selection Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSegmentedControl<ChartType>(
                  groupValue: _selectedChartType,
                  selectedColor: Settings.instance.colors.primary,
                  borderColor: Settings.instance.colors.primary,
                  onValueChanged: (val) => setState(() => _selectedChartType = val),
                  children: const {
                    ChartType.bar: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Gráfico de barras', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    ChartType.pie: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Gráfico de pastel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    ChartType.none: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Sin gráfico', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  },
                ),
              ),
            ),
            // Chart Display Card
            if (_selectedChartType != ChartType.none && countsList.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _selectedChartType == ChartType.bar
                    ? HorizontalBarChart(
                        data: countsList,
                        total: totalCount,
                        primaryColor: Settings.instance.colors.primary,
                      )
                    : DonutChart(
                        data: countsList,
                        total: totalCount,
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
                              isSupplies ? 'Insumo' : 'Elemento de Catálogo',
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
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Porcentaje',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
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
            child: const Text('Exportar'),
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
    final isSupplies = _selectedCatalogKey == 'insumos';

    final title = isSupplies ? 'Reporte de Consumo e Inventario' : 'Reporte de Frecuencias de Catálogo';
    final List<String> headers = ['INSUMO', 'CANTIDAD', 'PORCENTAJE'];

    final List<List<String>> rows = [];
    for (final entry in countsList) {
      final itemName = entry.key;
      final val = entry.value;
      final valStr = val.toStringAsFixed(val == val.toInt() ? 0 : 1);
      final pct = totalCount > 0 ? (val / totalCount) * 100 : 0.0;
      rows.add([itemName, valStr, '${pct.toStringAsFixed(1)}%']);
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
      filters['Valor del Filtro'] = _selectedFilterValues.contains('Todos')
          ? 'Todos'
          : _selectedFilterValues.join(', ');
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

class HorizontalBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final double total;
  final Color primaryColor;

  const HorizontalBarChart({
    super.key,
    required this.data,
    required this.total,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos para graficar',
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      );
    }

    final List<MapEntry<String, double>> displayData = [];
    double othersSum = 0;
    if (data.length <= 7) {
      displayData.addAll(data);
    } else {
      displayData.addAll(data.take(6));
      othersSum = data.skip(6).fold(0.0, (sum, entry) => sum + entry.value);
      if (othersSum > 0) {
        displayData.add(MapEntry('Otros', othersSum));
      }
    }

    final double maxVal = displayData.isEmpty
        ? 1.0
        : displayData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: displayData.map((entry) {
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
        final barWidthFactor = maxVal > 0 ? (entry.value / maxVal) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              // Label
              Expanded(
                flex: 3,
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Bar Container
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    // Background track
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    // Foreground bar with gradient
                    FractionallySizedBox(
                      widthFactor: barWidthFactor,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Value
              SizedBox(
                width: 70,
                child: Text(
                  '${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.secondaryLabel,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class DonutChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final double total;

  const DonutChart({
    super.key,
    required this.data,
    required this.total,
  });

  static final List<Color> _chartColors = [
    const Color(0xFF0F172A), // Slate Dark
    const Color(0xFF3B82F6), // Indigo/Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEF4444), // Red
    const Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos para graficar',
          style: TextStyle(color: CupertinoColors.secondaryLabel),
        ),
      );
    }

    final List<MapEntry<String, double>> displayData = [];
    double othersSum = 0;
    if (data.length <= 7) {
      displayData.addAll(data);
    } else {
      displayData.addAll(data.take(6));
      othersSum = data.skip(6).fold(0.0, (sum, entry) => sum + entry.value);
      if (othersSum > 0) {
        displayData.add(MapEntry('Otros', othersSum));
      }
    }

    return Row(
      children: [
        // Donut circle
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: DonutChartPainter(
                  data: displayData,
                  colors: _chartColors,
                  total: total,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.secondaryLabel,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  total.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Legend List
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(displayData.length, (index) {
              final entry = displayData[index];
              final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
              final color = _chartColors[index % _chartColors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final List<Color> colors;
  final double total;

  DonutChartPainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) {
      final paint = Paint()
        ..color = CupertinoColors.systemGrey5
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 8, paint);
      return;
    }

    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius - 8);

    double startAngle = -3.1415926535 / 2; // Start from top (-90 degrees)

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      if (entry.value == 0) continue;

      final sweepAngle = (entry.value / total) * 2 * 3.1415926535;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}