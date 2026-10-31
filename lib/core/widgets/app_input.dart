import 'package:flutter/material.dart';

/// Unified text input styling matching Wall o' Pay aesthetics.
InputDecoration appInput(
  BuildContext context, {
  String? label,
  String? hint,
  Widget? prefixIcon,
  String? prefixText,
  String? helper,
  Widget? suffixIcon,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    prefixText: prefixText,
    helperText: helper,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: scheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
  );
}

