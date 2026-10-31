import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'sync_service.dart';

/// Offline backup as a plain .json file. All file_picker calls live here, so
/// if the package API changes you only need to edit this file.
class BackupService {
  const BackupService._();

  /// Returns true when the file was saved.
  static Future<bool> export(SyncService sync) async {
    final json = const JsonEncoder.withIndent('  ').convert(sync.snapshot());
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Nesty backup',
      fileName: 'nesty_backup_$stamp.json',
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
    return saved != null;
  }

  /// Returns the file's text, or null if the person cancelled.
  static Future<String?> pickBackupText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes());
  }
}
