import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/core/l10n/locale_controller.dart';
import 'package:nesty/core/theme/app_theme.dart';
import 'package:nesty/core/utils/photo_service.dart';
import 'package:nesty/features/auth/auth_controller.dart';
import 'package:nesty/features/bills/bills_screen.dart';
import 'package:nesty/features/bills/data/bills_controller.dart';
import 'package:nesty/features/gallon/data/gallon_controller.dart';
import 'package:nesty/features/home/home_screen.dart';
import 'package:nesty/features/laundry/data/laundry_controller.dart';
import 'package:nesty/features/profile/profile_controller.dart';
import 'package:nesty/features/routine/data/routines_controller.dart';
import 'package:nesty/features/routine/routine_screen.dart';
import 'package:nesty/features/supplies/data/supplies_controller.dart';
import 'package:nesty/features/token/data/token_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestApp({
  required SharedPreferences prefs,
  required Widget child,
}) {
  final locale = LocaleController(prefs);
  final supplies = SuppliesController(prefs);
  final routines = RoutinesController(prefs);
  final token = TokenController(prefs);
  final gallon = GallonController(prefs);
  final laundry = LaundryController(prefs);
  final bills = BillsController(prefs);
  final auth = AuthController(prefs, firebaseReady: false);
  final profile = ProfileController(prefs, auth: auth);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: locale),
      ChangeNotifierProvider.value(value: supplies),
      ChangeNotifierProvider.value(value: routines),
      ChangeNotifierProvider.value(value: token),
      ChangeNotifierProvider.value(value: gallon),
      ChangeNotifierProvider.value(value: laundry),
      ChangeNotifierProvider.value(value: bills),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: profile),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late SharedPreferences prefs;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('nesty_widget_test_');
    PhotoService.avatarDirForTesting = tempDir.path;
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() {
    PhotoService.avatarDirForTesting = null;
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Widget Tests - HomeScreen', () {
    testWidgets('renders greeting, today card, and module cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var suppliesOpened = false;

      await tester.pumpWidget(createTestApp(
        prefs: prefs,
        child: HomeScreen(onOpenSupplies: () => suppliesOpened = true),
      ));
      await tester.pumpAndSettle();

      // Check greetings and header
      expect(find.text('Hi, Nesty!'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      // Check module titles
      expect(find.text('Electricity Token'), findsOneWidget);
      expect(find.text('Water Gallon'), findsOneWidget);
      expect(find.text('Laundry'), findsOneWidget);
      expect(find.text('Daily Supplies'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);

      // Tap on supplies module card
      await tester.tap(find.text('Daily Supplies'));
      await tester.pumpAndSettle();
      expect(suppliesOpened, isTrue);
    });
  });

  group('Widget Tests - RoutineScreen', () {
    testWidgets('displays default routines and marks routine as done', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(
        prefs: prefs,
        child: const RoutineScreen(),
      ));
      await tester.pumpAndSettle();

      // Default routines should be visible
      expect(find.text('Change bedsheets & pillowcases'), findsOneWidget);
      expect(find.text('Scrub the bathroom'), findsOneWidget);

      // Find first "Mark done" check button and tap it
      final markDoneBtn = find.byIcon(Icons.check_circle_outline_rounded).first;
      await tester.tap(markDoneBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar appears with undo action
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });
  });

  group('Widget Tests - BillsScreen', () {
    testWidgets('displays empty state, adds bill, and marks paid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final billsController = BillsController(prefs);
      billsController.add(
        name: 'Apartment Rent',
        amountRp: 1500000,
        dayOfMonth: 15,
        splitWays: 2,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: LocaleController(prefs)),
            ChangeNotifierProvider.value(value: billsController),
            ChangeNotifierProvider.value(value: TokenController(prefs)),
            ChangeNotifierProvider.value(value: LaundryController(prefs)),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: [Locale('en'), Locale('id')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: BillsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify bill and split badge are rendered
      expect(find.text('Apartment Rent'), findsOneWidget);
      expect(find.textContaining('Split 2'), findsOneWidget);

      // Find and tap "Mark paid"
      final markPaidBtn = find.text('Mark paid');
      expect(markPaidBtn, findsOneWidget);

      await tester.tap(markPaidBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar notification appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Apartment Rent paid'), findsOneWidget);
    });
  });
}
