import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  
  // ═══════════════════════════════════════════════════════════
  // 🎨 MAVİ & BEYAZ RENK PALETİ
  // ═══════════════════════════════════════════════════════════
  
  // Primary Colors - Mavi tonları
  static const Color primary = Color(0xFF00B6F0);        // Parlak mavi
  static const Color primaryDark = Color(0xFF0096D6);    // Koyu mavi
  static const Color primaryLight = Color(0xFF4FC3F7);   // Açık mavi
  static const Color secondary = Color(0xFF2633C5);      // Derin mavi
  static const Color accent = Color(0xFF00D4FF);         // Cyan accent
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // ═══════════════════════════════════════════════════════════
  // ☀️ LIGHT MODE - BEYAZ & MAVİ
  // ═══════════════════════════════════════════════════════════
  
  static const Color lightBackground = Color(0xFFF2F3F8);     // Soft gri-mavi
  static const Color lightSurface = Color(0xFFFFFFFF);        // Pure white
  static const Color lightSurfaceVariant = Color(0xFFF5F7FA); // Soft grey
  static const Color lightTextPrimary = Color(0xFF17262A);    // Koyu
  static const Color lightTextSecondary = Color(0xFF4A6572);  // Orta
  static const Color lightTextTertiary = Color(0xFF767676);   // Açık
  static const Color lightBorder = Color(0xFFE8ECF1);
  static const Color lightDivider = Color(0xFFEEF1F3);
  
  // ═══════════════════════════════════════════════════════════
  // 🌙 DARK MODE - KOYU TONLAR
  // ═══════════════════════════════════════════════════════════
  
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextTertiary = Color(0xFF6E7681);
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkDivider = Color(0xFF21262D);

  // ═══════════════════════════════════════════════════════════
  // 🎯 GRADIENT PRESETS
  // ═══════════════════════════════════════════════════════════
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B6F0), Color(0xFF2633C5)],
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FC3F7), Color(0xFF00B6F0)],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF00B6F0)],
  );

  // ═══════════════════════════════════════════════════════════
  // 🎯 THEME DATA - LIGHT
  // ═══════════════════════════════════════════════════════════
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: 'Roboto',
    
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: lightSurface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.18,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.grey.withOpacity(0.15),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primary,
      unselectedItemColor: lightTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: lightTextTertiary),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    
    dividerTheme: const DividerThemeData(color: lightDivider, thickness: 1),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: lightTextSecondary,
      indicatorColor: primary,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: lightSurfaceVariant,
      selectedColor: primary.withOpacity(0.15),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ═══════════════════════════════════════════════════════════
  // 🎯 THEME DATA - DARK
  // ═══════════════════════════════════════════════════════════
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'Roboto',
    
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: darkSurface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
      onError: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.18,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: darkTextTertiary),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    
    dividerTheme: const DividerThemeData(color: darkDivider, thickness: 1),
    
    tabBarTheme: const TabBarThemeData(
      labelColor: primary,
      unselectedLabelColor: darkTextSecondary,
      indicatorColor: primary,
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceVariant,
      selectedColor: primary.withOpacity(0.2),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // ═══════════════════════════════════════════════════════════
  // 🛠️ HELPER METHODS - AYNI KALIYOR
  // ═══════════════════════════════════════════════════════════
  
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  
  static Color background(BuildContext context) => isDark(context) ? darkBackground : lightBackground;
  static Color surface(BuildContext context) => isDark(context) ? darkSurface : lightSurface;
  static Color surfaceVariant(BuildContext context) => isDark(context) ? darkSurfaceVariant : lightSurfaceVariant;
  static Color textPrimary(BuildContext context) => isDark(context) ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(BuildContext context) => isDark(context) ? darkTextSecondary : lightTextSecondary;
  static Color textTertiary(BuildContext context) => isDark(context) ? darkTextTertiary : lightTextTertiary;
  static Color border(BuildContext context) => isDark(context) ? darkBorder : lightBorder;
  static Color divider(BuildContext context) => isDark(context) ? darkDivider : lightDivider;
  
  // ═══════════════════════════════════════════════════════════
  // 🎨 SHADOWS
  // ═══════════════════════════════════════════════════════════
  
  static List<BoxShadow> cardShadow(BuildContext context) => isDark(context) ? [] : [
    BoxShadow(
      color: Colors.grey.withOpacity(0.15),
      offset: const Offset(4, 4),
      blurRadius: 16,
    ),
  ];
  
  static List<BoxShadow> shadowSm(BuildContext context) => [
    BoxShadow(
      color: isDark(context) 
          ? Colors.black.withOpacity(0.3) 
          : Colors.grey.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMd(BuildContext context) => [
    BoxShadow(
      color: isDark(context) 
          ? Colors.black.withOpacity(0.4) 
          : Colors.grey.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(4, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLg(BuildContext context) => [
    BoxShadow(
      color: isDark(context) 
          ? Colors.black.withOpacity(0.5) 
          : Colors.grey.withOpacity(0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> colorShadow(Color color, {double opacity = 0.35, double blur = 12}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: blur,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ═══════════════════════════════════════════════════════════
  // 🎨 DECORATIONS
  // ═══════════════════════════════════════════════════════════
  
  static BoxDecoration glassEffect(BuildContext context) => BoxDecoration(
    color: isDark(context) 
        ? Colors.white.withOpacity(0.05) 
        : Colors.white.withOpacity(0.8),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isDark(context) 
          ? Colors.white.withOpacity(0.1) 
          : Colors.white.withOpacity(0.5),
    ),
    boxShadow: shadowSm(context),
  );
  
  static BoxDecoration gradientButton({double radius = 28}) => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: colorShadow(primary),
  );
  
  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
    color: surface(context),
    borderRadius: BorderRadius.circular(16),
    boxShadow: cardShadow(context),
  );
  
  static BoxDecoration elevatedCard(BuildContext context) => BoxDecoration(
    color: surface(context),
    borderRadius: BorderRadius.circular(16),
    boxShadow: shadowMd(context),
  );
}
