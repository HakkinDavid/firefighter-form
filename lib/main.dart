import 'package:bomberos/models/form.dart';
import 'package:bomberos/models/settings.dart';
import 'package:bomberos/models/SRE/service_reliability_engineer.dart';
import 'package:bomberos/routes/console.dart';
import 'package:bomberos/routes/form.dart';
import 'package:bomberos/routes/home.dart';
import 'package:bomberos/routes/maker.dart';
import 'package:bomberos/routes/preferences.dart';
import 'package:bomberos/routes/search.dart';
import 'package:bomberos/routes/statistics.dart';
import 'package:bomberos/routes/users_panel.dart';
import 'package:bomberos/routes/welcome.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: DatabaseSettings.url,
    anonKey: DatabaseSettings.anonKey,
  );
  ServiceReliabilityEngineer.instance.initialize();
  await ServiceReliabilityEngineer.instance.fetchAppVersion();
  runApp(BomberosApp());
}

class BomberosApp extends StatelessWidget {
  const BomberosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      navigatorKey: Settings.instance.navigatorKey,
      title: 'Servicios Digitales para Bomberos',
      theme: CupertinoThemeData(
        primaryColor: Settings.instance.colors.primary,
        primaryContrastingColor: Settings.instance.colors.primaryContrast,
        textTheme: CupertinoTextThemeData(
          primaryColor: CupertinoColors.black,
          pickerTextStyle: TextStyle(
            color: CupertinoColors.white,
            fontSize: 24,
          ),
          dateTimePickerTextStyle: TextStyle(
            color: CupertinoColors.white,
            fontSize: 24,
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        final arguments = settings.arguments as Map<String, dynamic>?;
        return CupertinoPageRoute(
          builder: (context) {
            switch (settings.name) {
              case '/form':
                if (arguments == null ||
                    arguments['template_id'] == null ||
                    arguments['filler'] == null ||
                    arguments['filled_at'] == null ||
                    arguments['content'] == null ||
                    arguments['status'] == null) {
                  return const Home();
                }
                return DynamicFormPage(form: ServiceForm.fromJson(arguments));
              case '/home':
                return const Home();
              case '/search':
                return const Search();
              case '/preferences':
                return const Preferences();
              case '/console':
                return const Console();
              case '/maker':
                return const ServiceTemplateMaker();
              case '/users_panel':
                return const UsersPanel();
              case '/statistics':
                return const StatisticsPanel();
              case '/':
              case '/welcome':
              default:
                return const Welcome();
            }
          },
          settings: settings,
        );
      },
    );
  }
}
