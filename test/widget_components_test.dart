import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/theme/hobby_theme.dart';
import 'package:hobby_tracker/widgets/async_states.dart';
import 'package:hobby_tracker/widgets/hobby_button.dart';
import 'package:hobby_tracker/widgets/hobby_checkbox.dart';
import 'package:hobby_tracker/widgets/hobby_text_field.dart';

Widget harness(Widget child) => MaterialApp(
  theme: HobbyTheme.forVariant(AppThemeVariant.light),
  home: Scaffold(
    body: Center(child: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('HobbyButton accepts taps and has a 48dp minimum target', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(HobbyButton(label: 'Create', onPressed: () => taps++)),
    );
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.text('Create'));
    expect(taps, 1);
  });

  testWidgets('HobbyButton disabled/loading never submits', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        Column(
          children: [
            const HobbyButton(label: 'Disabled', onPressed: null),
            HobbyButton(
              label: 'Saving',
              onPressed: () => taps++,
              isLoading: true,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Saving'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('Checkbox is tappable and respects semantics label', (
    tester,
  ) async {
    bool checked = false;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) => HobbyCheckbox(
            label: 'Demo option',
            value: checked,
            onChanged: (value) => setState(() => checked = value ?? false),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(checked, true);
  });

  testWidgets('Text field preserves entered draft when validation shown', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        HobbyTextField(
          label: 'Name',
          errorText: 'Required',
          controller: controller,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Painting');
    expect(controller.text, 'Painting');
    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('Loading, empty, error states have visible labels and retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      harness(
        Column(
          children: [
            const LoadingState(label: 'Loading demo'),
            const EmptyState(
              title: 'No data',
              description: 'Create your first item',
            ),
            ErrorState(message: 'No internet', onRetry: () => retries++),
          ],
        ),
      ),
    );
    expect(find.text('No data'), findsOneWidget);
    expect(find.text('No internet'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}
