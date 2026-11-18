import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared colour tokens. Screens should prefer these over inline hex values.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF0D9488);
  static const Color brandDark = Color(0xFF0F766E);
  static const Color brandLight = Color(0xFF2DD4BF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0284C7);

  // Neutrals (slate)
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSoft = Color(0xFF334155);
  static const Color muted = Color(0xFF64748B);
  static const Color mutedDark = Color(0xFF94A3B8);
  static const Color line = Color(0xFFE2E8F0);
  static const Color lineDark = Color(0xFF334155);
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color canvasDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color subtle = Color(0xFFF1F5F9);

  static Color surface(bool isDark) => isDark ? surfaceDark : Colors.white;
  static Color background(bool isDark) => isDark ? canvasDark : canvas;
  static Color border(bool isDark) => isDark ? lineDark : line;
  static Color title(bool isDark) => isDark ? Colors.white : ink;
  static Color subtitle(bool isDark) => isDark ? mutedDark : muted;
}

/// Spacing and radius scale used across the app.
class AppSpace {
  AppSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double radiusSm = 8;
  static const double radius = 12;
  static const double radiusLg = 16;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.brandLight : AppColors.brand,
      onPrimary: isDark ? const Color(0xFF042F2E) : Colors.white,
      surface: AppColors.surface(isDark),
      onSurface: AppColors.title(isDark),
      onSurfaceVariant: AppColors.subtitle(isDark),
      outline: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      outlineVariant: AppColors.border(isDark),
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
    );

    final baseTextTheme = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;

    TextStyle font(double size, FontWeight weight, {double spacing = 0, double? height}) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          height: height,
        );

    // A compact type scale: fewer, clearer steps with restrained weights.
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme)
        .copyWith(
          headlineLarge: font(26, FontWeight.w800, spacing: -0.5),
          headlineMedium: font(22, FontWeight.w800, spacing: -0.4),
          headlineSmall: font(19, FontWeight.w700, spacing: -0.3),
          titleLarge: font(17, FontWeight.w700, spacing: -0.2),
          titleMedium: font(15, FontWeight.w700, spacing: -0.1),
          titleSmall: font(13.5, FontWeight.w600),
          bodyLarge: font(14.5, FontWeight.w500, height: 1.4),
          bodyMedium: font(13.5, FontWeight.w500, height: 1.4),
          bodySmall: font(12, FontWeight.w500, height: 1.35),
          labelLarge: font(13.5, FontWeight.w700),
          labelMedium: font(12, FontWeight.w600),
          labelSmall: font(11, FontWeight.w600, spacing: 0.1),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    final border = AppColors.border(isDark);
    final shape12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.radius));

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background(isDark),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        toolbarHeight: 58,
        titleSpacing: 4,
        backgroundColor: AppColors.background(isDark),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface, size: 22),
        systemOverlayStyle: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface(isDark),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withAlpha(18),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.subtle,
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.radiusSm)),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface(isDark),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(colorScheme.primary, 1.5),
        errorBorder: inputBorder(colorScheme.error),
        focusedErrorBorder: inputBorder(colorScheme.error, 1.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        isDense: false,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(170), fontSize: 13.5),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13.5),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: shape12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 46),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.labelLarge,
          shape: shape12,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: colorScheme.outline),
          shape: shape12,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        highlightElevation: 3,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        extendedIconLabelSpacing: 6,
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.radiusLg)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface(isDark),
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFE2E8F0) : AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.ink : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpace.radius)),
      ),
      listTileTheme: ListTileThemeData(
        dense: false,
        minVerticalPadding: 10,
        horizontalTitleGap: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        iconColor: colorScheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.radius),
          side: BorderSide(color: border),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface.withAlpha(230),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.all(8),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
      ),
    );
  }
}
