import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/core/l10n/locale_controller.dart';
import 'package:nesty/core/notifications/reminder_controller.dart';
import 'package:nesty/core/theme/app_colors.dart';
import 'package:nesty/features/auth/auth_controller.dart';
import 'package:nesty/features/bills/data/bills_controller.dart';
import 'package:nesty/features/gallon/data/gallon_controller.dart';
import 'package:nesty/features/laundry/data/laundry_controller.dart';
import 'package:nesty/features/routine/data/routines_controller.dart';
import 'package:nesty/features/token/data/token_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme Palette Tokens Tests', () {
    test('brand colors provide comfortable warm cream and espresso values', () {
      expect(AppColors.cream, const Color(0xFFFFF7EC));
      expect(AppColors.surface, const Color(0xFFFFFCF7));
      expect(AppColors.brown, const Color(0xFF62504A));
      expect(AppColors.peachDeep, const Color(0xFFF2A07F));
      expect(AppColors.safe, const Color(0xFF6FBF8A));
      expect(AppColors.out, const Color(0xFFE5675D));
    });
  });

  group('ReminderController Weekly Digest & Actionable Reminders Tests', () {
    test('weekly digest defaults to enabled and can be toggled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final locale = LocaleController(prefs);
      final routines = RoutinesController(prefs);
      final gallon = GallonController(prefs);
      final token = TokenController(prefs);
      final laundry = LaundryController(prefs);
      final bills = BillsController(prefs);

      final rem = ReminderController(
        prefs,
        routines: routines,
        gallon: gallon,
        token: token,
        laundry: laundry,
        bills: bills,
        locale: locale,
      );

      expect(rem.weeklyDigestEnabled, isTrue);

      await rem.setWeeklyDigestEnabled(false);
      expect(rem.weeklyDigestEnabled, isFalse);
      expect(prefs.getBool('notif_weekly_digest'), isFalse);

      await rem.setWeeklyDigestEnabled(true);
      expect(rem.weeklyDigestEnabled, isTrue);
    });
  });

  group('AuthController & Account Lifecycle Tests', () {
    test('username and email validation behave accurately', () {
      expect(AuthController.isValidUsername('budi'), isTrue);
      expect(AuthController.isValidUsername('budi_123'), isTrue);
      expect(AuthController.isValidUsername('budi.nest'), isTrue);
      expect(AuthController.isValidUsername('ab'), isFalse); // too short (<3)
      expect(AuthController.isValidUsername('a' * 21), isFalse); // too long (>20)
      expect(AuthController.isValidUsername('budi@123'), isFalse); // invalid character

      expect(AuthController.isValidEmail('user@test.com'), isTrue);
      expect(AuthController.isValidEmail('user.name@domain.co.id'), isTrue);
      expect(AuthController.isValidEmail('invalid-email'), isFalse);
      expect(AuthController.isValidEmail('@domain.com'), isFalse);
    });

    test('AuthController initializes with mock preferences in guest mode', () async {
      SharedPreferences.setMockInitialValues({
        'cached_username': 'cozy_nester',
        'guest_mode': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final auth = AuthController(prefs, firebaseReady: false);

      expect(auth.isGuest, isTrue);
      expect(auth.username, 'cozy_nester');
      expect(auth.needsAuth, isFalse);

      await auth.exitGuest();
      expect(auth.isGuest, isFalse);
    });
  });
}
