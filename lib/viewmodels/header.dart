import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Header extends StatefulWidget {
  final String? username;
  final String? adminUsername;
  const Header({super.key, this.username, this.adminUsername});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxContentWidth = 900;
        final double contentWidth = constraints.maxWidth < maxContentWidth
            ? constraints.maxWidth
            : maxContentWidth;
        return Container(
          color: Settings.instance.colors.primary,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "AYUNTAMIENTO DE TIJUANA, B.C.",
                        style: TextStyle(
                          color: Settings.instance.colors.textOverPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "DIRECCIÓN DE BOMBEROS TIJUANA",
                        style: TextStyle(
                          color: Settings.instance.colors.textOverPrimary,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        flex: 1,
                        child: Image.asset(
                          'assets/tijuana.png',
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "PARTE DE SERVICIO PREHOSPITALARIO",
                              style: TextStyle(
                                color: Settings.instance.colors.textOverPrimary,
                                fontSize: 16,
                                letterSpacing: 0.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.username != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.person_crop_circle,
                                      size: 30,),
                                    padding: EdgeInsets.zero,
                                    color: Settings().colors.primaryContrast,
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      CupertinoIcons.search,
                                      size: 30,
                                    ),
                                    padding: EdgeInsets.zero,
                                    color: Settings().colors.primaryContrast,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              //   Text(
                              //     "Usuario: ${widget.username}",
                              //     style: TextStyle(
                              //       color: Settings.instance.colors.textOverPrimary,
                              //       fontSize: 15,
                              //     ),
                              //     textAlign: TextAlign.center,
                              //   ),
                              // if (widget.adminUsername != null)
                              //   Text(
                              //     "Supervisor: ${widget.adminUsername}",
                              //     style: TextStyle(
                              //       color: Settings.instance.colors.textOverPrimary,
                              //       fontSize: 15,
                              //     ),
                              //   ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        flex: 1,
                        child: Image.asset(
                          'assets/bomberos.png',
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
