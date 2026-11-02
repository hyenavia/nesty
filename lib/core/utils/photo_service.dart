import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Receipt photos and user avatars live in the app's documents folder.
/// This prevents heavy binary / Base64 data from bloating SharedPreferences.
class PhotoService {
  PhotoService._();
  static String? _dir;
  static String? _avatarDir;
  static final _picker = ImagePicker();

  @visibleForTesting
  static set avatarDirForTesting(String? dir) => _avatarDir = dir;

  static Future<void> init() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final folder = Directory('${base.path}/laundry');
      if (!folder.existsSync()) folder.createSync(recursive: true);
      _dir = folder.path;

      final avatarFolder = Directory('${base.path}/avatars');
      if (!avatarFolder.existsSync()) avatarFolder.createSync(recursive: true);
      _avatarDir = avatarFolder.path;
    } catch (e) {
      debugPrint('[PhotoService] init note: $e');
    }
  }

  static File fileFor(String name) => File('${_dir ?? ''}/$name');

  static File? avatarFile(String id) {
    if (_avatarDir == null) return null;
    return File('$_avatarDir/$id.jpg');
  }

  static Future<void> saveAvatar(String id, Uint8List bytes) async {
    saveAvatarSync(id, bytes);
  }

  static void saveAvatarSync(String id, Uint8List bytes) {
    try {
      final f = avatarFile(id);
      if (f != null) {
        f.writeAsBytesSync(bytes, flush: true);
      }
    } catch (e) {
      debugPrint('[PhotoService] saveAvatar error: $e');
    }
  }

  static Uint8List? loadAvatar(String id) {
    try {
      final f = avatarFile(id);
      if (f != null && f.existsSync()) {
        return f.readAsBytesSync();
      }
    } catch (e) {
      debugPrint('[PhotoService] loadAvatar error: $e');
    }
    return null;
  }

  static void deleteAvatar(String id) {
    try {
      final f = avatarFile(id);
      if (f != null && f.existsSync()) {
        f.deleteSync();
      }
    } catch (e) {
      debugPrint('[PhotoService] Failed to delete avatar: $e');
    }
  }

  /// Returns the saved file name, or null if cancelled / failed.
  static Future<String?> pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 80);
      if (x == null) return null;
      final name = '${const Uuid().v4()}.jpg';
      if (_dir != null) {
        await File(x.path).copy('$_dir/$name');
      }
      return name;
    } catch (e) {
      debugPrint('[PhotoService] Failed to pick/save image: $e');
      return null;
    }
  }
}
