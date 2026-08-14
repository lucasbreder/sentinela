import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sentinela/core/app_routes.dart';
import 'package:sentinela/core/service_locator.dart';
import '../../firebase_options.dart';

void removeSplashOverlay() {
  if (!kIsWeb) return;
  try {
    final document = globalContext['document'] as JSObject;
    final splash = document.callMethodVarArgs<JSAny?>(
      'querySelector'.toJS,
      <JSAny?>['#splash'.toJS],
    );
    (splash as JSObject)
        .callMethodVarArgs<JSAny?>('remove'.toJS, const <JSAny?>[]);
  } catch (_) {
    // falha silenciosa: splash já removido ou ausente no host
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => removeSplashOverlay());
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    ServiceLocator.instance.init();

    if (!mounted) return;
    unawaited(Navigator.pushReplacementNamed(context, AppRoutes.login));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF20528B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/sentinela-icon.png',
              width: 120,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
