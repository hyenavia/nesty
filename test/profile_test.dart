import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nesty/core/utils/photo_service.dart';
import 'package:nesty/features/auth/auth_controller.dart';
import 'package:nesty/features/profile/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nesty_avatar_test_');
    PhotoService.avatarDirForTesting = tempDir.path;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    PhotoService.avatarDirForTesting = null;
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('PhotoService disk storage', () {
    test('save, load, and delete avatar', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await PhotoService.saveAvatar('user_1', sampleBytes);

      final loaded = PhotoService.loadAvatar('user_1');
      expect(loaded, isNotNull);
      expect(loaded, equals(sampleBytes));

      PhotoService.deleteAvatar('user_1');
      expect(PhotoService.loadAvatar('user_1'), isNull);
    });
  });

  group('ProfileController storage optimization', () {
    test('migrates legacy base64 from SharedPreferences to disk', () async {
      final sampleBytes = Uint8List.fromList([10, 20, 30, 40]);
      final b64 = base64Encode(sampleBytes);

      // Seed mock SharedPreferences with legacy base64 string
      SharedPreferences.setMockInitialValues({
        'guest_nickname': 'GuestUser',
        'guest_photo': b64,
      });

      final prefs = await SharedPreferences.getInstance();
      final auth = AuthController(prefs, firebaseReady: false);
      final profile = ProfileController(prefs, auth: auth);

      expect(profile.nickname, 'GuestUser');
      expect(profile.photo, equals(sampleBytes));

      // SharedPreferences should have been cleaned up of heavy base64
      expect(prefs.containsKey('guest_photo'), isFalse);

      // Disk file should now exist
      final diskAvatar = PhotoService.loadAvatar('guest');
      expect(diskAvatar, equals(sampleBytes));
    });

    test('loadJson saves avatar to disk without keeping base64 in prefs', () async {
      final sampleBytes = Uint8List.fromList([7, 8, 9]);
      final b64 = base64Encode(sampleBytes);

      final prefs = await SharedPreferences.getInstance();
      final auth = AuthController(prefs, firebaseReady: false);
      final profile = ProfileController(prefs, auth: auth);

      profile.loadJson({
        'nickname': 'CloudUser',
        'photo': b64,
        'updatedAt': 12345,
      });

      expect(profile.nickname, 'CloudUser');
      expect(profile.photo, equals(sampleBytes));
      expect(prefs.containsKey('guest_photo'), isFalse);

      // Verify toJson still produces base64 for cloud sync
      final json = profile.toJson();
      expect(json['photo'], b64);
      expect(json['nickname'], 'CloudUser');
    });
  });
}
