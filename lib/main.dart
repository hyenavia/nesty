import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/l10n/locale_controller.dart';
import 'core/notifications/reminder_controller.dart';
import 'core/sync/sync_service.dart';
import 'core/update/update_checker.dart';
import 'core/utils/photo_service.dart';
import 'features/auth/auth_controller.dart';
import 'features/bills/data/bills_controller.dart';
import 'features/gallon/data/gallon_controller.dart';
import 'features/laundry/data/laundry_controller.dart';
import 'features/onboarding/onboarding_controller.dart';
import 'features/profile/profile_controller.dart';
import 'features/routine/data/routines_controller.dart';
import 'features/supplies/data/supplies_controller.dart';
import 'features/token/data/token_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await initializeDateFormatting();
  await PhotoService.init();

  // If Firebase is not configured yet, the app still works locally.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase not configured, running local-only: $e');
  }

  final locale = LocaleController(prefs);
  final supplies = SuppliesController(prefs);
  final routines = RoutinesController(prefs);
  final token = TokenController(prefs);
  final gallon = GallonController(prefs);
  final laundry = LaundryController(prefs);
  final bills = BillsController(prefs);
  final onboarding = OnboardingController(prefs);
  final auth = AuthController(prefs, firebaseReady: firebaseReady);
  final profile = ProfileController(prefs, auth: auth);
  final sync = SyncService(
    prefs,
    supplies: supplies,
    routines: routines,
    token: token,
    gallon: gallon,
    laundry: laundry,
    bills: bills,
    profile: profile,
    auth: auth,
  );
  final reminders = ReminderController(
    prefs,
    routines: routines,
    gallon: gallon,
    token: token,
    laundry: laundry,
    bills: bills,
    locale: locale,
  );
  await reminders.init();

  final update = UpdateController();
  // Silently check for GitHub releases in the background
  update.checkSilently();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider.value(value: supplies),
        ChangeNotifierProvider.value(value: routines),
        ChangeNotifierProvider.value(value: token),
        ChangeNotifierProvider.value(value: gallon),
        ChangeNotifierProvider.value(value: laundry),
        ChangeNotifierProvider.value(value: bills),
        ChangeNotifierProvider.value(value: onboarding),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: profile),
        ChangeNotifierProvider.value(value: sync),
        ChangeNotifierProvider.value(value: reminders),
        ChangeNotifierProvider.value(value: update),
      ],
      child: const NestyApp(),
    ),
  );
}
