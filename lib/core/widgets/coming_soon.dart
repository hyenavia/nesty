import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'screen_header.dart';

/// Temporary screen for modules that are not built yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          ScreenHeader(title: s.t(titleKey), subtitle: s.t(subtitleKey)),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: AppColors.peachDeep),
                  const SizedBox(height: 12),
                  Text(s.t('soon'), style: theme.textTheme.titleLarge),
                  Text(
                    s.t('soon_body'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.brownSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
