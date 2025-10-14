import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/models/formList.dart';
import 'package:flutter/cupertino.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Dummy data
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
      'title': 'Formulario Stupid',
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
  void initState() {
    super.initState();
    _loadSavedForms();
  }

  void _loadSavedForms() {

    // Load the forms that we have stored

    print('Loading saved forms...');
  }

  void _createForm() {
    Navigator.pushNamed(context, '/form');
  }

  void _onFormTap(Map<String, dynamic> form) {

    // Form interaction functionality goes Jeer

    print('Tapped on form: ${form['title']}');
  }

  void _onPdfTap(Map<String, dynamic> form) {

    // Future PDF export implementation

    print('Generate PDF for: ${form['title']}');
  }

  void _onDeleteTap(Map<String, dynamic> form) {

    // Implement form deletion soon...

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Eliminar formulario'),
        message: Text('¿Estás seguro de que quieres eliminar "${form['title']}"? Esta acción no se puede deshacer.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteForm(form);
            },
            isDestructiveAction: true,
            child: Text('Eliminar'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void _deleteForm(Map<String, dynamic> form) {
    setState(() {
      _formsList.removeWhere((item) => item['id'] == form['id']);
    });
    // Delete from storage eventually
    print('Deleted form: ${form['title']}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      backgroundColor: Settings.instance.colors.primaryContrast,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Header(
                  username: Settings.instance.self?.fullName,
                  adminUsername: Settings.instance.watcher?.fullName,
                ),
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
            // Button at the bottom right
            Positioned(
              right: 16,
              bottom: 16,
              child: CupertinoButton(
                onPressed: _createForm,
                color: Settings.instance.colors.primaryContrast,
                borderRadius: BorderRadius.circular(48),
                padding: EdgeInsets.all(16),
                child: Icon(
                  CupertinoIcons.add,
                  color: Settings.instance.colors.primary,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}