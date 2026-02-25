import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/user.dart';
import 'package:flutter/cupertino.dart';

class UsersList extends StatefulWidget {
  final List<FirefighterUser> usersList;
  final Widget? placeholder;

  const UsersList({super.key, required this.usersList, this.placeholder});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  void onUserTap(FirefighterUser user) async {
    // Si es que queremos revisar detalles del usuario (view details)
    // await Navigator.pushNamed(context, '/user', arguments: user.toJson());
  }

    Future<void> onUpdateRoleButtonTap(FirefighterUser user, bool promote) async {
    // Promote = true or false, Promote o Demote desde Settings
    await Settings.instance.updateUserRole(user.id, promote);
  }

  Widget _buildUserListItem(FirefighterUser user) {
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
            // First row: Role icon, User name, and Action buttons
            Row(
              children: [
                // Role icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getRoleIcon(user.role),
                    color: Settings.instance.colors.textOverPrimary,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                // User name - expanded to take available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
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
                        _getRoleDisplayName(user.role),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Action buttons
                Row(
                  children: [
                    // Promote button (up arrow)
                    CupertinoButton(
                      onPressed: () => onUpdateRoleButtonTap(user, true),
                      padding: EdgeInsets.all(6),
                      minimumSize: Size(0, 0),
                      child: Icon(
                        CupertinoIcons.arrow_up_circle,
                        size: 20,
                        color: Settings.instance.colors.primary,
                      ),
                    ),
                    // Demote button (down arrow)
                    CupertinoButton(
                      onPressed: () => onUpdateRoleButtonTap(user, false),
                      padding: EdgeInsets.all(6),
                      minimumSize: Size(0, 0),
                      child: Icon(
                        CupertinoIcons.arrow_down_circle,
                        size: 20,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // Second row: User ID and additional info
            Row(
              children: [
                // User information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID:',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        user.id,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.label,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.watchedByUserId != null) SizedBox(height: 2),
                      if (user.watchedByUserId != null)
                        Text(
                          'Supervisado por:',
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.tertiaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (user.watchedByUserId != null) SizedBox(height: 2),
                      if (user.watchedByUserId != null)
                        Text(
                          Settings.instance
                              .getUserOrFail(user.watchedByUserId!)
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
                // Role badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleDisplayName(user.role),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getRoleColor(user.role),
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

  Color _getRoleColor(int role) {
    switch (role) {
      case 2: // Supervisor
        return Settings.instance.colors.primary;
      case 1: // Bombero
        return Settings.instance.colors.primaryBright;
      default: // Unknown/other
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getRoleIcon(int role) {
    switch (role) {
      case 2: // Supervisor
        return CupertinoIcons.person_alt_circle;
      case 1: // Bombero
        return CupertinoIcons.person_circle;
      default: // Unknown/other
        return CupertinoIcons.person;
    }
  }

  String _getRoleDisplayName(int role) {
    switch (role) {
      case 2:
        return 'Supervisor';
      case 1:
        return 'Bombero';
      default:
        return 'Usuario';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Settings.instance.colors.background,
      child: widget.usersList.isEmpty
          ? Center(
              child: widget.placeholder ??
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_crop_circle_badge_xmark,
                        size: 64,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sin usuarios',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No hay usuarios bajo tu supervisión',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
            )
          : ListView.builder(
              itemCount: widget.usersList.length,
              itemBuilder: (context, index) {
                return CupertinoButton(
                  onPressed: () => onUserTap(widget.usersList[index]),
                  padding: EdgeInsets.zero,
                  child: _buildUserListItem(widget.usersList[index]),
                );
              },
            ),
    );
  }
}