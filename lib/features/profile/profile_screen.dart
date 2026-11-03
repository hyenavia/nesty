import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/modules/module_controller.dart';
import '../../core/notifications/reminder_controller.dart';
import '../../core/sync/backup_service.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/update/update_checker.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import '../onboarding/onboarding_controller.dart';
import '../settings/app_changelog.dart';
import 'profile_controller.dart';
import 'profile_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openModuleCustomizer(BuildContext context) {
    final s = context.s;
    final modules = [
      (ModuleController.moduleToken, Icons.bolt_rounded, AppColors.low, s.t('module_token')),
      (ModuleController.moduleGallon, Icons.water_drop_rounded, AppColors.water, s.t('module_gallon')),
      (ModuleController.moduleLaundry, Icons.local_laundry_service_rounded, AppColors.lavender, s.t('module_laundry')),
      (ModuleController.moduleSupplies, Icons.shopping_basket_rounded, AppColors.peachDeep, s.t('module_supplies')),
      (ModuleController.moduleBills, Icons.receipt_long_rounded, AppColors.peachDeep, s.t('module_bills')),
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final controller = ctx.watch<ModuleController>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('customize_modules'),
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  s.t('customize_modules_sub'),
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.brownSoft),
                ),
                const SizedBox(height: 14),
                for (final m in modules)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: controller.isEnabled(m.$1),
                    activeColor: AppColors.peachDeep,
                    title: Text(m.$4, style: const TextStyle(fontWeight: FontWeight.w700)),
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: m.$3.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.$2, color: AppColors.brown, size: 20),
                    ),
                    onChanged: (val) {
                      controller.setEnabled(m.$1, val ?? true);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool isDestructive = false,
  }) async {
    final s = context.s;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.out)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _export(BuildContext context) async {
    final s = context.s;
    final sync = context.read<SyncService>();
    try {
      if (await BackupService.export(sync) && context.mounted) {
        _toast(context, s.t('export_ok'));
      }
    } catch (_) {
      if (context.mounted) _toast(context, s.t('err_unknown'));
    }
  }

  Future<void> _import(BuildContext context) async {
    final s = context.s;
    final sync = context.read<SyncService>();
    final ok = await _confirm(
      context,
      title: s.t('import_confirm_t'),
      body: s.t('import_confirm_b'),
      action: s.t('replace'),
    );
    if (!ok) return;
    try {
      final text = await BackupService.pickBackupText();
      if (text == null) return;
      sync.importJson(text);
      if (context.mounted) _toast(context, s.t('import_ok'));
    } on FormatException {
      if (context.mounted) _toast(context, s.t('import_failed'));
    } catch (_) {
      if (context.mounted) _toast(context, s.t('err_unknown'));
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final s = context.s;
    final ok = await _confirm(
      context,
      title: s.t('delete_account_t'),
      body: s.t('delete_account_b'),
      action: s.t('delete_account'),
      isDestructive: true,
    );
    if (!ok || !context.mounted) return;

    final passCtrl = TextEditingController();
    String? passError;
    final passOk = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.t('delete_account')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.t('reauth_password')),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.t('password'),
                  errorText: passError,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                onChanged: (_) {
                  if (passError != null) setDialogState(() => passError = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.t('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.out),
              onPressed: () {
                if (passCtrl.text.trim().isEmpty) {
                  setDialogState(() => passError = s.t('err_password_required'));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(s.t('delete_account')),
            ),
          ],
        ),
      ),
    );

    if (passOk != true || !context.mounted) return;

    try {
      await context.read<AuthController>().deleteAccount(password: passCtrl.text.trim());
      if (context.mounted) _toast(context, s.t('delete_account_ok'));
    } on AuthFailure catch (e) {
      if (context.mounted) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _toast(context, s.t('wrong_current_password'));
        } else if (e.code == 'requires-recent-login') {
          _toast(context, s.t('err_requires_recent_login'));
        } else {
          _toast(context, s.t('err_unknown'));
        }
      }
    } catch (e) {
      if (context.mounted) _toast(context, s.t('err_unknown'));
    }
  }

  void _showBatteryGuideDialog(BuildContext context) {
    final s = context.s;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.battery_saver_rounded, color: AppColors.peachDeep),
            const SizedBox(width: 8),
            Expanded(child: Text(s.t('battery_guide_title'))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.t('battery_guide_desc')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. ${s.lang == 'id' ? 'Buka Pengaturan HP > Aplikasi > Nesty' : 'Open Settings > Apps > Nesty'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('2. ${s.lang == 'id' ? 'Pilih Penghemat Baterai: Tidak ada pembatasan' : 'Set Battery Saver to No Restrictions'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('3. ${s.lang == 'id' ? 'Aktifkan Mulai Otomatis (Autostart) jika ada' : 'Allow Autostart / Background activity if present'}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.t('tip_dismiss')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final locale = context.read<LocaleController>();
    final auth = context.watch<AuthController>();
    final sync = context.watch<SyncService>();
    final profile = context.watch<ProfileController>();
    final reminders = context.watch<ReminderController>();
    final update = context.watch<UpdateController>();

    final displayName = profile.nickname?.trim().isNotEmpty == true
        ? profile.nickname!.trim()
        : (auth.username?.trim().isNotEmpty == true ? auth.username!.trim() : s.t('profile'));

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        );

    Widget sectionCard(List<Widget> children) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        );

    final lastSyncText = sync.lastSyncTime == null
        ? s.t('no_backup_yet')
        : s.t('last_backup', {
            'date': DateFormat('dd MMM yyyy, HH:mm').format(sync.lastSyncTime!),
          });

    final (syncStatusText, syncStatusColor) = switch (sync.state) {
      SyncState.idle => (s.t('sync_idle'), AppColors.brownSoft),
      SyncState.syncing => (s.t('sync_syncing'), AppColors.low),
      SyncState.synced => (s.t('sync_synced'), AppColors.safe),
      SyncState.offline => (s.t('sync_offline'), AppColors.low),
      SyncState.error => (s.t('sync_error'), AppColors.out),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('tab_profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ---- TOP PROFILE CARD (Matching Wall o' Pay)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const UserAvatar(size: 58),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.signedIn && auth.username != null
                                  ? '@${auth.username}'
                                  : s.t('continue_guest'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.brownSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.brownSoft),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---- PREFERENCES
          sectionHeader(s.t('preferences')),
          sectionCard([
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_rounded),
              title: Text(s.t('language'), style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: DropdownButton<String>(
                value: s.lang,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(12),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(s.t('lang_en'))),
                  DropdownMenuItem(value: 'id', child: Text(s.t('lang_id'))),
                ],
                onChanged: (code) {
                  if (code != null) locale.setLanguage(code);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: Text(s.t('customize_modules'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('customize_modules_sub'), style: theme.textTheme.bodySmall),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _openModuleCustomizer(context),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined),
              title: Text(s.t('theme'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('theme_signature'), style: theme.textTheme.bodySmall),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.peach,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ]),

          // ---- SMART REMINDERS
          sectionHeader(s.t('smart_reminders')),
          sectionCard([
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.t('rem_enable'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('rem_enable_sub'), style: theme.textTheme.bodySmall),
              value: reminders.enabled,
              onChanged: (val) async {
                final ok = await reminders.setEnabled(val);
                if (!ok && context.mounted) {
                  _toast(context, s.t('rem_denied'));
                }
              },
            ),
            if (reminders.enabled) ...[
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm_rounded),
                title: Text(s.t('rem_time'), style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: ActionChip(
                  avatar: const Icon(Icons.access_time_rounded, size: 16),
                  label: Text(reminders.time.format(context)),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminders.time,
                    );
                    if (picked != null) {
                      await reminders.setTime(picked);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.t('rem_weekly_digest'), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(s.t('rem_weekly_digest_sub'), style: theme.textTheme.bodySmall),
                value: reminders.weeklyDigestEnabled,
                onChanged: (val) => reminders.setWeeklyDigestEnabled(val),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.battery_saver_rounded),
                title: Text(s.t('battery_guide'), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(s.t('battery_guide_sub'), style: theme.textTheme.bodySmall),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showBatteryGuideDialog(context),
              ),
            ],
          ]),

          // ---- CLOUD SYNC & STORAGE
          sectionHeader(s.t('cloud_sync_storage')),
          sectionCard([
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: syncStatusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    syncStatusText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: syncStatusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              lastSyncText,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: auth.signedIn ? sync.syncNow : null,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(s.t('sync_now')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: auth.signedIn
                        ? () async {
                            try {
                              await sync.sendToCloud();
                              if (context.mounted) _toast(context, s.t('cloud_upload_ok'));
                            } catch (_) {
                              if (context.mounted) _toast(context, s.t('err_unknown'));
                            }
                          }
                        : null,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(s.t('send_to_cloud')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: auth.signedIn
                        ? () async {
                            try {
                              await sync.fetchFromCloud();
                              if (context.mounted) _toast(context, s.t('cloud_fetch_ok'));
                            } catch (_) {
                              if (context.mounted) _toast(context, s.t('err_unknown'));
                            }
                          }
                        : null,
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: Text(s.t('fetch_from_cloud')),
                  ),
                ),
              ],
            ),
          ]),

          // ---- BACKUP FILE (OFFLINE)
          sectionHeader(s.t('backup')),
          sectionCard([
            Text(
              s.t('backup_sub'),
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export(context),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: Text(s.t('export_data')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _import(context),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(s.t('import_data')),
                  ),
                ),
              ],
            ),
          ]),

          // ---- ACCOUNT
          sectionHeader(s.t('account')),
          sectionCard([
            if (!auth.firebaseReady)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(s.t('cloud_off')),
              )
            else if (auth.signedIn) ...[
              if (auth.email != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: Text(auth.email!),
                  subtitle: Text(s.t('email')),
                ),
              if (auth.username != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alternate_email_rounded),
                  title: Text('@${auth.username}'),
                  subtitle: Text(s.t('username')),
                ),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await _confirm(
                          context,
                          title: s.t('sign_out_t'),
                          body: s.t('sign_out_b'),
                          action: s.t('sign_out'),
                        );
                        if (ok) await auth.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(s.t('sign_out')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.out),
                      onPressed: () => _deleteAccount(context),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: Text(s.t('delete_account')),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                s.t('guest_note'),
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brownSoft),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: auth.exitGuest,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: Text('${s.t('sign_in')} / ${s.t('sign_up')}'),
              ),
            ],
          ]),

          // ---- ABOUT & UPDATES
          sectionHeader(s.t('about_support')),
          sectionCard([
            // Check for Updates (matching Wall o' Pay)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.system_update_alt_rounded),
              title: Row(
                children: [
                  Text(
                    s.t('check_updates'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (update.availableUpdate != null && update.availableUpdate!.hasUpdate) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.peach,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.t('new_badge'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                update.availableUpdate != null && update.availableUpdate!.hasUpdate
                    ? 'v${UpdateCheckerService.currentVersion} ➔ v${update.availableUpdate!.latestVersion} (${s.t('update_available')})'
                    : 'Nesty v${UpdateCheckerService.currentVersion} • ${s.t('latest_release')}',
                style: TextStyle(
                  color: update.availableUpdate != null && update.availableUpdate!.hasUpdate
                      ? AppColors.peach
                      : null,
                  fontWeight: update.availableUpdate != null && update.availableUpdate!.hasUpdate
                      ? FontWeight.w700
                      : null,
                ),
              ),
              trailing: update.isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () {
                if (update.availableUpdate != null && update.availableUpdate!.hasUpdate) {
                  UpdateCheckerService.showUpdateDialog(context, update.availableUpdate!);
                } else {
                  _toast(context, s.t('checking_updates'));
                  UpdateCheckerService.checkAndPromptUpdate(
                    context,
                    controller: update,
                    silentIfUpToDate: false,
                  );
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_edu_rounded),
              title: Text(s.t('version_changelog'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('changelog_sub'), style: theme.textTheme.bodySmall),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showAppChangelogSheet(context),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(s.t('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('privacy_policy_sub'), style: theme.textTheme.bodySmall),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () {
                UpdateCheckerService.openUrl(UpdateCheckerService.privacyPolicyUrl);
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.feedback_outlined),
              title: Text(s.t('send_feedback'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('send_feedback_sub'), style: theme.textTheme.bodySmall),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () {
                UpdateCheckerService.openUrl(UpdateCheckerService.feedbackUrl);
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.slideshow_rounded),
              title: Text(s.t('show_intro'), style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                context.read<OnboardingController>().reset();
                _toast(context, s.t('show_intro'));
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(s.t('app_version'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.t('open_source_license'), style: theme.textTheme.bodySmall),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.peach.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'v${UpdateCheckerService.currentVersion} (Build ${UpdateCheckerService.buildNumber})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.brown),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
