import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';

class Header extends CupertinoNavigationBar {
  final String? name;
  const Header({super.key, this.name});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build (BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: Settings().colors.primary,
      middle: Text("Aplicación de Atención Prehospitalaria y Servicios Digitales para Bomberos",
        style: TextStyle(
          color: Settings().colors.textOverPrimary,
        ),
        textAlign: TextAlign.center
      ),
    );
  }
}