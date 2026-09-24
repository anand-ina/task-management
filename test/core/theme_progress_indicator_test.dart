import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samskar_taskmanager/core/constants/app_colors.dart';

void main() {
  group('Progress Indicator Theme Tests', () {
    test('AppColors buttonPrimary and buttonPrimaryDark match specification', () {
      expect(AppColors.buttonPrimary, const Color(0xFF1E40AF));
      expect(AppColors.buttonPrimaryDark, const Color(0xFF3B82F6));
    });

    testWidgets('AppColors.progressIndicator respects dark/light theme context', (tester) async {
      late Color lightModeColor;
      late Color darkModeColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(brightness: Brightness.light),
            child: Builder(
              builder: (context) {
                lightModeColor = AppColors.progressIndicator(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData(brightness: Brightness.dark),
            child: Builder(
              builder: (context) {
                darkModeColor = AppColors.progressIndicator(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(lightModeColor, AppColors.buttonPrimary);
      expect(darkModeColor, AppColors.buttonPrimaryDark);
    });

    testWidgets('CircularProgressIndicator without explicit color inherits progressIndicatorTheme color in light mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: AppColors.buttonPrimary,
            ),
          ),
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(indicator.color, isNull);
      final theme = Theme.of(tester.element(find.byType(CircularProgressIndicator)));
      expect(theme.progressIndicatorTheme.color, AppColors.buttonPrimary);
    });

    testWidgets('CircularProgressIndicator without explicit color inherits progressIndicatorTheme color in dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: AppColors.buttonPrimaryDark,
            ),
          ),
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(indicator.color, isNull);
      final theme = Theme.of(tester.element(find.byType(CircularProgressIndicator)));
      expect(theme.progressIndicatorTheme.color, AppColors.buttonPrimaryDark);
    });
  });
}
