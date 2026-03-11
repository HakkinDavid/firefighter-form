import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/user.dart';
import 'package:flutter/cupertino.dart';

typedef UserActionButtonsBuilder =
    List<Widget> Function(BuildContext context, FirefighterUser user);

class UsersList extends StatefulWidget {
  final List<FirefighterUser> usersList;
  final Widget? placeholder;
  final Future<void> Function(FirefighterUser user)? onUserTap;
  final UserActionButtonsBuilder? actionButtonsBuilder;

  const UsersList({
    super.key,
    required this.usersList,
    this.placeholder,
    this.onUserTap,
    this.actionButtonsBuilder,
  });

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  final Map<String, Future<FirefighterUser>> _userFetches = {};

  Future<FirefighterUser> _getUserFuture(String userId) {
    return _userFetches.putIfAbsent(
      userId,
      () => Settings.instance.fetchUser(pUserId: userId),
    );
  }

  Widget _buildWatcherName(String watcherId) {
    final cachedWatcher = Settings.instance.userCache[watcherId];
    if (cachedWatcher != null) {
      return Text(
        cachedWatcher.fullName,
        style: TextStyle(fontSize: 13, color: CupertinoColors.label),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return FutureBuilder<FirefighterUser>(
      future: _getUserFuture(watcherId),
      builder: (context, snapshot) {
        final fullName = snapshot.data?.fullName ?? 'Cargando tutelar...';
        return Text(
          fullName,
          style: TextStyle(fontSize: 13, color: CupertinoColors.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildUserListItem(FirefighterUser user) {
    final actionButtons =
        widget.actionButtonsBuilder?.call(context, user) ?? const <Widget>[];

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
                        user.roleName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionButtons.isNotEmpty) SizedBox(width: 8),
                if (actionButtons.isNotEmpty) Row(children: actionButtons),
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
                          'Tutelado por:',
                          style: TextStyle(
                            fontSize: 11,
                            color: CupertinoColors.tertiaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (user.watchedByUserId != null) SizedBox(height: 2),
                      if (user.watchedByUserId != null)
                        _buildWatcherName(user.watchedByUserId!),
                    ],
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
      case 2: // Administrador
        return Settings.instance.colors.primaryContrastDark;
      case 1: // Supervisor
        return Settings.instance.colors.primary;
      case 0: // Bombero
        return Settings.instance.colors.primaryBright;
      default: // Unknown/other
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getRoleIcon(int role) {
    switch (role) {
      case 2: // Administrador
        return CupertinoIcons.person_3_fill;
      case 1: // Supervisor
        return CupertinoIcons.person_2_fill;
      case 0: // Bombero
        return CupertinoIcons.person_fill;
      default: // Unknown/other
        return CupertinoIcons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Settings.instance.colors.background,
      child: widget.usersList.isEmpty
          ? Center(
              child:
                  widget.placeholder ??
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
                final user = widget.usersList[index];
                if (widget.onUserTap == null) {
                  return _buildUserListItem(user);
                }
                return CupertinoButton(
                  onPressed: () => widget.onUserTap!(user),
                  padding: EdgeInsets.zero,
                  child: _buildUserListItem(user),
                );
              },
            ),
    );
  }
}
