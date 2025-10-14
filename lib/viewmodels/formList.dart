import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';

class FormList extends StatefulWidget {
  final List<Map<String, dynamic>> formsList;
  final Function(Map<String, dynamic>) onFormTap;
  final Function(Map<String, dynamic>) onPdfTap;
  final Function(Map<String, dynamic>) onDeleteTap;

  const FormList({
    super.key,
    required this.formsList,
    required this.onFormTap,
    required this.onPdfTap,
    required this.onDeleteTap,
  });

  @override
  State<FormList> createState() => _FormListState();
}

class _FormListState extends State<FormList> {
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
                      onPressed: () => widget.onPdfTap(form),
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
                      onPressed: () => widget.onDeleteTap(form),
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
    return Container(
      color: Settings.instance.colors.background,
      child: widget.formsList.isEmpty
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
              itemCount: widget.formsList.length,
              itemBuilder: (context, index) {
                return CupertinoButton(
                  onPressed: () => widget.onFormTap(widget.formsList[index]),
                  padding: EdgeInsets.zero,
                  child: _buildFormListItem(widget.formsList[index]),
                );
              },
            ),
    );
  }
}