import 'package:flutter/material.dart';

/// Official Nesty brand mark widget using `assets/images/logo.png`.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.borderRadius});

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? (size * 0.22)),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        cacheWidth: (size * 3).round(),
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Nesty Logo',
      ),
    );
  }
}

