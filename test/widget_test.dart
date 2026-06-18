// Phase 1 — smoke test: verify the theme compiles and exposes the expected values.
// Phase 2: add Firebase mock, Riverpod ProviderContainer overrides, and
//          widget tests for each screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme is not null', () {
      expect(AppTheme.light, isNotNull);
    });

    test('dark theme is not null', () {
      expect(AppTheme.dark, isNotNull);
    });

    test('primary color is set correctly', () {
      expect(AppTheme.light.colorScheme.primary, equals(AppColors.primary));
    });
  });
}
