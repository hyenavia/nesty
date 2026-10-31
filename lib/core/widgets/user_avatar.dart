import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/auth_controller.dart';
import '../../features/profile/profile_controller.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.size = 48, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<ProfileController>();
    final auth = context.watch<AuthController>();
    final photo = profile.photo;
    final name = profile.nickname?.trim().isNotEmpty == true
        ? profile.nickname!.trim()
        : (auth.username?.trim().isNotEmpty == true ? auth.username!.trim() : 'Nesty');

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: photo == null ? null : MemoryImage(photo),
      child: photo == null
          ? Text(
              (name.isEmpty ? 'N' : String.fromCharCode(name.runes.first)).toUpperCase(),
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }
}

