import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/user.dart';
import 'package:bomberos/viewmodels/header.dart';
import 'package:bomberos/viewmodels/users_list.dart';
import 'package:flutter/cupertino.dart';

class UsersPanel extends StatefulWidget {
  const UsersPanel({super.key});

  @override
  State<UsersPanel> createState() => _UsersPanelState();
}

class _UsersPanelState extends State<UsersPanel> {
  List<FirefighterUser> _sortedUsers(Iterable<FirefighterUser> users) {
    final sorted = users.toList();
    sorted.sort((a, b) {
      if (a.role != b.role) {
        return b.role.compareTo(a.role);
      }
      return a.fullName.compareTo(b.fullName);
    });
    return sorted;
  }

  Future<void> _onUpdateRoleButtonTap(
    FirefighterUser user,
    bool promote,
  ) async {
    await Settings.instance.setUserRole(
      user.id,
      user.role + (promote ? 1 : -1),
    );
  }

  List<Widget> _buildRoleActionButtons(FirefighterUser user) {
    if (!(Settings.instance.self?.hasAdministratorRights ?? false)) {
      return const <Widget>[];
    }

    final actions = <Widget>[];
    if (!user.isExclusivelyAdministrator) {
      actions.add(
        CupertinoButton(
          onPressed: () => _onUpdateRoleButtonTap(user, true),
          padding: EdgeInsets.all(6),
          minimumSize: Size(0, 0),
          child: Icon(
            CupertinoIcons.arrow_up_circle,
            size: 28,
            color: Settings.instance.colors.primaryBright,
          ),
        ),
      );
    }

    if (!user.isExclusivelyFirefighter) {
      actions.add(
        CupertinoButton(
          onPressed: () => _onUpdateRoleButtonTap(user, false),
          padding: EdgeInsets.all(6),
          minimumSize: Size(0, 0),
          child: Icon(
            CupertinoIcons.arrow_down_circle,
            size: 28,
            color: Settings.instance.colors.primaryContrastDark,
          ),
        ),
      );
    }

    return actions;
  }

  Future<void> _showNoCandidatesAlert(String title, String message) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddWatchedPicker(
    FirefighterUser user,
    Map<String, FirefighterUser> usersMap,
  ) async {
    final candidates = _sortedUsers(
      usersMap.values.where(
        (candidate) =>
            candidate.id != user.id &&
            !user.watchesUsersId.contains(candidate.id),
      ),
    );

    if (candidates.isEmpty) {
      await _showNoCandidatesAlert(
        'Sin candidatos',
        'No hay usuarios disponibles para agregar como tutelados.',
      );
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Agregar tutelado'),
        message: Text(
          'Selecciona un usuario para tutelarlo con ${user.fullName}.',
        ),
        actions: [
          for (final candidate in candidates)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await Settings.instance.setUserHierarchy(candidate.id, user.id);
              },
              child: Text(candidate.fullName),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _showReplaceWatcherPicker(
    FirefighterUser user,
    Map<String, FirefighterUser> usersMap,
  ) async {
    final candidates = _sortedUsers(
      usersMap.values.where(
        (candidate) =>
            candidate.id != user.id && candidate.id != user.watchedByUserId,
      ),
    );

    if (candidates.isEmpty) {
      await _showNoCandidatesAlert(
        'Sin candidatos',
        'No hay usuarios disponibles para asignar como tutelar.',
      );
      return;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Cambiar tutelar'),
        message: Text('Selecciona quién tutelará a ${user.fullName}.'),
        actions: [
          for (final candidate in candidates)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await Settings.instance.setUserHierarchy(user.id, candidate.id);
              },
              child: Text(candidate.fullName),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  Future<void> _onUserTap(FirefighterUser user) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.86,
          color: Settings.instance.colors.background,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jerarquía de usuario',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      minimumSize: Size(0, 0),
                      child: Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: CupertinoColors.systemGrey,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<Map<String, FirefighterUser>>(
                  stream: Settings.instance.userCacheStream,
                  initialData: Settings.instance.userCache,
                  builder: (context, snapshot) {
                    final usersMap = snapshot.data ?? {};
                    final liveUser = usersMap[user.id] ?? user;

                    final watchedUsers = _sortedUsers(
                      liveUser.watchesUsersId
                          .map((id) => usersMap[id])
                          .whereType<FirefighterUser>(),
                    );

                    final watcher = liveUser.watchedByUserId == null
                        ? null
                        : usersMap[liveUser.watchedByUserId!];

                    return Padding(
                      padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tutelados',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              CupertinoButton(
                                onPressed: () =>
                                    _showAddWatchedPicker(liveUser, usersMap),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                minimumSize: Size(0, 0),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.add_circled,
                                      size: 18,
                                      color: Settings.instance.colors.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Agregar',
                                      style: TextStyle(
                                        color: Settings.instance.colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: CupertinoColors.separator,
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: UsersList(
                                usersList: watchedUsers,
                                onUserTap: null,
                                actionButtonsBuilder: (context, watchedUser) =>
                                    [
                                      CupertinoButton(
                                        onPressed: () =>
                                            Settings.instance.setUserHierarchy(
                                              watchedUser.id,
                                              null,
                                            ),
                                        padding: EdgeInsets.all(6),
                                        minimumSize: Size(0, 0),
                                        child: Icon(
                                          CupertinoIcons.trash,
                                          size: 20,
                                          color: CupertinoColors.systemRed,
                                        ),
                                      ),
                                    ],
                                placeholder: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.person_2,
                                      size: 40,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sin tutelados asignados',
                                      style: TextStyle(
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tutelar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            height: 140,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: CupertinoColors.separator,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: watcher == null
                                ? Center(
                                    child: CupertinoButton(
                                      onPressed: () =>
                                          _showReplaceWatcherPicker(
                                            liveUser,
                                            usersMap,
                                          ),
                                      child: Text('Asignar tutelar'),
                                    ),
                                  )
                                : UsersList(
                                    usersList: [watcher],
                                    onUserTap: null,
                                    actionButtonsBuilder:
                                        (context, watchedBy) => [
                                          CupertinoButton(
                                            onPressed: () => Settings.instance
                                                .setUserHierarchy(
                                                  liveUser.id,
                                                  null,
                                                ),
                                            padding: EdgeInsets.all(6),
                                            minimumSize: Size(0, 0),
                                            child: Icon(
                                              CupertinoIcons
                                                  .clear_circled_solid,
                                              size: 20,
                                              color: CupertinoColors.systemRed,
                                            ),
                                          ),
                                          CupertinoButton(
                                            onPressed: () =>
                                                _showReplaceWatcherPicker(
                                                  liveUser,
                                                  usersMap,
                                                ),
                                            padding: EdgeInsets.all(6),
                                            minimumSize: Size(0, 0),
                                            child: Icon(
                                              CupertinoIcons.pencil_circle,
                                              size: 20,
                                              color: Settings
                                                  .instance
                                                  .colors
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: null,
      backgroundColor: Settings.instance.colors.primaryContrast,
      child: SafeArea(
        child: Column(
          children: [
            Header(
              username: Settings.instance.self?.fullName,
              adminUsername: Settings.instance.watcher?.fullName,
              versionString: ServiceReliabilityEngineer.appVersion,
            ),
            Expanded(
              child: Container(
                color: Settings.instance.colors.background,
                child: StreamBuilder<Map<String, FirefighterUser>>(
                  stream: Settings.instance.userCacheStream,
                  initialData: Settings.instance.userCache,
                  builder: (context, snapshot) {
                    final userScope = _sortedUsers(
                      (snapshot.data ?? {}).values,
                    );
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Usuarios',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Settings.instance.colors.primary,
                                ),
                              ),
                              Text(
                                '${userScope.length} elementos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: UsersList(
                            usersList: userScope,
                            onUserTap: _onUserTap,
                            actionButtonsBuilder: (context, user) =>
                                _buildRoleActionButtons(user),
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
      ),
    );
  }
}
