import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/pdf_report_exporter.dart';
import 'package:hobby_tracker/viewmodels/feature_actions.dart';
import 'package:hobby_tracker/viewmodels/hyper_view_model.dart';
import 'package:hobby_tracker/viewmodels/data_providers.dart';
import 'package:hobby_tracker/firebase/notification_background.dart';
import 'package:hobby_tracker/services/local_reminders.dart';
import 'support/fakes.dart';

class TestClock implements ActiveClock {
  int value = 0;
  bool running = false;
  void advance(int ms) {
    if (running) value += ms;
  }

  @override
  int get milliseconds => value;
  @override
  void start() {
    running = true;
  }

  @override
  void stop() {
    running = false;
  }

  @override
  void reset() {
    value = 0;
  }
}

class DelayedDraftDevice extends TestDeviceServices {
  final pending = Completer<Json?>();
  @override
  Future<Json?> readDraft(String uid) => pending.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const h = Hobby(
    id: 'h1',
    name: 'Guitar',
    description: 'Practice',
    icon: 'music',
    color: 'mint',
    priority: 'interested',
  );
  late TestRepository repo;
  late TestDeviceServices device;
  late TestClock clock;
  late HyperViewModel vm;
  late FeatureActions actions;
  setUp(() {
    repo = TestRepository();
    device = TestDeviceServices();
    clock = TestClock();
    vm = HyperViewModel('alice', repo, device, clock: clock, tick: false);
    actions = FeatureActions(
      'alice',
      repo,
      device,
      () => PdfReportExporter(),
      () => TestReportUploader(),
    );
  });
  tearDown(() async {
    vm.dispose();
    actions.dispose();
    await repo.dispose();
  });
  test(
    'custom hobby validation rejects missing name/priority and invalid paths',
    () {
      expect(() => validateHobby(' ', '', null), throwsA(isA<DataFailure>()));
      expect(
        () => validateHobby('Guitar', '', null),
        throwsA(isA<DataFailure>()),
      );
      expect(
        () => validateHobby('a/b', '', 'active'),
        throwsA(isA<DataFailure>()),
      );
      expect(
        () => validateHobby('Vẽ tranh', '', 'interested'),
        returnsNormally,
      );
    },
  );
  test(
    'duplicate draft error leaves first hobby intact and allows recovery',
    () async {
      expect(
        await actions.saveHobby(
          name: 'Guitar',
          description: 'first',
          icon: 'music',
          color: 'mint',
          priority: 'interested',
        ),
        true,
      );
      expect(
        await actions.saveHobby(
          name: ' GUITAR ',
          description: 'second',
          icon: 'music',
          color: 'mint',
          priority: 'active',
        ),
        false,
      );
      expect(repo.hobbyData['alice']!.length, 1);
      expect(repo.hobbyData['alice']!.values.single.description, 'first');
      expect(actions.state.error, contains('tồn tại'));
      expect(
        await actions.saveHobby(
          name: 'Piano',
          description: 'second',
          icon: 'music',
          color: 'mint',
          priority: 'active',
        ),
        true,
      );
    },
  );
  test('both priority values retain plans and history', () async {
    await repo.saveHobby('alice', h);
    await repo.savePlan(
      'alice',
      PracticePlan(
        id: 'p',
        hobbyId: h.id,
        title: 'Practice',
        startsAt: DateTime(2027),
        minutes: 30,
      ),
    );
    await actions.priority(h, 'active');
    expect(repo.planData['alice']!.length, 1);
    await actions.priority(h.withPriority('active'), 'interested');
    expect(repo.planData['alice']!.length, 1);
  });
  test('timer counts only running time and reset retains notes', () async {
    vm.select(h);
    vm.notes('Keep this note');
    vm.start();
    clock.advance(10000);
    vm.pause();
    clock.advance(90000);
    expect(vm.state.elapsedMs, 10000);
    vm.start();
    clock.advance(5000);
    vm.pause();
    expect(vm.state.elapsedMs, 15000);
    vm.reset();
    expect(vm.state.elapsedMs, 0);
    expect(vm.state.notes, 'Keep this note');
  });
  test('Finish writes one record and marks matching plan done', () async {
    await repo.savePlan(
      'alice',
      PracticePlan(
        id: 'p',
        hobbyId: h.id,
        title: 'Practice',
        startsAt: DateTime(2027),
        minutes: 30,
      ),
    );
    vm.select(h, planId: 'p');
    vm.notes('Chord C');
    vm.start();
    clock.advance(3000);
    expect(await vm.finish(h), true);
    expect(await vm.finish(h), false);
    expect(repo.recordData['alice']!.length, 1);
    expect(repo.planData['alice']!['p']!.done, true);
    expect(repo.recordData['alice']!.values.single.notes, 'Chord C');
    expect(device.drafts['alice'], null);
  });
  test(
    'failed Finish preserves session ID, time and notes for idempotent retry',
    () async {
      vm.select(h);
      vm.notes('Do not lose');
      vm.start();
      clock.advance(2000);
      final id = vm.state.sessionId;
      repo.failWrites = true;
      expect(await vm.finish(h), false);
      expect(vm.state.sessionId, id);
      expect(vm.state.elapsedMs, 2000);
      expect(vm.state.notes, 'Do not lose');
      expect(vm.state.saving, false);
      repo.failWrites = false;
      expect(await vm.finish(h), true);
      expect(repo.recordData['alice']!.keys, [id]);
    },
  );
  test(
    'restored draft is paused and cannot be overwritten while storage loads',
    () async {
      final delayed = DelayedDraftDevice(),
          restored = HyperViewModel(
            'alice',
            repo,
            delayed,
            clock: TestClock(),
            tick: false,
          );
      addTearDown(restored.dispose);
      final pending = restored.restore();
      expect(restored.select(h), false);
      delayed.pending.complete({
        'sessionId': 'saved',
        'hobbyId': 'old',
        'planId': 'p',
        'elapsedMs': 4200,
        'notes': 'Saved notes',
      });
      await pending;
      expect(restored.state.hobbyId, 'old');
      expect(restored.state.notes, 'Saved notes');
      expect(restored.state.running, false);
      expect(restored.state.restoring, false);
    },
  );
  test('changing hobby requires explicit discard of an unfinished draft', () {
    vm.select(h);
    vm.notes('draft');
    const other = Hobby(
      id: 'h2',
      name: 'Chess',
      description: '',
      icon: 'chess',
      color: 'blue',
      priority: 'active',
    );
    expect(vm.select(other), false);
    expect(vm.state.hobbyId, 'h1');
    expect(vm.select(other, discard: true), true);
    expect(vm.state.hobbyId, 'h2');
  });
  test('oversized notes rejected before any record is written', () async {
    vm.select(h);
    vm.notes('x' * 2001);
    expect(await vm.finish(h), false);
    expect(repo.recordData['alice'], null);
  });
  test('background policy pauses only when preference is enabled', () {
    vm.select(h);
    vm.start();
    clock.advance(1000);
    vm.onBackground(false);
    expect(vm.state.running, true);
    vm.onBackground(true);
    expect(vm.state.running, false);
    expect(vm.state.elapsedMs, 1000);
  });
  test(
    'daily plans filter archived/missing hobbies and sort chronologically',
    () {
      final day = DateTime(2027, 1, 1);
      final plans = [
        PracticePlan(
          id: 'late',
          hobbyId: 'h1',
          title: 'later',
          startsAt: DateTime(2027, 1, 1, 15),
          minutes: 30,
        ),
        PracticePlan(
          id: 'early',
          hobbyId: 'h1',
          title: 'early',
          startsAt: DateTime(2027, 1, 1, 9),
          minutes: 30,
        ),
        PracticePlan(
          id: 'missing',
          hobbyId: 'other',
          title: 'removed',
          startsAt: DateTime(2027, 1, 1, 8),
          minutes: 30,
        ),
      ];
      expect(visiblePlans(plans, [h], day).map((p) => p.id), ['early', 'late']);
    },
  );
  test(
    'RSVP does not create a plan; Add to Home is explicit and idempotent',
    () async {
      final event = SocialEntry(
        id: 'e1',
        data: {'title': 'Practice', 'startsAt': DateTime(2027)},
      );
      expect(await actions.rsvp(event.id, true), true);
      expect(repo.planData['alice'], null);
      expect(await actions.addEvent(event, h), true);
      expect(await actions.addEvent(event, h), true);
      expect(repo.planData['alice']!.length, 1);
      expect(await actions.rsvp(event.id, false), true);
      expect(repo.planData['alice'], isEmpty);
    },
  );
  test(
    'message retry reuses draft ID and failed text is available to caller',
    () async {
      repo.failWrites = true;
      expect(await actions.send('chat', false, 'hello', 'draft'), false);
      repo.failWrites = false;
      expect(await actions.send('chat', false, 'hello', 'draft'), true);
      expect(await actions.send('chat', false, 'hello', 'draft'), true);
      expect(repo.messageData['chat']!.length, 1);
    },
  );
  test(
    'notification deep links reject arbitrary URLs and unrelated routes',
    () {
      expect(allowedNotificationPath('/home'), true);
      expect(allowedNotificationPath('/community/chat/alice.bob'), true);
      expect(allowedNotificationPath('https://evil.invalid'), false);
      expect(allowedNotificationPath('/settings/delete-all'), false);
      expect(
        stableNotificationId('alice:p1'),
        stableNotificationId('alice:p1'),
      );
      expect(
        stableNotificationId('alice:p1'),
        isNot(stableNotificationId('bob:p1')),
      );
    },
  );
  test(
    'PDF exporter creates real bytes including multi-page Vietnamese notes',
    () async {
      final records = List.generate(
        50,
        (i) => PracticeRecord(
          id: 'r$i',
          hobbyId: h.id,
          name: 'Đàn guitar',
          icon: h.icon,
          color: h.color,
          elapsedMs: 61000,
          notes: 'Học hợp âm và luyện tập — buổi $i',
          finishedAt: DateTime(2026, 11, 3),
        ),
      );
      final bytes = await PdfReportExporter().export([h], records);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(5000));
    },
  );
  test(
    'export does not imply cloud upload; receipt appears only after upload',
    () async {
      expect(await actions.exportReport([h], []), true);
      expect(actions.state.pdf, isNotNull);
      expect(actions.state.receipt, null);
      expect(await actions.uploadReport(), true);
      expect(actions.state.receipt!.path, startsWith('reports/alice/'));
      expect(device.logged, containsAll(['export_report', 'upload_report']));
    },
  );
  test(
    'telemetry action parameters never include display names or e-mail',
    () async {
      await actions.saveHobby(
        name: 'PRIVATE hobby',
        description: '',
        icon: 'music',
        color: 'mint',
        priority: 'active',
      );
      expect(device.logged, contains('create_hobby'));
      expect(device.parameters.toString(), isNot(contains('PRIVATE hobby')));
      expect(device.parameters.expand((p) => p.keys), isNot(contains('email')));
    },
  );
}
