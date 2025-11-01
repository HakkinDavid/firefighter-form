import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
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
    ServiceReliabilityEngineer.instance.enqueueTasks({"SetForms"});
    setState(() {});
  }

  void _createForm() async {
    int? latestTemplate = await Settings.instance.getNewestSavedTemplate();
    if (!mounted) return;
    await Navigator.pushNamed(
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      backgroundColor: Settings.instance.colors.primary,
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
                    child: StreamBuilder<List<ServiceForm>>(
                      stream: Settings.instance.formsListStream,
                      initialData: Settings.instance.formsList,
                      builder: (context, snapshot) {
                        final forms = snapshot.data ?? [];
                        return Column(
                          children: [
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    '${forms.length} elementos',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: FormList(
                                formsList: forms,
                                placeholder: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc,
                                      size: 64,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay formularios',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Toca el botón + para crear uno',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.tertiaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
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
