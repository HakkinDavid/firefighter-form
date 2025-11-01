import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';

class FormList extends StatefulWidget {
  final List<ServiceForm> formsList;
  final Widget? placeholder;

  const FormList({super.key, required this.formsList, this.placeholder});

  @override
  State<FormList> createState() => _FormListState();
}

class _FormListState extends State<FormList> {
  void onFormTap(ServiceForm form) async {
    await Navigator.pushNamed(context, '/form', arguments: form.toJson());
  }

  void onPdfTap(ServiceForm form) async {
    await form.render();
  }

  void onDeleteTap(ServiceForm form) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Eliminar formulario'),
        message: Text(
          '¿Estás seguro de que deseas eliminar el folio ${form.statusName.toLowerCase()} "${form.id}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              deleteForm(form);
            },
            isDestructiveAction: true,
            child: Text('Eliminar folio ${form.statusName.toLowerCase()}'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void deleteForm(ServiceForm form) async {
    await form.delete();
  }

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
                    color: form.statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    form.statusIcon,
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
                    if (form.status >= 1)
                      // PDF button
                      CupertinoButton(
                        onPressed: () => onPdfTap(form),
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
                        onPressed: () => onDeleteTap(form),
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
                      if (form.tags.isNotEmpty) SizedBox(height: 2),
                      Text(
                        'Etiquetas:',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        form.tags.join(", "),
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
                    color: form.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    form.statusName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: form.statusColor,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Settings.instance.colors.background,
      child: widget.formsList.isEmpty
          ? Center(
              child: widget.placeholder
            )
          : ListView.builder(
              itemCount: widget.formsList.length,
              itemBuilder: (context, index) {
                return CupertinoButton(
                  onPressed: () => onFormTap(widget.formsList[index]),
                  padding: EdgeInsets.zero,
                  child: _buildFormListItem(widget.formsList[index]),
                );
              },
            ),
    );
  }
}
