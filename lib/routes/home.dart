import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/viewmodels/form_list.dart';
import 'package:flutter/cupertino.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    _loadSavedForms();
  }

  Future<void> _loadSavedForms() async {
    try {
      await Settings.instance.setForms();
      setState(() {});
    } catch (e) {}
  }

  void _createForm() async {
    int? latestTemplate = await Settings.instance.getNewestSavedTemplate();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/form',
      arguments: {
        'template_id': latestTemplate,
        'filler': Settings.instance.userId,
        'filled_at': DateTime.now().toIso8601String(),
        'content': <String, dynamic>{},
        'status': 0,
      },
    );
  }

  void _onFormTap(ServiceForm form) {
    Navigator.pushReplacementNamed(context, '/form', arguments: form.toJson());
  }

  void _onPdfTap(ServiceForm form) {
    // Future PDF export implementation
  }

  void _onDeleteTap(ServiceForm form) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Eliminar formulario'),
        message: Text(
          '¿Estás seguro de que deseas eliminar el folio ${form.getStatusName.toLowerCase()} "${form.id}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _deleteForm(form);
            },
            isDestructiveAction: true,
            child: Text('Eliminar folio ${form.getStatusName.toLowerCase()}'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void _deleteForm(ServiceForm form) async {
    await form.delete();
    setState(() {});
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
                  child: Container(
                    // ← ADD THIS CONTAINER
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
                                '${Settings.instance.formsList.length} elementos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Forms list component
                        Expanded(
                          // ← NESTED EXPANDED FOR THE FORM LIST
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
