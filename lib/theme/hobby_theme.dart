import 'package:flutter/material.dart';

import 'tokens.dart';

enum AppThemeVariant {
  light('Light'),
  dark('Dark'),
  energetic('Energetic'),
  cyber('Cyber'),
  art('Art'),
  sad('Sad'),
  rainyDay('Rainy Day');

  const AppThemeVariant(this.label);
  final String label;
}

@immutable
class HobbyPalette extends ThemeExtension<HobbyPalette> {
  const HobbyPalette({
    required this.muted,
    required this.soft,
    required this.border,
    required this.cardSurface,
    required this.primaryDark,
    required this.heroStart,
    required this.heroEnd,
    required this.inputBorder,
  });

  final Color muted;
  final Color soft;
  final Color border;
  final Color cardSurface;
  final Color primaryDark;
  final Color heroStart;
  final Color heroEnd;
  final Color inputBorder;

  @override
  HobbyPalette copyWith({
    Color? muted,
    Color? soft,
    Color? border,
    Color? cardSurface,
    Color? primaryDark,
    Color? heroStart,
    Color? heroEnd,
    Color? inputBorder,
  }) => HobbyPalette(
    muted: muted ?? this.muted,
    soft: soft ?? this.soft,
    border: border ?? this.border,
    cardSurface: cardSurface ?? this.cardSurface,
    primaryDark: primaryDark ?? this.primaryDark,
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
    inputBorder: inputBorder ?? this.inputBorder,
  );

  @override
  HobbyPalette lerp(ThemeExtension<HobbyPalette>? other, double t) {
    if (other is! HobbyPalette) return this;
    return HobbyPalette(
      muted: Color.lerp(muted, other.muted, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      border: Color.lerp(border, other.border, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
    );
  }
}

extension HobbyThemeContext on BuildContext {
  HobbyPalette get hobbyPalette => Theme.of(this).extension<HobbyPalette>()!;
}

abstract final class HobbyTheme {
  // Palettes read from Figma 5JiJtLyXN6DEpC1LycQPBb, 03/11/2026.
  static ThemeData forVariant(AppThemeVariant variant) {
    final colors = switch (variant) {
      AppThemeVariant.light => (
        primary: const Color(0xFF087F72),
        on: const Color(0xFFFFFFFF),
        bg: const Color(0xFFF7FAF7),
        ink: const Color(0xFF213D36),
        muted: const Color(0xFF4F6F63),
        soft: const Color(0xFFE7F5ED),
        hero: const Color(0xFFC5EADC),
        paper: const Color(0xFFFFFFFF),
        line: const Color(0xFFD8E9DF),
      ),
      AppThemeVariant.dark => (
        primary: const Color(0xFF88B8FF),
        on: const Color(0xFF102238),
        bg: const Color(0xFF101B2C),
        ink: const Color(0xFFE6EDF8),
        muted: const Color(0xFFA8BDD3),
        soft: const Color(0xFF203650),
        hero: const Color(0xFF243B5D),
        paper: const Color(0xFF1B2A40),
        line: const Color(0xFF33445D),
      ),
      AppThemeVariant.energetic => (
        primary: const Color(0xFFCF491E),
        on: const Color(0xFFFFFFFF),
        bg: const Color(0xFFFFF4DD),
        ink: const Color(0xFF492D1C),
        muted: const Color(0xFF775A43),
        soft: const Color(0xFFFFE5BA),
        hero: const Color(0xFFFFC374),
        paper: const Color(0xFFFFFCF6),
        line: const Color(0xFFECC8A0),
      ),
      AppThemeVariant.cyber => (
        primary: const Color(0xFF00DFD5),
        on: const Color(0xFF002D34),
        bg: const Color(0xFF041F29),
        ink: const Color(0xFFD4F3F5),
        muted: const Color(0xFF99C3C8),
        soft: const Color(0xFF0B3945),
        hero: const Color(0xFF10434B),
        paper: const Color(0xFF0D303E),
        line: const Color(0xFF245864),
      ),
      AppThemeVariant.art => (
        primary: const Color(0xFF974E90),
        on: const Color(0xFFFFFFFF),
        bg: const Color(0xFFFFF7E9),
        ink: const Color(0xFF533D56),
        muted: const Color(0xFF7B667E),
        soft: const Color(0xFFF9E2EE),
        hero: const Color(0xFFF5D1DF),
        paper: const Color(0xFFFFFDFC),
        line: const Color(0xFFEED5DD),
      ),
      AppThemeVariant.sad => (
        primary: const Color(0xFF736889),
        on: const Color(0xFFFFFFFF),
        bg: const Color(0xFFF4F1F7),
        ink: const Color(0xFF4B465D),
        muted: const Color(0xFF81798E),
        soft: const Color(0xFFEAE5F0),
        hero: const Color(0xFFDDD8E8),
        paper: const Color(0xFFFCFBFD),
        line: const Color(0xFFDCD6E5),
      ),
      AppThemeVariant.rainyDay => (
        primary: const Color(0xFF367E96),
        on: const Color(0xFFFFFFFF),
        bg: const Color(0xFFEFF8FA),
        ink: const Color(0xFF224B59),
        muted: const Color(0xFF5D8390),
        soft: const Color(0xFFDFF0F6),
        hero: const Color(0xFFB7DDE9),
        paper: const Color(0xFFFAFEFF),
        line: const Color(0xFFCFE5EC),
      ),
    };
    final brightness =
        variant == AppThemeVariant.dark || variant == AppThemeVariant.cyber
        ? Brightness.dark
        : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.on,
          surface: colors.bg,
          onSurface: colors.ink,
          onSurfaceVariant: colors.muted,
          outline: colors.line,
          primaryContainer: colors.soft,
          onPrimaryContainer: colors.primary,
          error: const Color(0xFFC72F48),
        );
    final palette = HobbyPalette(
      muted: colors.muted,
      soft: colors.soft,
      border: colors.line,
      cardSurface: colors.paper,
      primaryDark: colors.primary,
      heroStart: colors.hero,
      heroEnd: colors.hero,
      inputBorder: colors.line,
    );
    final baseText = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme.apply(fontFamily: 'Inter');
    final textTheme = baseText
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontSize: 28,
            height: 34 / 28,
            letterSpacing: 0,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleLarge: baseText.titleLarge?.copyWith(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: scheme.onSurface,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            color: scheme.onSurface,
          ),
          bodyLarge: baseText.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.45,
            color: scheme.onSurface,
          ),
          labelLarge: baseText.labelLarge?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          labelMedium: baseText.labelMedium?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: palette.muted,
          ),
        );
    final themedText = textTheme.apply(fontFamily: 'Inter');
    final cardRadius = variant == AppThemeVariant.cyber ? 0.0 : AppRadii.card;
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        variant == AppThemeVariant.cyber ? 0 : AppRadii.control,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: 'Inter',
      textTheme: themedText,
      extensions: [palette, FigmaStyle(variant)],
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      splashColor: scheme.primary.withValues(alpha: 0.08),
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: AppSizes.appBar,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: palette.cardSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x141A5F42),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.cardSurface,
        isDense: true,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            variant == AppThemeVariant.cyber ? 0 : AppRadii.control,
          ),
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            variant == AppThemeVariant.cyber ? 0 : AppRadii.control,
          ),
          borderSide: BorderSide(color: palette.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            variant == AppThemeVariant.cyber ? 0 : AppRadii.control,
          ),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            variant == AppThemeVariant.cyber ? 0 : AppRadii.control,
          ),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            variant == AppThemeVariant.cyber ? 0 : AppRadii.control,
          ),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.25),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.8),
          minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: textTheme.labelLarge,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primaryDark,
          minimumSize: const Size(AppSizes.minTap, AppSizes.minTap),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          side: BorderSide(color: palette.border),
          shape: controlShape,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
    );
  }
}

@immutable
class FigmaStyle extends ThemeExtension<FigmaStyle> {
  const FigmaStyle(this.variant);
  final AppThemeVariant variant;
  double get controlRadius => variant == AppThemeVariant.cyber ? 0 : 12;
  double get cardRadius => variant == AppThemeVariant.cyber ? 0 : 16;
  @override
  FigmaStyle copyWith({AppThemeVariant? variant}) =>
      FigmaStyle(variant ?? this.variant);
  @override
  FigmaStyle lerp(ThemeExtension<FigmaStyle>? other, double t) =>
      t < .5 || other is! FigmaStyle ? this : other;
}

extension FigmaContext on BuildContext {
  FigmaStyle get figmaStyle => Theme.of(this).extension<FigmaStyle>()!;
}
