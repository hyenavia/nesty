import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Receipt photos live in the app's documents folder. Only the file NAME is
/// stored in the data, so the path keeps working even if the OS moves the
/// app container. Photos are not synced to the cloud or included in backups.
class PhotoService {
  PhotoService._();
  static late String _dir;
  static final _picker = ImagePicker();

  static Future<void> init() async {
    final base = await getApplicationDocumentsDirectory();
    final folder = Directory('${base.path}/laundry');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    _dir = folder.path;
  }

  static File fileFor(String name) => File('$_dir/$name');

  /// Returns the saved file name, or null if cancelled / failed.
  static Future<String?> pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
          source: source, maxWidth: 1600, imageQuality: 80);
      if (x == null) return null;
      final name = '${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(x.path).copy('$_dir/$name');
      return name;
    } catch (_) {
      return null;
    }
  }
}
