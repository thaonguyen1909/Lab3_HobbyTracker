import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/app.dart';
import 'package:hobby_tracker/features/practice/screens/practice_screens.dart';
import 'package:hobby_tracker/l10n/app_strings.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/models/schedule_draft.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/widgets/feature_widgets.dart';
import 'full_ui_test.dart' show mount;
import 'support/fakes.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<TestRepository> open(
    WidgetTester tester, {
    double width = 360,
    String language = 'vi',
    ScheduleRepeat repeat = ScheduleRepeat.none,
  }) async {
    final container = await mount(
      tester,
      width: width,
      languageStore: TestLanguageStore(code: language),
    );
    final repo = container.read(repositoryProvider) as TestRepository;
    repo.hobbyData['owner-001'] = {
      for (final (id, name, icon) in [
        ('h1', 'Guitar', 'music'),
        ('h2', 'Gym', 'fitness'),
        ('h3', 'Đọc sách', 'book'),
        ('h4', 'Vẽ', 'palette'),
      ])
        id: Hobby(
          id: id,
          name: name,
          description: '',
          icon: icon,
          color: 'mint',
          priority: 'interested',
        ),
    };
    repo.emit();
    await tester.pumpAndSettle();
    unawaited(
      showEditor(
        tester.element(find.byType(HomeScreen)),
        PlanEditor(
          initialDay: DateTime(2026, 11, 4),
          initialTime: const TimeOfDay(hour: 20, minute: 0),
          initialMinutes: 120,
          initialRepeat: repeat,
        ),
        showClose: false,
        dismissible: false,
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  for (final width in [360.0, 412.0]) {
    for (final language in ['vi', 'en']) {
      testWidgets(
        'quick schedule layout/date/autofill and 2h save at $width $language',
        (tester) async {
          final repo = await open(tester, width: width, language: language);
          final strings = AppStrings(language);
          expect(
            find.text(strings.text('Schedule focus time')),
            findsOneWidget,
          );
          expect(find.byType(DropdownButtonFormField<int>), findsNothing);
          final input = tester.widget<TextField>(
            find.byKey(const ValueKey('plan-title')),
          );
          expect(
            input.controller!.text,
            strings.text('Practice {0}').replaceAll('{0}', 'Guitar'),
          );
          expect(
            tester
                .widget<ChoiceChip>(find.byKey(const ValueKey('duration-120')))
                .selected,
            true,
          );
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('CAPTURE_SCHEDULES')) {
            await expectLater(
              find.byType(HobbyTrackerApp),
              matchesGoldenFile(
                'schedule_review/schedule_${width.toInt()}_$language.png',
              ),
            );
          }
          final save = find.byKey(const ValueKey('save-schedule'));
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          final created = repo.planData['owner-001']!.values.single;
          expect(created.minutes, 120);
          expect(created.startsAt, DateTime(2026, 11, 4, 20));
          expect(created.hobbyId, 'h1');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'custom 75 minutes validates integer bounds and preserves draft after write failure',
    (tester) async {
      final repo = await open(tester, language: 'en');
      final custom = find.byKey(const ValueKey('custom-duration'));
      await tester.ensureVisible(custom);
      await tester.tap(custom);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('custom-minutes')), '0');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a whole number from 1 to 1440.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('custom-minutes')),
        '75',
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('plan-title')),
        'My practice',
      );
      repo.failWrites = true;
      final save = find.byKey(const ValueKey('save-schedule'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('plan-title')))
            .controller!
            .text,
        'My practice',
      );
      expect(repo.planData['owner-001'], isNull);
      repo.failWrites = false;
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.planData['owner-001']!.values.single.minutes, 75);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'hobby changes update automatic title but retain manually edited name',
    (tester) async {
      await open(tester, language: 'en');
      await tester.tap(find.text('Gym'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('plan-title')))
            .controller!
            .text,
        'Practice Gym',
      );
      await tester.enterText(
        find.byKey(const ValueKey('plan-title')),
        'My own session',
      );
      await tester.tap(find.text('Đọc sách'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('plan-title')))
            .controller!
            .text,
        'My own session',
      );
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vẽ'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('plan-title')))
            .controller!
            .text,
        'My own session',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'weekly repeat has real end-date picker and creates five sessions atomically',
    (tester) async {
      final repo = await open(
        tester,
        language: 'en',
        repeat: ScheduleRepeat.weekly,
      );
      final end = find.byKey(const ValueKey('repeat-until'));
      await tester.ensureVisible(end);
      await tester.tap(end);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-schedule'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final plans = repo.planData['owner-001']!.values.toList();
      expect(plans.length, 5);
      expect(plans.map((p) => p.startsAt.weekday).toSet().length, 1);
      expect(plans.every((p) => p.minutes == 120), true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('daily option and 200 percent text remain usable at 360dp', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = await open(
      tester,
      language: 'vi',
      repeat: ScheduleRepeat.daily,
    );
    final save = find.byKey(const ValueKey('save-schedule'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.planData['owner-001']!.length, 29);
    expect(tester.takeException(), isNull);
  });
}
