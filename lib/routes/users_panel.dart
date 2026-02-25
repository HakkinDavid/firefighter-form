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
  List<FirefighterUser> _watchedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadWatchedUsers();
  }

  void _loadWatchedUsers() {
    // This should give us our supervisados
    _watchedUsers = Settings.instance.getUserScope();
    
    // Sort by role (Supervisors first, then Bomberos) and then by name
    // Could be an option to toggle later maybe
    _watchedUsers.sort((a, b) {
      if (a.role != b.role) {
        return b.role.compareTo(a.role); // Higher role first (2 > 1)
      }
      return a.fullName.compareTo(b.fullName);
    });
  }

  @override
  void dispose() {
    super.dispose();
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
                child: UsersList(
                  usersList: _watchedUsers,
                  // users_list se encarga de mostrar si hay o no watchedUsers
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}