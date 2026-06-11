import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider._internal();
  static final ThemeProvider _instance = ThemeProvider._internal();
  factory ThemeProvider() => _instance;

  static const _key = 'is_dark_mode';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }

  // Light theme
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE0E0E0),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          selectedItemColor: const Color(0xFF00A36C),
          unselectedItemColor: Colors.grey,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.black87,
          iconColor: Colors.grey,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF00A36C);
            }
            return Colors.grey;
          }),
        ),
      );

  // Dark theme
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: const Color(0xFF3C3C3C),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
          selectedItemColor: const Color(0xFF00A36C),
          unselectedItemColor: Colors.grey,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3C3C3C)),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.grey,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF2C2C2C),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF00A36C);
            }
            return Colors.grey;
          }),
        ),
      );
}

/// Extension on BuildContext for easy theme-aware color access.
/// Use these instead of hardcoded Colors.white / Colors.black.
extension AppTheme on BuildContext {
  /// Surface color: white in light, dark card in dark
  Color get surfaceColor => Theme.of(this).cardColor;

  /// Scaffold background (returns the logical bg color even when scaffold is transparent)
  Color get bgColor =>
      Theme.of(this).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5);

  /// Primary text color
  Color get textColor =>
      Theme.of(this).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;

  /// Secondary text color
  Color get subtextColor =>
      Theme.of(this).brightness == Brightness.dark
          ? Colors.grey.shade400
          : Colors.grey.shade600;

  /// Border color
  Color get borderColor =>
      Theme.of(this).brightness == Brightness.dark
          ? const Color(0xFF3C3C3C)
          : Colors.grey.shade200;

  /// Whether dark mode is active
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
