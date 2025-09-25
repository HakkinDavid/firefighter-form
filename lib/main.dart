import 'package:bomberos/models/settings.dart';
import 'package:bomberos/routes/form.dart';
import 'package:bomberos/routes/home.dart';
import 'package:bomberos/routes/welcome.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://gpmonaitogjvxrfznhef.supabase.co';
const supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbW9uYWl0b2dqdnhyZnpuaGVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NjQxNTksImV4cCI6MjA3NDM0MDE1OX0.-udPuvfzbJ1SKdP-QcBt_NTlpU720P-hdBGm_n0kE7I";

Future<void> main() async {
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(BomberosApp());
}

class BomberosApp extends StatelessWidget {
  const BomberosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Servicios Digitales para Bomberos',
      theme: CupertinoThemeData(
        primaryColor: Settings().colors.primary
      ),
      onGenerateRoute: (settings) {
        return CupertinoPageRoute(
              builder: (context) {
                switch (settings.name) {
                  case '/form':
                    return DynamicFormPage();
                  case '/home':
                    return const Home();
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