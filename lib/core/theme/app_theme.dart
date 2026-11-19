import 'package:material_ui/material_ui.dart';

class AppColors {
  AppColors._();

  static const Color forest = Color(0xFF164F43);
  static const Color green = Color(0xFF26735A);
  static const Color mint = Color(0xFFE8F2EC);
  static const Color lime = Color(0xFFDCEB9C);
  static const Color brandDot = Color(0xFF8BAA72);
  static const Color ink = Color(0xFF1C332E);
  static const Color muted = Color(0xFF667A73);
  static const Color line = Color(0xFFDFE7E1);
  static const Color inputBorder = Color(0xFFD6E1D8);
  static const Color paper = Color(0xFFF5F8F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFEDF3EC);
  static const Color segmentedBg = Color(0xFFEDF2EC);
  static const Color avatarBg = Color(0xFFE4EDDF);
  static const Color storyBg = Color(0xFFE9F0E6);
  static const Color barTrack = Color(0xFFEDF1EB);
  static const Color barFill = Color(0xFF83A86B);
  static const Color unreadBg = Color(0xFFF4F8EF);

  static const Color orange = Color(0xFFA35C12);
  static const Color orangeBg = Color(0xFFFCF1E1);
  static const Color warningBg = Color(0xFFFCF2E4);
  static const Color warningText = Color(0xFF80501E);
  static const Color warningBorder = Color(0xFFDFC79C);
  static const Color notifDot = Color(0xFFC77E34);

  static const Color red = Color(0xFFB23A38);
  static const Color redBg = Color(0xFFFBECEB);

  static const Color blue = Color(0xFF326B8C);
  static const Color blueBg = Color(0xFFEDF3F8);

  static const Color offlineBg = Color(0xFFEDF0EE);
}

class AppFonts {
  AppFonts._();

  static TextStyle manrope({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w800,
    double? letterSpacing,
    double? height,
    Color color = AppColors.ink,
  }) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontFamilyFallback: const ['Manrope', 'Roboto', 'sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle dmSans({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
    double? height,
    Color color = AppColors.ink,
  }) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontFamilyFallback: const ['DM Sans', 'Roboto', 'sans-serif'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData build() {
    final headingStyle = AppFonts.manrope(
      color: AppColors.ink,
      fontWeight: FontWeight.w800,
    );
    final bodyStyle = AppFonts.dmSans(
      color: AppColors.ink,
      fontSize: 13,
      height: 1.5,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forest,
        onPrimary: AppColors.white,
        secondary: AppColors.green,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.ink,
        error: AppColors.red,
        onError: AppColors.white,
        outline: AppColors.line,
      ),
      textTheme: TextTheme(
        displayLarge: headingStyle.copyWith(fontSize: 34, letterSpacing: -1.2),
        displayMedium: headingStyle.copyWith(fontSize: 28, letterSpacing: -1.0),
        displaySmall: headingStyle.copyWith(fontSize: 24, letterSpacing: -0.8),
        headlineLarge: headingStyle.copyWith(
          fontSize: 26,
          letterSpacing: -0.9,
          height: 1.2,
        ),
        headlineMedium: headingStyle.copyWith(
          fontSize: 22,
          letterSpacing: -0.6,
          height: 1.25,
        ),
        headlineSmall: headingStyle.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: headingStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: headingStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleSmall: bodyStyle.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: bodyStyle.copyWith(fontSize: 14),
        bodyMedium: bodyStyle,
        bodySmall: bodyStyle.copyWith(
          fontSize: 12,
          color: AppColors.muted,
        ),
        labelLarge: bodyStyle.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: bodyStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
        labelSmall: bodyStyle.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: AppFonts.dmSans(
          fontSize: 13,
          color: AppColors.muted.withValues(alpha: 0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.green, width: 1.6),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: AppColors.red, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.forest.withValues(alpha: 0.42),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.85),
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: AppFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.white,
          disabledForegroundColor: AppColors.muted.withValues(alpha: 0.5),
          side: const BorderSide(color: AppColors.line),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          textStyle: AppFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green,
          textStyle: AppFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forest,
        contentTextStyle: AppFonts.dmSans(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
