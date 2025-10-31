import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/viewmodels/form_list.dart';
import 'package:flutter/cupertino.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool passesSearchCriteria(ServiceForm element) {
    final searchText = _searchController.text.trim().toLowerCase();
  
    final searchTerms = searchText.split(' ').where((term) => term.isNotEmpty).toList();
  
    // If no filters are active, show NO forms
    if (searchTerms.isEmpty && _startDate == null && _endDate == null) {
      return false;
    }
  
    // Text filter: if no search terms, all forms pass text filter
    final bool passesTextFilter = searchTerms.isEmpty || 
        searchTerms.every((term) => _matchesSearchTerm(element, term));
  
    // Date filter
    final bool passesDateFilter = _passesDateFilter(element);
  
    // Both filters must pass
    return passesTextFilter && passesDateFilter;
  }

  bool _matchesSearchTerm(ServiceForm element, String term) {
    // Check if term matches ANY characteristic
    return element.id.toLowerCase().contains(term) ||
        element.statusName.toLowerCase().contains(term) ||
        _userMatchesSearch(element, term) ||
        _tagsMatchSearch(element, term);
  }

  bool _userMatchesSearch(ServiceForm element, String searchText) {
    try {
      final creator = Settings.instance.getUserOrFail(pUserId: element.filler);
      return creator.fullName.toLowerCase().contains(searchText);
    } catch (e) {
      return false;
    }
  }

  bool _tagsMatchSearch(ServiceForm element, String searchText) {
    return element.tags.any((tag) => tag.toLowerCase().contains(searchText));
  }

  Future<void> _showDatePicker(bool isStartDate) async {
    final initialDate = DateTime.now();
    DateTime? selectedDate;
    
    await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216,
        padding: const EdgeInsets.only(top: 6.0),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: isStartDate ? _startDate : _endDate ?? initialDate,
            minimumDate: DateTime(2000),
            maximumDate: DateTime(2100),
            onDateTimeChanged: (DateTime newDate) {
              selectedDate = newDate;
            },
          ),
        ),
      ),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          if (_endDate != null && _endDate!.isBefore(selectedDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = selectedDate;
          if (_startDate != null && _startDate!.isAfter(selectedDate!)) {
            _startDate = null;
          }
        }
      });
    }
  }

  bool _passesDateFilter(ServiceForm element) {
    if (_startDate != null || _endDate != null) {
      final formDate = element.filledAt;
      
      if (_startDate != null && _endDate != null) {
        // Both dates selected
        return !formDate.isBefore(_startDate!) && !formDate.isAfter(_endDate!);
      } else if (_startDate != null) {
        // Only start date (>StartDate)
        return !formDate.isBefore(_startDate!);
      } else if (_endDate != null) {
        // Only end date (<EndDate)
        return !formDate.isAfter(_endDate!);
      }
    }
    return true;
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  String _getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    } else if (_startDate != null) {
      return 'Desde ${_formatDate(_startDate!)}';
    } else if (_endDate != null) {
      return 'Hasta ${_formatDate(_endDate!)}';
    }
    return 'Rango de fechas';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
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
            ),
            Expanded(
              child: Container(
                color: Settings.instance.colors.background,
                child: StreamBuilder<List<ServiceForm>>(
                  stream: Settings.instance.formsListStream,
                  initialData: Settings.instance.formsList,
                  builder: (context, snapshot) {
                    final forms = (snapshot.data ?? []).where(passesSearchCriteria).toList();
                    return Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Column(
                            children: [
                              // Search Text Field
                              CupertinoTextField(
                                controller: _searchController,
                                placeholder: 'Buscar por folio, estado, bombero o etiquetas',
                                decoration: BoxDecoration(
                                  color: Settings.instance.colors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey4,
                                  ),
                                ),
                                suffix: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    CupertinoIcons.search,
                                    size: 20,
                                    color: Settings.instance.colors.primary,
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                autofocus: true,
                                autocorrect: false,
                                onChanged: (value) => setState(() {}),
                              ),
                              SizedBox(height: 12),
                              // Date Filter Row
                              Row(
                                children: [
                                  // Before Button
                                  Expanded(
                                    child: CupertinoButton(
                                      onPressed: () => _showDatePicker(true),
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      color: _startDate != null 
                                          ? Settings.instance.colors.primary
                                          : Settings.instance.colors.disabled,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.calendar,
                                            size: 16,
                                            color: _startDate != null
                                                ? Settings.instance.colors.textOverPrimary
                                                : CupertinoColors.secondaryLabel,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Desde',
                                            style: TextStyle(
                                              color: _startDate != null
                                                  ? Settings.instance.colors.textOverPrimary
                                                  : CupertinoColors.secondaryLabel,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // After Button
                                  Expanded(
                                    child: CupertinoButton(
                                      onPressed: () => _showDatePicker(false),
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      color: _endDate != null 
                                          ? Settings.instance.colors.primary
                                          : Settings.instance.colors.disabled,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.calendar,
                                            size: 16,
                                            color: _endDate != null
                                                ? Settings.instance.colors.textOverPrimary
                                                : CupertinoColors.secondaryLabel,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Hasta',
                                            style: TextStyle(
                                              color: _endDate != null
                                                  ? Settings.instance.colors.textOverPrimary
                                                  : CupertinoColors.secondaryLabel,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Date Range Display and Clear Button
                              if (_startDate != null || _endDate != null) ...[
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _getDateRangeText(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Settings.instance.colors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    CupertinoButton(
                                      onPressed: _clearDateFilters,
                                      padding: EdgeInsets.zero,
                                      minSize: 0,
                                      child: Text(
                                        'Limpiar',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Settings.instance.colors.primaryBright,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Add the FormList component here
                        Expanded(
                          child: FormList(
                            formsList: forms
                          ),
                        ),
                      ],
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