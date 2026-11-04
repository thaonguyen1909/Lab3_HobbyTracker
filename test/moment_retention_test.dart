import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hobby_tracker/models/group_moment.dart';
import 'package:hobby_tracker/models/moment_alert.dart';
import 'package:hobby_tracker/services/local_owner_store.dart';
import 'package:hobby_tracker/services/moment_local_notifications.dart';
import 'package:hobby_tracker/services/moment_local_retention.dart';

class RetentionPreferences extends Mock implements SharedPreferencesAsync {
  final values = <String, Object>{'active_owner': 'alice'};
  final afterIntWrite = <void Function()>[];
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async =>
      Map.fromEntries(
        values.entries.where(
          (e) => allowList == null || allowList.contains(e.key),
        ),
      );
  @override
  Future<void> setInt(String key, int value) async {
    values[key] = value;
    for (final hook in afterIntWrite) {
      hook();
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class NoticePlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class AndroidNoticePlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late RetentionPreferences prefs;
  late LocalOwnerStore local;
  late MomentLocalRetention retention;
  late DateTime now;
  setUpAll(() => registerFallbackValue(const NotificationDetails()));
  setUp(() {
    prefs = RetentionPreferences();
    local = LocalOwnerStore(preferences: prefs);
    now = DateTime.utc(2026, 11, 4);
    retention = MomentLocalRetention(local, now: () => now);
  });
  test(
    'prunes expired owner markers and notices, preserving live markers, other UID, Hyper and preferences',
    () async {
      final prefix = local.prefix('alice'),
          other = local.prefix('bob'),
          id = momentNotificationId('alice', 'old');
      prefs.values.addAll({
        '${prefix}moment_seen_old': true,
        '${prefix}moment_seen_expiry_old': now.millisecondsSinceEpoch - 1,
        '${prefix}moment_seen_live': true,
        '${prefix}moment_seen_expiry_live': now.millisecondsSinceEpoch + 10000,
        '${prefix}moment_notice_$id': jsonEncode({
          'id': id,
          'expiresAt': now.millisecondsSinceEpoch - 1,
          'groupId': 'g1',
        }),
        '${other}moment_seen_old': true,
        '${prefix}hyper_draft': 'KEEP DRAFT',
        '${prefix}notification_preferences': 'KEEP SETTINGS',
      });
      final cancelled = <int>[];
      expect(
        await retention.prune(
          'alice',
          cancelNotice: (value) async {
            cancelled.add(value);
          },
        ),
        2,
      );
      expect(cancelled, [id]);
      expect(prefs.values['${prefix}moment_seen_old'], isNull);
      expect(prefs.values['${prefix}moment_seen_live'], true);
      expect(prefs.values['${other}moment_seen_old'], true);
      expect(prefs.values['${prefix}hyper_draft'], 'KEEP DRAFT');
      expect(
        prefs.values['${prefix}notification_preferences'],
        'KEEP SETTINGS',
      );
    },
  );
  test(
    'legacy markers migrate conservatively and expire on a later pass',
    () async {
      final prefix = local.prefix('alice'),
          id = momentNotificationId('alice', 'legacy');
      prefs.values.addAll({
        '${prefix}moment_seen_legacy': true,
        '${prefix}moment_notice_$id': jsonEncode({'id': id, 'groupId': 'g1'}),
      });
      final cancelled = <int>[];
      Future<void> cancel(int value) async {
        cancelled.add(value);
      }

      await retention.prune('alice', cancelNotice: cancel);
      expect(prefs.values['${prefix}moment_seen_legacy'], true);
      expect(cancelled, isEmpty);
      now = now.add(const Duration(hours: 25));
      expect(await retention.prune('alice', cancelNotice: cancel), 2);
      expect(cancelled, [id]);
    },
  );
  test('failed OS cancellation preserves notice index for retry', () async {
    final key = '${local.prefix('alice')}moment_notice_1',
        id = momentNotificationId('alice', 'x');
    prefs.values[key] = jsonEncode({
      'id': id,
      'expiresAt': now.millisecondsSinceEpoch - 1,
    });
    await expectLater(
      retention.prune(
        'alice',
        cancelNotice: (_) async {
          throw StateError('Test native failure');
        },
      ),
      throwsStateError,
    );
    expect(prefs.values[key], isNotNull);
    await retention.prune('alice', cancelNotice: (_) async {});
    expect(prefs.values[key], isNull);
  });
  test(
    'garbage collection ignores non-owner and never cancels a reminder ID',
    () async {
      final key = '${local.prefix('alice')}moment_notice_1';
      prefs.values[key] = jsonEncode({'id': 1, 'expiresAt': 0});
      final cancelled = <int>[];
      expect(
        await retention.prune(
          'bob',
          cancelNotice: (id) async {
            cancelled.add(id);
          },
        ),
        0,
      );
      await retention.prune(
        'alice',
        cancelNotice: (id) async {
          cancelled.add(id);
        },
      );
      expect(cancelled, isEmpty);
    },
  );
  test(
    'remembered marker has bounded lifetime and account switch cannot recreate old owner data',
    () async {
      await retention.remember('alice', 'event');
      final prefix = local.prefix('alice');
      expect(
        prefs.values['${prefix}moment_seen_expiry_event'],
        now.add(const Duration(days: 1)).millisecondsSinceEpoch,
      );
      prefs.afterIntWrite.add(() {
        prefs.values['active_owner'] = 'bob';
        prefs.values.removeWhere((key, _) => key.startsWith(prefix));
      });
      await retention.remember('alice', 'late');
      expect(prefs.values.keys.where((key) => key.startsWith(prefix)), isEmpty);
    },
  );
  test('legacy migration cannot resurrect a cleared owner prefix', () async {
    final prefix = local.prefix('alice');
    prefs.values['${prefix}moment_seen_legacy'] = true;
    prefs.afterIntWrite.add(() {
      prefs.values['active_owner'] = 'bob';
      prefs.values.removeWhere((key, _) => key.startsWith(prefix));
    });
    await retention.prune('alice');
    expect(prefs.values.keys.where((key) => key.startsWith(prefix)), isEmpty);
  });
  MomentPopup popup() => MomentPopup(
    MomentAlert(
      eventId: 'moment_m1',
      groupId: 'g1',
      momentId: 'm1',
      expiresAt: now.add(const Duration(hours: 3)),
    ),
    GroupMoment(
      id: 'm1',
      groupId: 'g1',
      authorId: 'bob',
      authorName: 'Bob',
      hobbyName: 'Badminton',
      caption: '',
      publishedAt: now,
      expiresAt: now.add(const Duration(hours: 3)),
    ),
    null,
  );
  test(
    'late account switch during permission lookup prevents notification display',
    () async {
      final plugin = NoticePlugin(),
          android = AndroidNoticePlugin(),
          gate = Completer<bool>();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(
        () => android.areNotificationsEnabled(),
      ).thenAnswer((_) => gate.future);
      final work = MomentLocalNotifications(local, plugin: plugin).show(
        'alice',
        popup(),
        const Duration(minutes: 1),
        previewOnLockScreen: false,
      );
      await Future<void>.delayed(Duration.zero);
      prefs.values['active_owner'] = 'bob';
      gate.complete(true);
      await work;
      verifyNever(
        () => plugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        ),
      );
    },
  );
  test(
    'elapsed permission lookup cannot display a notification after its remaining lifetime',
    () async {
      final plugin = NoticePlugin(), android = AndroidNoticePlugin();
      when(
        () => plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >(),
      ).thenReturn(android);
      when(() => android.areNotificationsEnabled()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return true;
      });
      await MomentLocalNotifications(local, plugin: plugin).show(
        'alice',
        popup(),
        const Duration(milliseconds: 1),
        previewOnLockScreen: false,
      );
      verifyNever(
        () => plugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        ),
      );
    },
  );
}
