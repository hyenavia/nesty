import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/core/sync/sync_service.dart';
import 'package:nesty/features/auth/auth_controller.dart';
import 'package:nesty/features/bills/data/bills_controller.dart';
import 'package:nesty/features/gallon/data/gallon_controller.dart';
import 'package:nesty/features/laundry/data/laundry_controller.dart';
import 'package:nesty/features/profile/profile_controller.dart';
import 'package:nesty/features/routine/data/routines_controller.dart';
import 'package:nesty/features/supplies/data/supplies_controller.dart';
import 'package:nesty/features/token/data/token_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SyncService snapshot contains all 6 modules and profile', () async {
    final prefs = await SharedPreferences.getInstance();

    final auth = AuthController(prefs, firebaseReady: false);
    final profile = ProfileController(prefs, auth: auth);
    final supplies = SuppliesController(prefs);
    final routines = RoutinesController(prefs);
    final token = TokenController(prefs);
    final gallon = GallonController(prefs);
    final laundry = LaundryController(prefs);
    final bills = BillsController(prefs);

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

    final snap = sync.snapshot();
    expect(snap['app'], 'nesty');
    expect(snap['version'], 1);
    expect(snap.containsKey('supplies'), isTrue);
    expect(snap.containsKey('routines'), isTrue);
    expect(snap.containsKey('token'), isTrue);
    expect(snap.containsKey('gallon'), isTrue);
    expect(snap.containsKey('laundry'), isTrue);
    expect(snap.containsKey('bills'), isTrue);
    expect(snap.containsKey('profile'), isTrue);

    // Verify it converts to JSON string without error
    final encoded = jsonEncode(snap);
    expect(encoded.isNotEmpty, isTrue);
  });
}

