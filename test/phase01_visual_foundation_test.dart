import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/theme/hobby_theme.dart';
import 'package:hobby_tracker/theme/tokens.dart';
import 'package:hobby_tracker/widgets/app_navigation_bar.dart';
import 'package:hobby_tracker/widgets/hobby_app_bar.dart';
import 'package:hobby_tracker/widgets/hobby_button.dart';
import 'package:hobby_tracker/widgets/hobby_card.dart';
import 'package:hobby_tracker/widgets/hobby_dialog.dart';
import 'package:hobby_tracker/widgets/hobby_text_field.dart';

Widget _app(Widget child) => MaterialApp(
  theme: HobbyTheme.forVariant(AppThemeVariant.light),
  home: Scaffold(
    body: Center(child: SingleChildScrollView(child: child)),
  ),
);

void main() {
  test(
    'Light surface, typography and radius tokens match live Figma baseline',
    () {
      final theme = HobbyTheme.forVariant(AppThemeVariant.light);
      final palette = theme.extension<HobbyPalette>()!;
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF7FAF7));
      expect(palette.cardSurface, Colors.white);
      expect(palette.soft, const Color(0xFFE7F5ED));
      expect(palette.primaryDark, const Color(0xFF087F72));
      expect(theme.colorScheme.primary, const Color(0xFF087F72));
      expect(theme.textTheme.headlineSmall?.fontSize, 28);
      expect(theme.textTheme.titleMedium?.fontSize, 17);
      expect(theme.textTheme.bodyMedium?.fontSize, greaterThanOrEqualTo(14));
      expect(AppRadii.card, 16);
      expect(AppRadii.hero, 21);
      expect(AppSpacing.page, 20);
    },
  );

  testWidgets('Four navigation destinations fit both phone widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final tapped = <int>[];
    for (final width in [360.0, 412.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        MaterialApp(
          theme: HobbyTheme.forVariant(AppThemeVariant.light),
          home: Scaffold(
            body: const Center(child: Text('Main screen')),
            bottomNavigationBar: AppNavigationBar(
              selectedIndex: 0,
              onSelected: tapped.add,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('bottom-navigation')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('bottom-navigation'))).height,
        76,
      );
      for (final key in [
        'tab-home',
        'tab-community',
        'tab-hobbies',
        'tab-settings',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byKey(const ValueKey('tab-community')));
    expect(tapped.last, 1);
  });

  testWidgets('Branded app bar, card and controls remain present at 360dp', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    await tester.pumpWidget(
      MaterialApp(
        theme: HobbyTheme.forVariant(AppThemeVariant.light),
        home: const Scaffold(
          appBar: HobbyAppBar(title: 'Home'),
          body: Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: HobbyCard(child: Text('Design card')),
          ),
        ),
      ),
    );
    expect(find.text('hobby'), findsOneWidget);
    expect(find.text('Design card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Password visibility does not destroy draft or validation error',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _app(
          HobbyTextField(
            label: 'Mật khẩu',
            controller: controller,
            errorText: 'Quá ngắn',
            obscureText: true,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'demo-password');
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('password-visibility')));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(controller.text, 'demo-password');
      expect(find.text('Quá ngắn'), findsOneWidget);
    },
  );

  testWidgets('All four button variants and disabled loading are rendered', (
    tester,
  ) async {
    var submits = 0;
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HobbyButton(label: 'Primary', onPressed: () => submits++),
            HobbyButton(
              label: 'Secondary',
              onPressed: () => submits++,
              variant: HobbyButtonVariant.secondary,
            ),
            HobbyButton(
              label: 'Outline',
              onPressed: () => submits++,
              variant: HobbyButtonVariant.outline,
            ),
            HobbyButton(
              label: 'Danger',
              onPressed: () => submits++,
              variant: HobbyButtonVariant.danger,
            ),
            HobbyButton(
              label: 'Saving',
              onPressed: () => submits++,
              isLoading: true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Primary'));
    expect(submits, 1);
    await tester.tap(find.text('Saving'), warnIfMissed: false);
    expect(submits, 1);
  });

  testWidgets('Dialog cannot confirm while saving', (tester) async {
    var submits = 0;
    await tester.pumpWidget(
      _app(
        HobbyDialog(
          title: 'Confirm',
          message: 'Please check',
          onConfirm: () => submits++,
          isSubmitting: true,
        ),
      ),
    );
    expect(find.text('Confirm'), findsNWidgets(2));
    await tester.tap(find.text('Confirm').last, warnIfMissed: false);
    expect(submits, 0);
  });
}
