import 'package:bomberos/models/settings.dart';
import 'package:bomberos/viewmodels/overlay_service.dart';
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
  final GlobalKey _buttonKey = GlobalKey();

  void _goToSearch() {
    Navigator.pushNamed(context, '/search');
  }
  void _goBack() {
    Navigator.pop(context);
  }

  void _showUserMenu(BuildContext context, double contentWidth) {
    final RenderBox button = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero);
    final buttonSize = button.size;
    final double overlayWidth = (contentWidth/2) < 300 ? (contentWidth/2) : 300;

    OverlayService.showOverlay(
      context: context,
      position: position,
      buttonSize: buttonSize,
      overlayWidth: overlayWidth,
      overlayContent: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Usuario: ${widget.username}",
              style: TextStyle(
                color: Settings.instance.colors.textOverPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.adminUsername != null)
              Text(
                "Supervisor: ${widget.adminUsername}",
                style: TextStyle(
                  color: Settings.instance.colors.textOverPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

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
                  // The 600 could be a macro in settings. Something like WIDESCREEN
                  if (contentWidth < 600) ...[
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
                  ],
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (contentWidth >= 600) ...[
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
                              const SizedBox(height: 10),
                            ],
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
                                    key: _buttonKey,
                                    icon: const Icon(
                                      CupertinoIcons.person_crop_circle,
                                      size: 30,),
                                    padding: EdgeInsets.zero,
                                    color: Settings().colors.primaryContrast,
                                    onPressed: () => _showUserMenu(context, contentWidth),
                                  ),
                                  const SizedBox(width: 12),
                                  if (currentRoute != '/welcome' && currentRoute != '/')
                                    IconButton(
                                      icon: Icon(
                                        (currentRoute == '/home')
                                            ? CupertinoIcons.search
                                            : CupertinoIcons.arrow_left_circle,
                                        size: 30,
                                      ),
                                      padding: EdgeInsets.zero,
                                      color: Settings().colors.primaryContrast,
                                      onPressed: (currentRoute == '/home')
                                          ? _goToSearch
                                          : _goBack,
                                    ),
                                ],
                              ),
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
