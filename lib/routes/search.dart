import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/viewmodels/formList.dart'; // Import the FormList component
import 'package:flutter/cupertino.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _searchController = TextEditingController();
  
  // Dummy data for the forms list (same as in home.dart)
  final List<Map<String, dynamic>> _formsList = [
    {
      'id': '1',
      'title': 'Formulario dummy',
      'date': '2024-01-15',
      'status': 'Completado',
      'user': 'Mauricio Alcántar',
      'supervisor': 'S',
    },
    {
      'id': '2', 
      'title': 'Formlulario Stupid',
      'date': '2024-02-26',
      'status': 'Pendiente',
      'user': 'Espárrago Gazpacho',
      'supervisor': 'T',
    },
    {
      'id': '3',
      'title': 'Formulario Tontín',
      'date': '2024-03-37',
      'status': 'Completado',
      'user': 'Telurio Fuzetinio',
      'supervisor': 'A',
    },
    {
      'id': '4',
      'title': 'Formulario  de   Dunce',
      'date': '2024-04-48',
      'status': 'Borrador',
      'user': 'David Emmanuel',
      'supervisor': 'C',
    },
    {
      'id': '5',
      'title': 'Roberto de Arimotonga',
      'date': '2024-05-59r',
      'status': 'Borrador',
      'user': 'Santana Romero',
      'supervisor': 'K',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Empty callback functions for the FormList
  void _onFormTap(Map<String, dynamic> form) {
    print('Tapped on form: ${form['title']}');
  }

  void _onPdfTap(Map<String, dynamic> form) {
    print('Generate PDF for: ${form['title']}');
  }

  void _onDeleteTap(Map<String, dynamic> form) {
  // Show a message that deletion is not available from search
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text('Acción no disponible'),
      content: Text('La eliminación de formularios no está disponible desde la búsqueda.'),
      actions: [
        CupertinoDialogAction(
          child: Text('OK'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
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
                        formsList: _formsList,
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