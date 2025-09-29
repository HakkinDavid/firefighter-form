import 'package:bomberos/models/user.dart';
import 'package:flutter/cupertino.dart';

class ColorsSettings {
  final Color primary = Color.fromRGBO(98, 19, 51, 1.0);
  final Color background = CupertinoColors.white;
  final Color primaryContrast = Color.fromRGBO(231, 210, 149, 1.0);
  final Color textOverPrimary = CupertinoColors.white;
}

class Settings {
  static final Settings _instance = Settings._internal();

  Settings._internal();

  factory Settings() {
    return _instance;
  }

  final ColorsSettings colors = ColorsSettings();

  User? user;

  bool get isLoggedIn => user != null;
}