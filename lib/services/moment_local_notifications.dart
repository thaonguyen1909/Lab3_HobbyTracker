import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../l10n/app_strings.dart';
import '../models/moment_alert.dart';
import 'local_reminders.dart';
import 'local_owner_store.dart';
import 'moment_local_retention.dart';

int momentNotificationId(String uid, String eventId) =>
    0x40000000 | (stableNotificationId('$uid:$eventId') & 0x3fffffff);
bool isMomentNotificationId(int id) => id & 0x40000000 != 0;

class MomentLocalNotifications {
  MomentLocalNotifications(
    this.local, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final LocalOwnerStore local;
  final FlutterLocalNotificationsPlugin plugin;
  Future<void> init() async => plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    ),
  );
  Future<void> show(
    String uid,
    MomentPopup popup,
    Duration remaining, {
    required bool previewOnLockScreen,
  }) async {
    final elapsed = Stopwatch()..start();
    if (remaining <= Duration.zero ||
        await local.prefs.getString('active_owner') != uid) {
      return;
    }
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() != true) return;
    final language = await local.prefs.getString('app_language') ?? 'en';
    final strings = AppStrings(language);
    if (await local.prefs.getString('active_owner') != uid) return;
    final left = remaining - elapsed.elapsed;
    if (left <= Duration.zero) return;
    final id = momentNotificationId(uid, popup.alert.eventId);
    final image = popup.thumbnail;
    await plugin.show(
      id,
      strings.text('New group moment'),
      strings.text('Open to check availability.'),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'group_moments_v1',
          'Group moments',
          importance: Importance.high,
          priority: Priority.high,
          onlyAlertOnce: true,
          visibility: previewOnLockScreen
              ? NotificationVisibility.public
              : NotificationVisibility.private,
          timeoutAfter: left.inMilliseconds,
          styleInformation: image == null
              ? null
              : BigPictureStyleInformation(
                  ByteArrayAndroidBitmap(image.bytes),
                  hideExpandedLargeIcon: true,
                ),
        ),
      ),
      payload: jsonEncode({
        ...popup.alert.payload(uid),
        'uid': uid,
        'path': popup.alert.path,
      }),
    );
    final key = '${local.prefix(uid)}moment_notice_$id';
    await local.prefs.setString(
      key,
      jsonEncode({
        'id': id,
        'groupId': popup.alert.groupId,
        'expiresAt': popup.moment.expiresAt.millisecondsSinceEpoch,
      }),
    );
    if (await local.prefs.getString('active_owner') != uid) {
      await plugin.cancel(id);
      await local.prefs.remove(key);
    }
  }

  Future<int> prune(String uid) => MomentLocalRetention(
    local,
  ).prune(uid, cancelNotice: (id) => plugin.cancel(id));

  Future<void> clear(String uid, {String? groupId}) async {
    for (final key in (await local.prefs.getKeys()).where(
      (k) => k.startsWith('${local.prefix(uid)}moment_notice_'),
    )) {
      try {
        final value =
            jsonDecode(await local.prefs.getString(key) ?? '{}') as Map;
        if (groupId == null || value['groupId'] == groupId) {
          if (value['id'] is int &&
              isMomentNotificationId(value['id'] as int)) {
            await plugin.cancel(value['id'] as int);
          }
          await local.prefs.remove(key);
        }
      } on FormatException {
        await local.prefs.remove(key);
      }
    }
    if (groupId == null) {
      // Includes notifications left after a process died before writing its local index.
      for (final notice in await plugin.getActiveNotifications()) {
        if (notice.id != null && isMomentNotificationId(notice.id!)) {
          await plugin.cancel(notice.id!);
        }
      }
    }
  }
}
