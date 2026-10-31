import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// Plus Jakarta Sans for numbers / info, per the brand board.
  static TextStyle numbers({double size = 16, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: AppColors.brown);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.peachDeep,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.peachDeep,
      onPrimary: AppColors.brown,
      primaryContainer: AppColors.peach,
      onPrimaryContainer: AppColors.brown,
      secondary: AppColors.safe,
      secondaryContainer: AppColors.mint,
      onSecondaryContainer: AppColors.brown,
      surface: AppColors.cream,
      onSurface: AppColors.brown,
      error: AppColors.out,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    // Nunito Sans = body, Nunito = headings.
    final textTheme = GoogleFonts.nunitoSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.brown, displayColor: AppColors.brown)
        .copyWith(
          headlineMedium: GoogleFonts.nunito(
              fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.brown),
          headlineSmall: GoogleFonts.nunito(
              fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.brown),
          titleLarge: GoogleFonts.nunito(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brown),
          titleMedium: GoogleFonts.nunito(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brown),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.peach.withValues(alpha: 0.6)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.peach,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.nunitoSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brown),
        ),
        iconTheme: const WidgetStatePropertyAll(
            IconThemeData(color: AppColors.brown)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.peach,
        side: BorderSide(color: AppColors.peach.withValues(alpha: 0.8)),
        labelStyle: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w700, color: AppColors.brown),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.brownSoft,
          selectedBackgroundColor: AppColors.peach,
          selectedForegroundColor: AppColors.brown,
          side: BorderSide(color: AppColors.peach.withValues(alpha: 0.8)),
          textStyle: GoogleFonts.nunitoSans(fontWeight: FontWeight.w800),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected) ? AppColors.brown : AppColors.brownSoft),
        trackColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected) ? AppColors.safe : AppColors.peach),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.peachDeep,
        foregroundColor: AppColors.brown,
        elevation: 2,
        shape: CircleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.peachDeep,
          foregroundColor: AppColors.brown,
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.brown),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.peach.withValues(alpha: 0.9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.peach.withValues(alpha: 0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.peachDeep, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.brown,
        contentTextStyle: GoogleFonts.nunitoSans(
            color: AppColors.cream, fontWeight: FontWeight.w700),
        actionTextColor: AppColors.peach,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
