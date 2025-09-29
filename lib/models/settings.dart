import 'package:bomberos/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ColorsSettings {
  final Color primary = Color.fromRGBO(98, 19, 51, 1.0);
  final Color background = CupertinoColors.white;
  final Color primaryContrast = Color.fromRGBO(231, 210, 149, 1.0);
  final Color textOverPrimary = CupertinoColors.white;
}

class Settings {
  static final Settings instance = Settings._internal();

  Settings._internal();

  factory Settings() {
    return instance;
  }

  final ColorsSettings colors = ColorsSettings();

  String? userId;

  Map<String, FirefighterUser> userCache = {};

  bool get isLoggedIn => userId != null && userCache.containsKey(userId);

  FirefighterUser? get self => userCache[userId];
  FirefighterUser? get watcher => userCache[self?.watchedByUserId ?? ""];

  Future<FirefighterUser> getUser({String? pUserId}) async {
    pUserId ??= userId!;
    if (userCache.containsKey(pUserId)) return userCache[pUserId]!;
    final nameRecord = await Supabase.instance.client
        .from('user_name')
        .select('id, given, surname1, surname2')
        .eq('id', pUserId)
        .maybeSingle();

    final roleRecord = await Supabase.instance.client
        .from('user_role')
        .select('id, value')
        .eq('id', pUserId)
        .maybeSingle();

    final watchedByRecord = await Supabase.instance.client
        .from('user_hierarchy')
        .select('id, watched_by')
        .eq('id', pUserId)
        .maybeSingle();

    final watchesRecord = await Supabase.instance.client
        .from('user_hierarchy')
        .select('id')
        .eq('watched_by', pUserId);

    Set<String> watchesUsersId = {};

    for (var w in watchesRecord) {
      watchesUsersId.add(w['id']);
    }

    if (nameRecord == null || roleRecord == null) throw Error();

    final user = FirefighterUser(
      id: pUserId,
      givenName: nameRecord['given'],
      firstSurname: nameRecord['surname1'],
      secondSurname: nameRecord['surname2'],
      role: roleRecord['value'],
      watchedByUserId: watchedByRecord?['watched_by'],
      watchesUsersId: watchesUsersId,
    );

    userCache[pUserId] = user;

    return user;
  }
}
