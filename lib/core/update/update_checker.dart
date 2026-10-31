import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releasePageUrl,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final String releasePageUrl;
  final bool hasUpdate;
}

/// Controller reaktif untuk memantau status ketersediaan pembaruan Nesty di seluruh aplikasi.
class UpdateController extends ChangeNotifier {
  AppUpdateInfo? _availableUpdate;
  bool _isChecking = false;

  AppUpdateInfo? get availableUpdate => _availableUpdate;
  bool get isChecking => _isChecking;
  bool get hasUpdate => _availableUpdate?.hasUpdate ?? false;

  void setUpdate(AppUpdateInfo? info) {
    _availableUpdate = info;
    notifyListeners();
  }

  void dismiss() {
    _availableUpdate = null;
    notifyListeners();
  }

  /// Memeriksa pembaruan di latar belakang secara hening (silent check).
  Future<AppUpdateInfo?> checkSilently({BuildContext? context}) async {
    if (_isChecking) return _availableUpdate;
    _isChecking = true;
    notifyListeners();

    try {
      final info = await UpdateCheckerService.checkForUpdate();
      _availableUpdate = info;
      _isChecking = false;
      notifyListeners();

      if (info != null && info.hasUpdate && context != null && context.mounted) {
        UpdateCheckerService.showUpdateDialog(context, info);
      }
      return info;
    } catch (_) {
      _isChecking = false;
      notifyListeners();
      return null;
    }
  }
}

class UpdateCheckerService {
  /// Versi aplikasi saat ini. Selalu disinkronkan dengan pubspec.yaml.
  static const currentVersion = '0.7.2';

  static const String _latestReleaseApi =
      'https://api.github.com/repos/hyenavia/nesty/releases/latest';
  static const String _directDownloadUrl =
      'https://github.com/hyenavia/nesty/releases/latest/download/Nesty.apk';
  static const String feedbackUrl =
      'https://github.com/hyenavia/nesty/issues';

  static bool _isShowingDialog = false;

  /// Membuka URL di browser eksternal via url_launcher.
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to open URL: $e');
      return false;
    }
  }

  /// Memeriksa apakah ada pembaruan rilis terbaru di GitHub.
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final request = await client.getUrl(Uri.parse(_latestReleaseApi));
      request.headers.set('User-Agent', 'Nesty-Android/$currentVersion');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final data = jsonDecode(body) as Map<String, dynamic>;
      final rawTag = (data['tag_name'] as String? ?? '').trim();
      final cleanTag = rawTag.startsWith('v') ? rawTag.substring(1) : rawTag;
      final releaseName =
          (data['name'] as String? ?? 'Nesty $rawTag').trim();
      final releaseNotes = (data['body'] as String? ?? '').trim();
      final releasePageUrl = (data['html_url'] as String? ?? '').trim();

      // Cari URL download langsung untuk file Nesty.apk
      var downloadUrl = _directDownloadUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final a in assets) {
          final assetName = a['name'] as String? ?? '';
          if (assetName == 'Nesty.apk') {
            downloadUrl = a['browser_download_url'] as String? ?? downloadUrl;
            break;
          }
        }
      }

      final hasUpdate = _isVersionGreater(cleanTag, currentVersion);

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: cleanTag,
        releaseName: releaseName,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        releasePageUrl: releasePageUrl,
        hasUpdate: hasUpdate,
      );
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return null;
    }
  }

  /// Membandingkan dua nomor versi SemVer (misal "0.7.0" > "0.6.0").
  static bool _isVersionGreater(String remote, String current) {
    if (remote.isEmpty) return false;
    final rParts = remote.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final cParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (rParts.length < 3) {
      rParts.add(0);
    }
    while (cParts.length < 3) {
      cParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (rParts[i] > cParts[i]) return true;
      if (rParts[i] < cParts[i]) return false;
    }
    return false;
  }

  /// Memeriksa update dan langsung memunculkan dialog/snackbar.
  static Future<void> checkAndPromptUpdate(
    BuildContext context, {
    UpdateController? controller,
    bool silentIfUpToDate = false,
  }) async {
    final s = context.s;
    final info = await checkForUpdate();
    if (info != null && controller != null) {
      controller.setUpdate(info);
    }
    if (!context.mounted) return;

    if (info != null && info.hasUpdate) {
      showUpdateDialog(context, info);
    } else if (!silentIfUpToDate) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              s.t('latest_version_toast', {'version': 'v$currentVersion'}),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Menampilkan dialog pembaruan aplikasi modern bertema Cozy Clay Nesty.
  static void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    if (_isShowingDialog) return;
    _isShowingDialog = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final s = ctx.s;
        final theme = Theme.of(ctx);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppColors.peach,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('update_available'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.brown,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${info.currentVersion} ➔ v${info.latestVersion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.t('update_dialog_desc'),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (info.releaseNotes.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.peach.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.peach.withValues(alpha: 0.25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      info.releaseNotes,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                s.t('update_dialog_tip'),
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.t('later')),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(s.t('update_now')),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.peach,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                openUrl(info.downloadUrl);
              },
            ),
          ],
        );
      },
    ).then((_) {
      _isShowingDialog = false;
    });
  }
}

