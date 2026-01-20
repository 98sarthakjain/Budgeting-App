import 'package:flutter/material.dart';
import 'spacing.dart';

/// Central place for theming the app.
class AppTheme {
  static const Color primary = Color(0xFF0F7DB8); // GPay-ish blue
  static const Color background = Color(0xFFF5F5F7);

  /// Gradients for credit cards and other rich tiles.
  /// Use as: final g = AppTheme.cardGradients[index % AppTheme.cardGradients.length];
  static const List<List<Color>> cardGradients = [
    [Color(0xFF4e54c8), Color(0xFF8f94fb)],
    [Color(0xFF2193b0), Color(0xFF6dd5ed)],
    [Color(0xFFee9ca7), Color(0xFFffdde1)],
    [Color(0xFF4568dc), Color(0xFFb06ab3)],
    [Color(0xFF373B44), Color(0xFF4286f4)],
    [Color(0xFF11998e), Color(0xFF38ef7d)],
    [Color(0xFFfc5c7d), Color(0xFF6a82fb)],
    [Color(0xFFf7971e), Color(0xFFffd200)],
    [Color(0xFF3a1c71), Color(0xFFd76d77)],
    [Color(0xFF141e30), Color(0xFF243b55)],
  ];

  /// Color scheme used across the light theme.
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  );

  /// Main light theme used by BudgetingApp.
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        // Used for big numbers like balance & large headings.
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        // Section headers like "Accounts", "Transactions".
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        // Smaller title, e.g. "Welcome Sarthak"
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        // Primary body text.
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        // Secondary labels / subtitles.
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          color: lightColorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: lightColorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
