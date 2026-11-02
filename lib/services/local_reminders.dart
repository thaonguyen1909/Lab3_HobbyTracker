import '../l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/hobby_data.dart';

int stableNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(key)) {
    hash = ((hash ^ byte) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

class LocalReminders {
  final plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> init(void Function(String?) onOpen) async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (response) => onOpen(response.payload),
    );
    _ready = true;
  }

  Future<void> clear() async {
    if (_ready) await plugin.cancelAll();
  }

  Future<void> sync(
    String uid,
    List<PracticePlan> plans,
    List<PracticeRecord> history,
    AppPreferences p,
  ) async {
    if (!_ready) return;
    await plugin.cancelAll();
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() != true) {
      return;
    }
    final language =
        await SharedPreferencesAsync().getString('app_language') ?? 'en';
    final strings = AppStrings(language);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'practice_reminders_$language',
        strings.text('Nhắc luyện tập'),
        channelDescription: strings.text(
          'Lịch luyện tập và tóm tắt do bạn bật',
        ),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    if (p.reminders) {
      for (final plan in plans.where((x) => !x.done)) {
        final at = plan.startsAt.subtract(Duration(minutes: p.leadMinutes));
        if (!at.isAfter(DateTime.now())) continue;
        await plugin.zonedSchedule(
          stableNotificationId('$uid:${plan.id}'),
          strings.text('Đến giờ luyện tập'),
          plan.title,
          tz.TZDateTime.from(at.toUtc(), tz.UTC),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode({'uid': uid, 'path': '/home'}),
        );
      }
    }
    if (p.weekly) {
      final now = DateTime.now();
      var next = DateTime(now.year, now.month, now.day + (8 - now.weekday), 9);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 7));
      final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final records = history.where(
        (r) => !r.finishedAt.toLocal().isBefore(start),
      );
      final minutes = records.fold<int>(0, (n, r) => n + r.elapsedMs) ~/ 60000;
      await plugin.zonedSchedule(
        stableNotificationId('$uid:weekly'),
        strings.text('Một tuần cùng sở thích'),
        strings.text(
          '$minutes phút luyện tập đã được ghi nhận trong tuần này.',
        ),
        tz.TZDateTime.from(next.toUtc(), tz.UTC),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({'uid': uid, 'path': '/home'}),
      );
    }
  }
}
