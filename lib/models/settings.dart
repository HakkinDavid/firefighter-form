import 'package:flutter/cupertino.dart';

class Settings {
  static final Settings _instance = Settings._internal();
  
  Settings._internal();

  factory Settings() {
    return _instance;
  }

  Map<String, Color> colors = {
    "primary": Color.from(red: 98/255, green: 19/255, blue: 51/255, alpha: 1.0)
  };
}