import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static ThemeService? _instance;
  static SharedPreferences? _prefs;

  ThemeService._();

  static Future<ThemeService> getInstance() async {
    if (_instance == null) {
      _instance = ThemeService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> loadThemeMode() async {
    final String? savedMode = _prefs?.getString(_themeKey);
    if (savedMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString(_themeKey, mode.name);
    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xFFF5F7FA),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF4A90E2),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF4A90E2),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF4A90E2),
      surface: Colors.white,
      onSurface: Colors.black87,
      onSurfaceVariant: Colors.grey[600]!,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.grey[600]),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.grey[700]),
      labelLarge: TextStyle(color: Colors.black87),
      labelMedium: TextStyle(color: Colors.grey[600]),
      labelSmall: TextStyle(color: Colors.grey[500]),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: Color(0xFF4A90E2).withOpacity(0.2),
    ),
    dividerColor: Colors.grey[200],
    dividerTheme: DividerThemeData(color: Colors.grey[200]),
    listTileTheme: ListTileThemeData(
      textColor: Colors.black87,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E2E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E2E),
      selectedItemColor: Color(0xFF6DB3F2),
      unselectedItemColor: Colors.grey[500],
    ),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF6DB3F2),
      surface: Color(0xFF1E1E2E),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.grey[400]!,
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.grey[400]),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.grey[300]),
      labelLarge: TextStyle(color: Colors.white),
      labelMedium: TextStyle(color: Colors.grey[400]),
      labelSmall: TextStyle(color: Colors.grey[500]),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFF2A2A3E),
      selectedColor: Color(0xFF6DB3F2).withOpacity(0.2),
    ),
    dividerColor: Colors.grey[700],
    dividerTheme: DividerThemeData(color: Colors.grey[700]),
    listTileTheme: ListTileThemeData(
      textColor: Colors.white,
    ),
    dialogBackgroundColor: Color(0xFF1E1E2E),
    popupMenuTheme: PopupMenuThemeData(color: Color(0xFF1E1E2E)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Color(0xFF6DB3F2);
        return Colors.grey[600];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Color(0xFF6DB3F2).withOpacity(0.5);
        return Colors.grey[700];
      }),
    ),
  );
}
