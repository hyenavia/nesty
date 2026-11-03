import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../data/supply_item.dart';

extension SupplyStatusUi on SupplyStatus {
  Color get color => switch (this) {
        SupplyStatus.safe => AppColors.safe,
        SupplyStatus.low => AppColors.low,
        SupplyStatus.out => AppColors.out,
      };

  String get labelKey => switch (this) {
        SupplyStatus.safe => 'st_safe',
        SupplyStatus.low => 'st_low',
        SupplyStatus.out => 'st_out',
      };
}

extension SupplyCategoryUi on SupplyCategory {
  IconData get icon => switch (this) {
        SupplyCategory.food => Icons.rice_bowl_rounded,
        SupplyCategory.bathroom => Icons.bathtub_rounded,
        SupplyCategory.firstAid => Icons.medical_services_rounded,
        SupplyCategory.household => Icons.cleaning_services_rounded,
      };

  String get labelKey => switch (this) {
        SupplyCategory.food => 'cat_food',
        SupplyCategory.bathroom => 'cat_bathroom',
        SupplyCategory.firstAid => 'cat_firstaid',
        SupplyCategory.household => 'cat_household',
      };
}

/// Small colored pill: dot + label. Text stays brown for readability.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final SupplyStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            context.s.t(status.labelKey),
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down_rounded, size: 16, color: status.color),
        ],
      ),
    );
  }
}
