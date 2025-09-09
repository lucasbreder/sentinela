import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:localization/localization.dart';
import 'package:sentinela/pages/create_sentinel_registry_page.dart';
import 'package:sentinela/pages/create_units_page.dart';
import 'package:sentinela/pages/nav_page.dart';
import 'package:sentinela/pages/profile_page.dart';
import 'package:sentinela/pages/report_page.dart';
import 'package:sentinela/pages/signin_page.dart';
import 'package:sentinela/pages/units_page.dart';
import 'package:sentinela/widgets/login/login.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    LocalJsonLocalization.delegate.directories = ['lib/i18n'];

    return MaterialApp(
      title: 'Sentinela',
      localizationsDelegates: [
        // delegate from flutter_localization
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // delegate from localization package.
        LocalJsonLocalization.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        fontFamily: 'Monda',
        primaryColor: const Color.fromARGB(255, 114, 32, 59),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(
            color: Color.fromARGB(255, 112, 112, 112),
            fontSize: 18,
          ),
          contentPadding: EdgeInsets.all(10),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 112, 112, 112),
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(255, 112, 112, 112),
            ),
          ),
        ),
        textTheme: const TextTheme(), colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color.fromARGB(255, 114, 32, 59),
          onPrimary: Color.fromARGB(255, 255, 255, 255),
          secondary: Color.fromARGB(255, 32, 82, 139),
          onSecondary: Color.fromARGB(255, 112, 112, 112),
          error: Color.fromARGB(255, 181, 64, 34),
          onError: Color.fromARGB(255, 112, 112, 112),
          surface: Color.fromARGB(255, 230, 230, 230),
          onSurface: Color.fromARGB(255, 112, 112, 112),
        )
      ),
      routes: {
        '/': (context) => const Login(),
        '/units': (context) => const UnitsPage(),
        '/signin': (context) => const SignInPage(),
        '/createUnit': (context) => const CreateUnitsPage(),
        '/createCarRegistry': (context) => const CreateSentinelRegistryPage(),
        '/nav': (context) => const NavPage(),
        '/report': (context) => const ReportPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
