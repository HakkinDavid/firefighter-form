import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/viewmodels/form_list.dart'; // Import the FormList component
import 'package:flutter/cupertino.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _searchController = TextEditingController();

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 26),
                      // Search Text Field (non-functional for now)
                      child: CupertinoTextField(
                        controller: _searchController,
                        placeholder: 'Espacio que no hace nada',
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: const Icon(
                            CupertinoIcons.search,
                            size: 24,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        autofocus: true,
                        autocorrect: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Add the FormList component here
                    Expanded(
                      child: FormList(
                        formsList: Settings.instance.formsList,
                        onFormTap: _onFormTap,
                        onPdfTap: _onPdfTap,
                        onDeleteTap: _onDeleteTap,
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