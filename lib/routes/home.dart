import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/viewmodels/formList.dart';
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
      'id': 'foliodeejemplo1',
      'template_id': 1,
      'filler': Settings.instance.userId,
      'status': 0,
      'content': <String, dynamic>{},
      'filled_at': DateTime.now()
    },
    {
      'id': 'foliodeejemplo2',
      'template_id': 1,
      'filler': Settings.instance.userId,
      'status': 1,
      'content': <String, dynamic>{},
      'filled_at': DateTime.now()
    },
    {
      'id': 'foliodeejemplo3',
      'template_id': 1,
      'filler': Settings.instance.userId,
      'status': 2,
      'content': <String, dynamic>{},
      'filled_at': DateTime.now()
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedForms();
  }

  void _loadSavedForms() {

    // Load the forms that we have stored
  }

  void _createForm() async {
    int? latestTemplate = await Settings.instance.getNewestSavedTemplate();
    if (!mounted) return;
    Navigator.pushNamed(context, '/form', arguments: {
      'template_id': latestTemplate,
      'filler': Settings.instance.userId,
      'filled_at': DateTime.now(),
      'content': <String, dynamic>{},
      'status': 0,
    });
  }

  void _onFormTap(Map<String, dynamic> form) {

    // Form interaction functionality goes Jeer
  }

  void _onPdfTap(Map<String, dynamic> form) {

    // Future PDF export implementation
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
                child: Container(  // ← ADD THIS CONTAINER
                  color: Settings.instance.colors.background,
                  child: Column(
                    children: [
                      // Header for the list - NOW ONLY IN HOME
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Settings.instance.colors.primaryContrast,
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.separator,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Formularios Recientes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Settings.instance.colors.primary,
                              ),
                            ),
                            Text(
                              '${_formsList.length} elementos',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Forms list component
                      Expanded(  // ← NESTED EXPANDED FOR THE FORM LIST
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
          // Floating action button positioned at bottom right
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