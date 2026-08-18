import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/pages/create_sentinel_registry_page.dart';
import 'package:sentinela/pages/create_units_page.dart';
import 'package:sentinela/pages/driver_lookup_page.dart';
import 'package:sentinela/pages/nav_page.dart';
import 'package:sentinela/pages/profile_page.dart';
import 'package:sentinela/pages/report_page.dart';
import 'package:sentinela/pages/signin_page.dart';
import 'package:sentinela/pages/units_page.dart';
import 'package:sentinela/widgets/login/login.dart';
import 'package:sentinela/widgets/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinela',
      initialRoute: AppRoutes.splash,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        fontFamily: 'Monda',
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
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF72203B),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF20528B),
          onSecondary: Color(0xFF707070),
          error: Color(0xFFB54022),
          onError: Color(0xFF707070),
          surface: Color(0xFFE6E6E6),
          onSurface: Color(0xFF707070),
        ),
      ),
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const Login(),
        AppRoutes.units: (context) => const UnitsPage(),
        AppRoutes.signin: (context) => const SignInPage(),
        AppRoutes.createUnit: (context) => const CreateUnitsPage(),
        AppRoutes.createCarRegistry: (context) => const CreateSentinelRegistryPage(),
        AppRoutes.nav: (context) => const NavPage(),
        AppRoutes.report: (context) => const ReportPage(),
        AppRoutes.driverLookup: (context) => const DriverLookupPage(),
        AppRoutes.profile: (context) => const ProfilePage(),
      },
    );
  }
}
