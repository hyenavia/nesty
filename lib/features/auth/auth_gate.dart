import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shell/app_shell.dart';
import '../onboarding/onboarding_controller.dart';
import '../onboarding/onboarding_screen.dart';
import '../splash/splash_screen.dart';
import 'auth_controller.dart';
import 'auth_screen.dart';

/// Splash -> onboarding (first launch) -> login (if needed) / fallback -> app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _splashTime = Duration(milliseconds: 1900);
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_splashTime, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final onboarding = context.watch<OnboardingController>();

    final Widget child;
    if (!_splashDone || !auth.ready) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!onboarding.done) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else if (!auth.firebaseReady && !auth.isGuest) {
      child = FirebaseMissingPage(
        key: const ValueKey('missing'),
        onContinue: () => auth.continueAsGuest(),
      );
    } else if (auth.needsAuth) {
      child = const AuthScreen(key: ValueKey('auth'));
    } else {
      child = const AppShell(key: ValueKey('app'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: child,
    );
  }
}
