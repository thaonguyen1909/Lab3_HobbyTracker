import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hobby_tracker/models/group_moment.dart';
import 'package:hobby_tracker/models/moment_alert.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/local_reminders.dart';
import 'package:hobby_tracker/services/moment_local_notifications.dart';
import 'package:hobby_tracker/viewmodels/moment_alert_controller.dart';
import 'package:hobby_tracker/firebase/moment_background.dart';
import 'support/moment_fakes.dart';
import 'support/moment_alert_fakes.dart';

class ReminderPreferences extends Mock implements SharedPreferencesAsync {
  @override
  Future<String?> getString(String key) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = File('test/fixtures/moment.jpg').readAsBytesSync();
  late TestMomentClock clock;
  late TestMomentRepository moments;
  late TestMomentAlertRepository alerts;
  late MomentAlertController vm;
  late bool owner;
  late Set<String> seen;
  late MomentAlert alert;
  Future<void> settle() async {
    for (var n = 0; n < 6; n++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    clock = TestMomentClock(DateTime.utc(2026, 11, 4));
    moments = TestMomentRepository(clock, bytes);
    moments.moments['m1'] = moments.sample(authorId: 'another-user');
    alerts = TestMomentAlertRepository();
    owner = true;
    seen = {};
    alert = MomentAlert(
      eventId: 'moment_m1',
      groupId: 'g1',
      momentId: 'm1',
      expiresAt: clock.now.add(const Duration(hours: 3)),
    );
    vm = MomentAlertController(
      'owner-001',
      moments,
      alerts,
      clock,
      isOwner: () => owner,
      wasSeen: (event) async => seen.contains(event),
      remember: (event) async {
        seen.add(event);
      },
    );
    vm.configure(enabled: true, groupsEnabled: true, muted: {});
  });
  tearDown(() async {
    vm.dispose();
    await alerts.changes.close();
  });

  test(
    'verifies membership/media then deduplicates stream and push for one event',
    () async {
      vm.receive(alert);
      vm.receive(alert);
      await settle();
      expect(vm.state.popup?.thumbnail?.bytes, bytes);
      expect(seen, {'moment_m1'});
      vm.dismiss();
      vm.receive(alert);
      await settle();
      expect(vm.state.popup, isNull);
    },
  );
  test(
    'Hyper defers all reads and drains only after practice is paused',
    () async {
      vm.contextChanged(active: true, hyperRunning: true);
      vm.receive(alert);
      await settle();
      expect(vm.state.pending, 1);
      expect(vm.state.popup, isNull);
      expect(seen, isEmpty);
      vm.contextChanged(active: true, hyperRunning: false);
      await settle();
      expect(vm.state.popup, isNotNull);
    },
  );
  test(
    'disabled/global groups/muted notifications never load an image',
    () async {
      vm.configure(enabled: false, groupsEnabled: true, muted: {});
      vm.receive(alert);
      await settle();
      expect(vm.state.popup, isNull);
      expect(vm.state.pending, 0);
      vm.configure(enabled: true, groupsEnabled: false, muted: {});
      vm.receive(alert);
      await settle();
      expect(seen, isEmpty);
      vm.configure(enabled: true, groupsEnabled: true, muted: {'g1'});
      vm.receive(alert);
      await settle();
      expect(seen, isEmpty);
    },
  );
  test(
    'server preference denial and removed membership suppress popup',
    () async {
      alerts.permitted = false;
      vm.receive(alert);
      await settle();
      expect(vm.state.popup, isNull);
      alerts.permitted = true;
      moments.readFailure = const MomentFailure('permission-denied', 'Revoked');
      vm.receive(alert);
      await settle();
      expect(vm.state.popup, isNull);
      expect(seen, isEmpty);
    },
  );
  test(
    'account switch during image IO discards bytes and never remembers old event',
    () async {
      moments.imageGate = Completer<MomentImage>();
      vm.receive(alert);
      await settle();
      owner = false;
      moments.imageGate!.complete(
        MomentImage(bytes, alert.expiresAt, clock.now),
      );
      await settle();
      expect(vm.state.popup, isNull);
      expect(seen, isEmpty);
    },
  );
  test('mute while loading prevents late image display', () async {
    moments.imageGate = Completer<MomentImage>();
    vm.receive(alert);
    await settle();
    vm.configure(enabled: true, groupsEnabled: true, muted: {'g1'});
    moments.imageGate!.complete(MomentImage(bytes, alert.expiresAt, clock.now));
    await settle();
    expect(vm.state.popup, isNull);
    expect(seen, isEmpty);
  });
  test('expiry during IO prevents popup and image retention', () async {
    moments.imageGate = Completer<MomentImage>();
    vm.receive(alert);
    await settle();
    clock.value = alert.expiresAt;
    moments.imageGate!.complete(MomentImage(bytes, alert.expiresAt, clock.now));
    await settle();
    expect(vm.state.popup, isNull);
    expect(seen, isEmpty);
  });
  test('background clears image and resume rechecks deferred work', () async {
    vm.contextChanged(active: false, hyperRunning: false);
    vm.receive(alert);
    await settle();
    expect(vm.state.popup, isNull);
    vm.contextChanged(active: true, hyperRunning: false);
    await settle();
    expect(vm.state.popup, isNotNull);
    vm.contextChanged(active: false, hyperRunning: false);
    expect(vm.state.popup, isNull);
  });
  testWidgets(
    'popup disappears at expiry before its normal six-second duration',
    (tester) async {
      vm.dispose();
      vm = MomentAlertController(
        'owner-001',
        moments,
        alerts,
        clock,
        isOwner: () => owner,
        wasSeen: (event) async => seen.contains(event),
        remember: (event) async {
          seen.add(event);
        },
      );
      vm.configure(enabled: true, groupsEnabled: true, muted: {});
      moments.moments['m1'] = moments.sample(
        authorId: 'another',
        life: const Duration(seconds: 2),
      );
      vm.receive(alert);
      await tester.pump();
      await tester.pump();
      expect(vm.state.popup, isNotNull);
      await tester.pump(const Duration(seconds: 2));
      expect(vm.state.popup, isNull);
    },
  );
  test('own post/read event/invalid IDs never become a popup', () async {
    moments.moments['m1'] = moments.sample();
    vm.receive(alert);
    await settle();
    expect(vm.state.popup, isNull);
    expect(
      MomentAlert.parse({...alert.payload('owner-001'), 'groupId': '../g1'}),
      isNull,
    );
    expect(
      MomentAlert.parse({...alert.payload('owner-001'), 'eventId': 'wrong'}),
      isNull,
    );
    expect(isMomentRoute(alert.path), true);
    expect(isMomentRoute('${alert.path}?redirect=https://example.com'), false);
  });
  test(
    'moment and reminder IDs use disjoint namespaces, legacy reminder detection is narrow',
    () {
      expect(isMomentNotificationId(momentNotificationId('u', 'event')), true);
      expect(isMomentNotificationId(reminderNotificationId('u:weekly')), false);
      expect(
        isReminderPayload(jsonEncode({'uid': 'u', 'path': '/home'})),
        true,
      );
      expect(
        isReminderPayload(
          jsonEncode({'uid': 'u', 'path': alert.path, 'kind': 'moment'}),
        ),
        false,
      );
      expect(isReminderPayload('broken'), false);
      expect(supportsMomentExpedited('Android 17 (API 37)'), true);
      expect(supportsMomentExpedited('Android 11 (API 30)'), false);
      expect(supportsMomentExpedited('unknown'), false);
    },
  );
  test(
    'calendar sync cancels only reminder payloads and preserves moment notifications',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final cancelled = <int>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'initialize' ||
                call.method == 'areNotificationsEnabled') {
              return true;
            }
            if (call.method == 'pendingNotificationRequests') {
              return [
                {
                  'id': 5,
                  'title': 'Reminder',
                  'body': '',
                  'payload': jsonEncode({'uid': 'u', 'path': '/home'}),
                },
                {
                  'id': 100,
                  'title': 'Moment',
                  'body': '',
                  'payload': jsonEncode({
                    'uid': 'u',
                    'path': alert.path,
                    'kind': 'moment',
                  }),
                },
              ];
            }
            if (call.method == 'cancel') {
              cancelled.add((call.arguments as Map)['id'] as int);
            }
            if (call.method == 'cancelAll') fail('sync must never cancelAll');
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final reminders = LocalReminders(preferences: ReminderPreferences());
      await reminders.init((_) {});
      await reminders.sync('u', [], [], const AppPreferences());
      expect(cancelled, [5]);
    },
  );
}
