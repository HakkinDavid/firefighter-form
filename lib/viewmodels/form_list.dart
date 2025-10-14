import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';

class FormList extends StatefulWidget {
  final List<ServiceForm> formsList;
  final Function(ServiceForm) onFormTap;
  final Function(ServiceForm) onPdfTap;
  final Function(ServiceForm) onDeleteTap;

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
  Widget _buildFormListItem(ServiceForm form) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
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
                    color: _getStatusColor(form.status),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(form.status),
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
                        'Folio: ${form.id}',
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
                        'Llenado: ${form.filledAt}',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      Text(
                        'Plantilla: v${form.templateId}.0',
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
                      minimumSize: Size(0, 0),
                      child: Icon(
                        CupertinoIcons.doc,
                        size: 20,
                        color: Settings.instance.colors.primary,
                      ),
                    ),
                    if (form.canDeleteForm)
                      // Delete button
                      CupertinoButton(
                        onPressed: () => widget.onDeleteTap(form),
                        padding: EdgeInsets.all(6),
                        minimumSize: Size(0, 0),
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
                        'Responsable:',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        Settings.instance
                            .getUserOrFail(pUserId: form.filler)
                            .fullName,
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
                    color: _getStatusColor(form.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusName(form.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(form.status),
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

  String _getStatusName(int status) {
    switch (status) {
      case 2:
        return "Sincronizado";
      case 1:
        return "Finalizado";
      case 0:
      default:
        return "Borrador";
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 2:
        return CupertinoColors.systemGreen;
      case 1:
        return CupertinoColors.systemOrange;
      case 0:
        return Settings.instance.colors.primary;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 2:
        return CupertinoIcons.checkmark_alt_circle;
      case 1:
        return CupertinoIcons.clock;
      case 0:
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
