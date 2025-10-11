import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:flutter/cupertino.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Updated dummy data with user and supervisor information
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
  void initState() {
    super.initState();
    _loadSavedForms();
  }

  void _loadSavedForms() {
    // TODO: Load actual saved forms from disk/database
    print('Loading saved forms...');
  }

  void _createForm() {
    Navigator.pushNamed(context, '/form');
  }

  void _onFormTap(Map<String, dynamic> form) {
    // We'll implement form viewing/editing later
    print('Tapped on form: ${form['title']}');
  }

  void _onPdfTap(Map<String, dynamic> form) {
    // TODO: Implement PDF generation/export
    print('Generate PDF for: ${form['title']}');
  }

  void _onDeleteTap(Map<String, dynamic> form) {
    // TODO: Implement form deletion with confirmation
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
    // TODO: Also delete from persistent storage
    print('Deleted form: ${form['title']}');
  }

  Widget _buildFormListItem(Map<String, dynamic> form) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Status icon, Title, and Action buttons
            Row(
              children: [
                // Status icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor(form['status']),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(form['status']),
                    color: Settings.instance.colors.textOverPrimary,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                // Title - expanded to take available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form['title'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Creado: ${form['date']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Action buttons
                Row(
                  children: [
                    // PDF button
                    CupertinoButton(
                      onPressed: () => _onPdfTap(form),
                      padding: EdgeInsets.all(6),
                      minSize: 0,
                      child: Icon(
                        CupertinoIcons.doc,
                        size: 20,
                        color: Settings.instance.colors.primary,
                      ),
                    ),
                    // Delete button
                    CupertinoButton(
                      onPressed: () => _onDeleteTap(form),
                      padding: EdgeInsets.all(6),
                      minSize: 0,
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 20,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // Second row: User and Supervisor information
            Row(
              children: [
                // User information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario:',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        form['user'],
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                // Supervisor information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supervisor:',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        form['supervisor'],
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(form['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    form['status'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(form['status']),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return CupertinoColors.systemGreen;
      case 'pendiente':
        return CupertinoColors.systemOrange;
      case 'borrador':
        return Settings.instance.colors.primary;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
        return CupertinoIcons.checkmark_alt_circle;
      case 'pendiente':
        return CupertinoIcons.clock;
      case 'borrador':
        return CupertinoIcons.doc;
      default:
        return CupertinoIcons.question;
    }
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
                    color: Settings.instance.colors.background,
                    child: Column(
                      children: [
                        // Header for the list
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
                        // Forms list
                        Expanded(
                          child: _formsList.isEmpty
                              ? Center(
                                  child: Column(
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
                                )
                              : ListView.builder(
                                  itemCount: _formsList.length,
                                  itemBuilder: (context, index) {
                                    return CupertinoButton(
                                      onPressed: () => _onFormTap(_formsList[index]),
                                      padding: EdgeInsets.zero,
                                      child: _buildFormListItem(_formsList[index]),
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