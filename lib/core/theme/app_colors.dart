import 'package:flutter/material.dart';

/// Brand colors from the Nesty brand board + supporting colors.
class AppColors {
  AppColors._();

  // Brand board
  static const peach = Color(0xFFFFD6C2);
  static const cream = Color(0xFFFFF7EC);
  static const mint = Color(0xFFC8E8D0);
  static const brown = Color(0xFF62504A);

  // Supporting (not on the board; added for contrast & status colors)
  static const peachDeep = Color(0xFFF2A07F); // buttons / accents
  static const surface = Color(0xFFFFFCF7); // cards
  static const brownSoft = Color(0xFF7A6862); // secondary text

  // Status: Safe / Running low / Out
  static const safe = Color(0xFF6FBF8A);
  static const low = Color(0xFFF2B84B);
  static const out = Color(0xFFE5675D);
}
