import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import 'profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nickname;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(
      text: context.read<ProfileController>().nickname ?? '',
    );
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPhoto() async {
    final s = context.s;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 75,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (mounted) {
        await context.read<ProfileController>().setPhoto(bytes);
        _toast(s.t('profile_saved'));
      }
    } catch (e) {
      if (mounted) {
        _toast(s.t('could_not_pick_photo', {'error': '$e'}));
      }
    }
  }

  Future<void> _save() async {
    final s = context.s;
    await context.read<ProfileController>().setNickname(_nickname.text);
    if (mounted) _toast(s.t('profile_saved'));
  }

  Future<void> _changeUsernameDialog(BuildContext context) async {
    final s = context.s;
    final auth = context.read<AuthController>();
    final ctrl = TextEditingController(text: auth.username ?? '');
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.t('change_username')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: s.t('username'),
                  prefixText: '@',
                  helperText: s.t('username_hint'),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.t('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final val = ctrl.text.trim();
                if (!AuthController.isValidUsername(val)) {
                  setDialogState(() {
                    errorText = s.t('username_hint');
                  });
                  return;
                }
                try {
                  await auth.updateUsername(val);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _toast(s.t('username_saved'));
                } on AuthFailure catch (e) {
                  setDialogState(() {
                    errorText = e.code == 'username-taken'
                        ? s.t('username_taken')
                        : s.t('err_unknown');
                  });
                } catch (e) {
                  setDialogState(() {
                    errorText = '$e';
                  });
                }
              },
              child: Text(s.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final profile = context.watch<ProfileController>();
    final hasPhoto = profile.photo != null;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Stack(
              children: [
                const UserAvatar(size: 112),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(s.t('change_photo')),
              ),
              if (hasPhoto)
                TextButton.icon(
                  onPressed: () => context.read<ProfileController>().setPhoto(null),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(s.t('remove_photo')),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nickname,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 30,
                    decoration: InputDecoration(
                      labelText: s.t('nickname'),
                      helperText: s.t('nickname_hint'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (auth.username != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.alternate_email_rounded),
                      title: Text('@${auth.username}'),
                      subtitle: Text(s.t('username')),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: s.t('change_username'),
                        onPressed: () => _changeUsernameDialog(context),
                      ),
                      onTap: () => _changeUsernameDialog(context),
                    ),
                  if (auth.email != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined),
                      title: Text(auth.email!),
                      subtitle: Text(s.t('email')),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    s.t('username_immutable'),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: AppColors.peach.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.peachDeep.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_outlined,
                        color: AppColors.brown, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.t('nest_code'),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.nestCode ?? 'NST-HOME',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.brown,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.t('nest_code_desc'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.brownSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.brown),
                    tooltip: s.t('nest_code_copied'),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final code = profile.nestCode ?? 'NST-HOME';
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        _toast(s.t('nest_code_copied'));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(s.t('save')),
            ),
          ),
        ],
      ),
    );
  }
}

