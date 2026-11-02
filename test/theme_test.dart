import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/theme/hobby_theme.dart';
import 'package:hobby_tracker/theme/tokens.dart';

void main() {
  test('Light theme follows the live Figma token baseline', () {
    final theme = HobbyTheme.forVariant(AppThemeVariant.light);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.onSurface, AppColors.text);
    expect(theme.colorScheme.surface, AppColors.background);
    expect(theme.textTheme.headlineSmall?.fontSize, 28);
    expect(theme.textTheme.bodyMedium?.fontSize, greaterThanOrEqualTo(14));
  });

  test('Seven named theme variants exist; full parity belongs to Phase 06', () {
    expect(AppThemeVariant.values.length, 7);
    for (final variant in AppThemeVariant.values) {
      expect(HobbyTheme.forVariant(variant), isA<ThemeData>());
    }
  });
}
