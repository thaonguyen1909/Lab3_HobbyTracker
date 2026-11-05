import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/models/schedule_draft.dart';
import 'package:hobby_tracker/services/pdf_report_exporter.dart';
import 'package:hobby_tracker/viewmodels/feature_actions.dart';
import 'support/fakes.dart';

void main() {
  final start = DateTime(2026, 11, 4, 20);
  PracticePlan plan(int minutes, {String title = 'Practice'}) => PracticePlan(
    id: 'p',
    hobbyId: 'h',
    title: title,
    startsAt: start,
    minutes: minutes,
  );
  test(
    'duration accepts presets/custom/long sessions and rejects invalid bounds',
    () {
      for (final value in [1, 15, 30, 75, 90, 120, 150, 1440]) {
        expect(() => validatePracticePlan(plan(value)), returnsNormally);
      }
      for (final value in [-1, 0, 1441]) {
        expect(
          () => validatePracticePlan(plan(value)),
          throwsA(isA<DataFailure>()),
        );
      }
      expect(
        () => validatePracticePlan(plan(30, title: ' ')),
        throwsA(isA<DataFailure>()),
      );
    },
  );
  test(
    'single occurrence preserves selected day/time without a repeat end date',
    () {
      expect(scheduleOccurrences(start, ScheduleRepeat.none, null), [start]);
    },
  );
  test(
    'daily end date is inclusive and preserves wall time across month/year',
    () {
      final dates = scheduleOccurrences(
        DateTime(2026, 12, 30, 20, 15),
        ScheduleRepeat.daily,
        DateTime(2027, 1, 2),
      );
      expect(dates.length, 4);
      expect(dates.last, DateTime(2027, 1, 2, 20, 15));
      expect(dates.every((d) => d.hour == 20 && d.minute == 15), true);
    },
  );
  test(
    'weekly repeats same weekday, including leap-day calendar arithmetic',
    () {
      final dates = scheduleOccurrences(
        DateTime(2028, 2, 22, 9),
        ScheduleRepeat.weekly,
        DateTime(2028, 3, 7),
      );
      expect(dates.map((d) => d.day).toList(), [22, 29, 7]);
      expect(dates.map((d) => d.weekday).toSet().length, 1);
    },
  );
  test(
    'rejects missing/inverted/endless ranges and permits exactly 100 sessions',
    () {
      expect(
        () => scheduleOccurrences(start, ScheduleRepeat.daily, null),
        throwsA(isA<DataFailure>()),
      );
      expect(
        () => scheduleOccurrences(
          start,
          ScheduleRepeat.weekly,
          DateTime(2026, 11, 3),
        ),
        throwsA(isA<DataFailure>()),
      );
      expect(
        scheduleOccurrences(
          start,
          ScheduleRepeat.daily,
          DateTime(2026, 11, 4 + 99),
        ).length,
        100,
      );
      expect(
        () => scheduleOccurrences(
          start,
          ScheduleRepeat.daily,
          DateTime(2026, 11, 4 + 100),
        ),
        throwsA(isA<DataFailure>()),
      );
    },
  );
  test(
    'repeated save retries retain IDs/completed state and failures leave no partial series',
    () async {
      final repo = TestRepository(), device = TestDeviceServices();
      final actions = FeatureActions(
        'alice',
        repo,
        device,
        () => PdfReportExporter(),
        () => TestReportUploader(),
      );
      addTearDown(() async {
        actions.dispose();
        await repo.dispose();
      });
      Future<bool> save() => actions.plan(
        hobbyId: 'h',
        title: 'Guitar',
        startsAt: start,
        minutes: 150,
        repeat: ScheduleRepeat.daily,
        until: DateTime(2026, 11, 6),
        requestId: 'stable',
      );
      repo.failWrites = true;
      expect(await save(), false);
      expect(repo.planData['alice'], isNull);
      repo.failWrites = false;
      expect(await save(), true);
      expect(repo.planData['alice']!.length, 3);
      final before = repo.planData['alice']!.keys.toSet(),
          p = repo.planData['alice']!.values.first;
      repo.planData['alice']![p.id] = PracticePlan(
        id: p.id,
        hobbyId: p.hobbyId,
        title: p.title,
        startsAt: p.startsAt,
        minutes: p.minutes,
        done: true,
        completionId: 'history',
      );
      expect(await save(), true);
      expect(repo.planData['alice']!.keys.toSet(), before);
      expect(repo.planData['alice']![p.id]!.done, true);
      expect(repo.planData['alice']![p.id]!.completionId, 'history');
    },
  );
  test('oversized range fails before any repository write', () async {
    final repo = TestRepository(), device = TestDeviceServices();
    final actions = FeatureActions(
      'alice',
      repo,
      device,
      () => PdfReportExporter(),
      () => TestReportUploader(),
    );
    addTearDown(() async {
      actions.dispose();
      await repo.dispose();
    });
    expect(
      await actions.plan(
        hobbyId: 'h',
        title: 'Gym',
        startsAt: start,
        minutes: 75,
        repeat: ScheduleRepeat.daily,
        until: DateTime(2028),
        requestId: 'stable',
      ),
      false,
    );
    expect(repo.writes, 0);
    expect(repo.planData.isEmpty, true);
  });
}
