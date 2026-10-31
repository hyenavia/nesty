import 'package:flutter/material.dart';

import 'brand_mark.dart';

/// Nesty mascot badge using the new logo image.
class MascotBadge extends StatelessWidget {
  const MascotBadge({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return BrandMark(size: size);
  }
}
