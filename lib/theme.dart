import 'package:flutter/material.dart';

/// FixIt colour palette (matches the screen-design reports).
class C {
  static const navy = Color(0xFF1C2A4A);
  static const blue = Color(0xFF2F6BDB);
  static const green = Color(0xFF2E9E6A);
  static const amber = Color(0xFFC8942A);
  static const red = Color(0xFFD04A4A);
  static const grey = Color(0xFF7A808C);
  static const border = Color(0xFFE3E6EC);
  static const bg = Color(0xFFF5F7FB);
  static const muted = Color(0xFF6B7280);
  static const softBlue = Color(0xFFEAF0FB);
  static const star = Color(0xFFF5A623);
  static const onDarkMuted = Color(0xFFB9C4DB);
  static const railSelected = Color(0x2EFFFFFF);
}

ThemeData buildTheme() {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.blue,
      primary: C.navy,
      secondary: C.blue,
    ),
    scaffoldBackgroundColor: C.bg,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: b(C.border),
      enabledBorder: b(C.border),
      focusedBorder: b(C.blue, 1.6),
      errorBorder: b(C.red),
      focusedErrorBorder: b(C.red, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.navy,
        side: const BorderSide(color: C.navy),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
