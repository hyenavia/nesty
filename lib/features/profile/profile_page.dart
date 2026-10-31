import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
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

