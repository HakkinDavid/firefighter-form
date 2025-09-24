import 'package:bomberos/models/settings.dart';
import 'package:flutter/cupertino.dart';

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
          color: Settings().colors.primary,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Row(
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
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "AYUNTAMIENTO DE TIJUANA, B.C.",
                          style: TextStyle(
                            color: Settings().colors.textOverPrimary,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "DIRECCIÓN DE BOMBEROS TIJUANA",
                          style: TextStyle(
                            color: Settings().colors.textOverPrimary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "PARTE DE SERVICIO PREHOSPITALARIO",
                          style: TextStyle(
                            color: Settings().colors.textOverPrimary,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.username != null)
                          Text(
                            "Usuario: ${widget.username}",
                            style: TextStyle(
                              color: Settings().colors.textOverPrimary,
                              fontSize: 15,
                            ),
                          ),
                        if (widget.adminUsername != null)
                          Text(
                            "Supervisor: ${widget.adminUsername}",
                            style: TextStyle(
                              color: Settings().colors.textOverPrimary,
                              fontSize: 15,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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
            ),
          ),
        );
      },
    );
  }
}
