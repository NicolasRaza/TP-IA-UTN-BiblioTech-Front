import 'package:flutter/material.dart';

/// Paleta de BiblioTech, portada de las variables CSS del prototipo
/// (`css/main.css`) para que la app Flutter se vea igual que la web original.
class Paleta {
  static const bgBase = Color(0xFF080B14);
  static const bgSurface = Color(0xFF0E1220);
  static const bgCard = Color(0xFF141B2D);
  static const bgHover = Color(0xFF1A2338);
  static const bgInput = Color(0xFF0F1525);

  static const border = Color(0xFF1E2D4A);
  static const borderLight = Color(0xFF243552);

  static const primary = Color(0xFF7B68EE);
  static const primaryLight = Color(0xFF9B8FFF);
  static const primaryDark = Color(0xFF5A4FCF);

  static const teal = Color(0xFF00C9A7);
  static const tealLight = Color(0xFF00E5C0);

  static const pink = Color(0xFFFF6B9D);
  static const gold = Color(0xFFFFB547);

  static const success = Color(0xFF22D3A0);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFFF5C7A);
  static const info = Color(0xFF60A5FA);

  static const textPrimary = Color(0xFFE2E8F5);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF546080);
}

/// Radios de borde equivalentes a los `--radius-*` del CSS.
class Radios {
  static const sm = 6.0;
  static const base = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

ThemeData construirTema() {
  const esquema = ColorScheme.dark(
    primary: Paleta.primary,
    onPrimary: Colors.white,
    primaryContainer: Paleta.primaryDark,
    secondary: Paleta.teal,
    onSecondary: Paleta.bgBase,
    surface: Paleta.bgCard,
    onSurface: Paleta.textPrimary,
    error: Paleta.danger,
    onError: Colors.white,
    outline: Paleta.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Paleta.bgBase,
    canvasColor: Paleta.bgSurface,
    dividerColor: Paleta.border,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
          color: Paleta.textPrimary, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(
          color: Paleta.textPrimary, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(
          color: Paleta.textPrimary, fontWeight: FontWeight.w700),
      titleLarge:
          TextStyle(color: Paleta.textPrimary, fontWeight: FontWeight.w600),
      titleMedium:
          TextStyle(color: Paleta.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Paleta.textPrimary),
      bodyMedium: TextStyle(color: Paleta.textSecondary),
      bodySmall: TextStyle(color: Paleta.textMuted),
      labelLarge:
          TextStyle(color: Paleta.textPrimary, fontWeight: FontWeight.w600),
    ),
    cardTheme: CardTheme(
      color: Paleta.bgCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.md),
        side: const BorderSide(color: Paleta.border),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Paleta.bgSurface,
      foregroundColor: Paleta.textPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Paleta.bgInput,
      hintStyle: const TextStyle(color: Paleta.textMuted),
      labelStyle: const TextStyle(color: Paleta.textSecondary),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.base),
        borderSide: const BorderSide(color: Paleta.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.base),
        borderSide: const BorderSide(color: Paleta.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.base),
        borderSide: const BorderSide(color: Paleta.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radios.base),
        borderSide: const BorderSide(color: Paleta.danger),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.base),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.textPrimary,
        side: const BorderSide(color: Paleta.borderLight),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radios.base),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Paleta.primaryLight),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Paleta.bgHover,
      side: const BorderSide(color: Paleta.border),
      labelStyle: const TextStyle(color: Paleta.textSecondary, fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.xl),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Paleta.bgSurface,
      indicatorColor: Paleta.primary.withOpacity(0.22),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: s.contains(WidgetState.selected)
              ? Paleta.primaryLight
              : Paleta.textMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Paleta.primaryLight
              : Paleta.textMuted,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Paleta.bgSurface,
      selectedIconTheme: IconThemeData(color: Paleta.primaryLight),
      unselectedIconTheme: IconThemeData(color: Paleta.textMuted),
      selectedLabelTextStyle: TextStyle(
          color: Paleta.primaryLight, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: Paleta.textMuted),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Paleta.bgCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.lg),
        side: const BorderSide(color: Paleta.border),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Paleta.bgHover,
      contentTextStyle: const TextStyle(color: Paleta.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.base),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Paleta.primary),
    listTileTheme: const ListTileThemeData(
      iconColor: Paleta.textSecondary,
      textColor: Paleta.textPrimary,
    ),
  );
}
