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
  @override
  void initState() {
    super.initState();
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
                child: StreamBuilder<Map<String, FirefighterUser>>(
                  stream: Settings.instance.userCacheStream,
                  initialData: Settings.instance.userCache,
                  builder: (context, snapshot) {
                    final userScope = (snapshot.data ?? {}).values.toList();
                    userScope.sort((a, b) {
                      if (a.role != b.role) {
                        return b.role.compareTo(a.role);
                      }
                      return a.fullName.compareTo(b.fullName);
                    });
                    return UsersList(usersList: userScope);
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
