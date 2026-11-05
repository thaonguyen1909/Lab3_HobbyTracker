import '../l10n/app_strings.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/hobby_data.dart';
import '../services/local_owner_store.dart';
import 'moment_background.dart';

bool allowedNotificationPath(String path) =>
    const [
      '/home',
      '/hobbies',
      '/community/feed',
      '/community/chats',
      '/settings/notifications',
    ].contains(path) ||
    RegExp(
      r'^/community/groups/[A-Za-z0-9_-]{1,128}/moments/[A-Za-z0-9_-]{1,128}$',
    ).hasMatch(path) ||
    RegExp(r'^/community/chat/[A-Za-z0-9._~-]+$').hasMatch(path);

@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessage(RemoteMessage message) async {
  if (message.data['kind'] == 'moment') {
    await enqueueMomentNotification(message.data);
    return;
  }
  await Firebase.initializeApp();
  final store = LocalOwnerStore();
  final uid = await store.prefs.getString('active_owner');
  if (uid == null || message.data['ownerId'] != uid) return;
  final saved = await store.prefs.getString(
    '${store.prefix(uid)}notification_preferences',
  );
  final prefs = AppPreferences.fromJson(
    saved == null ? {} : jsonDecode(saved) as Json,
  );
  final strings = AppStrings(
    await store.prefs.getString('app_language') ?? 'en',
  );
  final kind = message.data['kind'];
  if ((kind == 'message' && !prefs.messages) ||
      (kind == 'group' && !prefs.groups) ||
      (kind == 'weekly' && !prefs.weekly)) {
    return;
  }
  final path = message.data['path'] as String? ?? '/settings/notifications';
  await store.saveNotification(
    uid,
    InboxItem(
      id:
          message.messageId ??
          message.sentTime?.millisecondsSinceEpoch.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: message.notification?.title ?? strings.text('Thông báo'),
      body: message.notification?.body ?? '',
      path: allowedNotificationPath(path) ? path : '/settings/notifications',
      receivedAt: DateTime.now(),
    ),
  );
}
