import 'package:flutter/material.dart';

class KbColors {
  static const orange900 = Color(0xFF7C2D12);
  static const orange800 = Color(0xFF9A3412);
  static const orange700 = Color(0xFFC2410C);
  static const orange600 = Color(0xFFEA580C);
  static const orange500 = Color(0xFFF97316);
  static const orange400 = Color(0xFFFB923C);
  static const orange300 = Color(0xFFFDBA74);
  static const orange200 = Color(0xFFFED7AA);
  static const ivory = Color(0xFFFFFDF7);
  static const ivory50 = Color(0xFFFFFDF7);
  static const ivory100 = Color(0xFFFDF6E9);
  static const ivory200 = Color(0xFFF8ECD7);
  static const ink = Color(0xFF3B2A1A);
  static const inkSoft = Color(0xFF7A6347);
  static const inkFaint = Color(0xFFA08A6D);
  static const green = Color(0xFF1F9D55);
  static const greenBg = Color(0xFFE7F7EE);
  static const red = Color(0xFFD64545);
  static const redBg = Color(0xFFFDECEC);
  static const amber = Color(0xFFB45309);
  static const amberBg = Color(0xFFFEF3C7);
  static const blue = Color(0xFF2B6CB0);
  static const blueBg = Color(0xFFEBF4FD);
}

ThemeData kbTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: KbColors.orange600,
      primary: KbColors.orange600,
      secondary: KbColors.orange400,
      surface: KbColors.ivory,
      onSurface: KbColors.ink,
    ),
    scaffoldBackgroundColor: KbColors.ivory100,
    fontFamily: 'Poppins',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: KbColors.ivory,
      foregroundColor: KbColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: KbColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: KbColors.ivory200),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: KbColors.orange600,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: KbColors.ivory50,
      hintStyle: const TextStyle(color: KbColors.inkFaint),
      labelStyle: const TextStyle(color: KbColors.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KbColors.ivory200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KbColors.ivory200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: KbColors.orange500, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: KbColors.orange600,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: KbColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KbColors.ivory,
      indicatorColor: KbColors.orange200,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? KbColors.orange700
              : KbColors.inkSoft,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? KbColors.orange700
              : KbColors.inkSoft,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(color: KbColors.ivory200),
  );
}
