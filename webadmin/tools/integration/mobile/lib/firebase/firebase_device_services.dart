import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/local_reminders.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hobby_data.dart';
import '../services/device_services.dart';
import '../services/local_owner_store.dart';
import 'notification_background.dart';

class FirebaseDeviceServices implements DeviceServices {
  FirebaseDeviceServices({
    required this.auth,
    required this.db,
    required this.analytics,
    required this.crashes,
    required this.config,
    required this.messaging,
    required this.local,
  });
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseAnalytics analytics;
  final FirebaseCrashlytics crashes;
  final FirebaseRemoteConfig config;
  final FirebaseMessaging messaging;
  final LocalOwnerStore local;
  final _diagnostics = StreamController<String>.broadcast();
  final _opens = StreamController<String>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _reminders = LocalReminders();
  AppPreferences _preferences = const AppPreferences();
  Future<void> _reminderWork = Future.value();
  Future<void> _draftWork = Future.value();
  bool _ownerInitialized = false;
  String? _uid;
  String? _initialPath;
  @override
  Stream<String> get diagnostics => _diagnostics.stream;
  @override
  Stream<String> get notificationOpens async* {
    if (_initialPath != null) {
      yield _initialPath!;
      _initialPath = null;
    }
    yield* _opens.stream;
  }

  Future<void> safe(Future<void> Function() task) async {
    try {
      await task();
    } catch (_) {
      _diagnostics.add(
        'Một dịch vụ Firebase chưa phản hồi. Kiểm tra cấu hình và kết nối.',
      );
    }
  }

  @override
  Future<void> event(String name, Map<String, Object> parameters) =>
      safe(() => analytics.logEvent(name: name, parameters: parameters));
  @override
  Future<void> screen(String name) =>
      safe(() => analytics.logScreenView(screenName: name));
  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String reason = 'handled',
    bool fatal = false,
  }) => safe(
    () => crashes.recordError(error, stack, reason: reason, fatal: fatal),
  );
  @override
  Future<void> setOwner(String? uid) async {
    if (_ownerInitialized && _uid == uid) return;
    _ownerInitialized = true;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    final previous = _uid ?? await local.prefs.getString('active_owner');
    _uid = uid;
    _initialPath = null;
    await _draftWork.catchError((Object _) {});
    await _reminderWork.catchError((Object _) {});
    if (previous != null && previous != uid) await local.clearOwner(previous);
    await local.setOwner(uid);
    await safe(() => analytics.setUserId(id: uid));
    await safe(() => crashes.setUserIdentifier(uid ?? ''));
    await safe(() => crashes.setCustomKey('app_scope', 'lab3'));
    if (uid == null) {
      await safe(_reminders.clear);
      return;
    }
    await safe(
      () => _reminders.init((payload) {
        if (payload == null) return;
        try {
          final data = jsonDecode(payload) as Json;
          if (data['uid'] == _uid &&
              allowedNotificationPath(data['path'] as String)) {
            _opens.add(data['path'] as String);
          }
        } catch (_) {}
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((m) {
        unawaited(_receive(uid, m, false));
      }),
    );
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        unawaited(_receive(uid, m, true));
      }),
    );
    _subscriptions.add(
      messaging.onTokenRefresh.listen((token) {
        unawaited(safe(() => _saveToken(uid, token)));
      }),
    );
    await safe(() async {
      final initial = await messaging.getInitialMessage();
      if (initial != null) await _receive(uid, initial, true, initial: true);
    });
  }

  Future<void> _receive(
    String uid,
    RemoteMessage m,
    bool open, {
    bool initial = false,
  }) async {
    try {
      if (_uid != uid || m.data['ownerId'] != uid) return;
      final kind = m.data['kind'];
      if ((kind == 'message' && !_preferences.messages) ||
          (kind == 'group' && !_preferences.groups) ||
          (kind == 'weekly' && !_preferences.weekly)) {
        return;
      }
      final p = m.data['path'] as String? ?? '/settings/notifications';
      final path = allowedNotificationPath(p) ? p : '/settings/notifications';
      await local.saveNotification(
        uid,
        InboxItem(
          id:
              m.messageId ??
              m.sentTime?.millisecondsSinceEpoch.toString() ??
              DateTime.now().microsecondsSinceEpoch.toString(),
          title: m.notification?.title ?? 'Thông báo',
          body: m.notification?.body ?? '',
          path: path,
          receivedAt: DateTime.now(),
        ),
      );
      if (open) {
        if (initial && !_opens.hasListener) {
          _initialPath = path;
        } else {
          _opens.add(path);
        }
      }
    } catch (_) {
      _diagnostics.add('Không lưu được thông báo trên thiết bị.');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    if (_uid != uid || auth.currentUser?.uid != uid) return;
    final id = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await db.doc('users/$uid/devices/$id').set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> endSession(String? uid) async {
    if (uid != null) {
      await safe(() async {
        final token = await messaging.getToken();
        if (token != null) {
          final id = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
          await db.doc('users/$uid/devices/$id').delete();
        }
        await messaging.deleteToken();
      });
      await local.clearOwner(uid);
    }
    await setOwner(null);
  }

  @override
  Future<RuntimeFlags> flags() async {
    var community = true;
    var feedLimit = 25;
    String? warning;
    try {
      await config.setDefaults({'community_enabled': true, 'feed_limit': 25});
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 1),
      ));
      await config.fetchAndActivate();
      community = config.getBool('community_enabled');
      feedLimit = config.getInt('feed_limit').clamp(1, 100);
    } catch (_) {
      warning = 'Remote Config chưa sẵn sàng; kiểm tra cấu hình quản trị.';
    }
    if (auth.currentUser != null) {
      try {
        final snapshot = await db.doc('appConfig/current').get().timeout(const Duration(seconds: 5));
        final data = snapshot.data();
        if (data != null) {
          return RuntimeFlags(
            community: data['community_enabled'] is bool ? data['community_enabled'] as bool : community,
            feedLimit: data['feed_limit'] is num ? (data['feed_limit'] as num).toInt().clamp(1, 100) : feedLimit,
            maintenance: data['maintenance'] == true,
            minVersion: data['min_version'] is String ? data['min_version'] as String : '0.3.0',
            message: data['message'] is String ? data['message'] as String : '',
          );
        }
      } catch (_) {
        warning = 'Không tải được cấu hình quản trị. Đang dùng Remote Config / mặc định.';
      }
    }
    return RuntimeFlags(community: community, feedLimit: feedLimit, error: warning);
  }

  @override
  Future<String> requestNotifications(String uid) async {
    if (auth.currentUser?.uid != uid) {
      throw const DataFailure('Phiên đăng nhập đã thay đổi.');
    }
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      throw const DataFailure(
        'Bạn đã từ chối thông báo. Có thể bật lại trong Settings của Android.',
      );
    }
    final token = await messaging.getToken();
    if (token == null) {
      throw const DataFailure(
        'Chưa lấy được token FCM. Kiểm tra Google Play Services.',
      );
    }
    await _saveToken(uid, token);
    return 'Đã bật thông báo và đăng ký thiết bị.';
  }

  @override
  Stream<List<InboxItem>> inbox(String uid) async* {
    yield await local.notifications(uid);
    yield* Stream.periodic(
      const Duration(seconds: 2),
    ).asyncMap((_) => local.notifications(uid));
  }

  @override
  Future<void> markRead(String uid, InboxItem item) => local.saveNotification(
    uid,
    InboxItem(
      id: item.id,
      title: item.title,
      body: item.body,
      path: item.path,
      receivedAt: item.receivedAt,
      read: true,
    ),
  );
  @override
  Future<Json?> readDraft(String uid) => local.readDraft(uid);
  @override
  Future<void> writeDraft(String uid, Json? draft) {
    _draftWork = _draftWork.catchError((Object _) {}).then((_) async {
      if (_uid == uid) await local.writeDraft(uid, draft);
    });
    return _draftWork;
  }

  @override
  Future<void> syncReminders(
    String uid,
    List<PracticePlan> plans,
    List<PracticeRecord> history,
    AppPreferences preferences,
  ) {
    _reminderWork = _reminderWork
        .then((_) async {
          if (_uid != uid) return;
          _preferences = preferences;
          await local.prefs.setString(
            '${local.prefix(uid)}notification_preferences',
            jsonEncode(preferences.toJson()),
          );
          await _reminders.sync(uid, plans, history, preferences);
        })
        .catchError((Object _) {
          _diagnostics.add(
            'Chưa lập được nhắc lịch. Kiểm tra quyền thông báo trên Android.',
          );
        });
    return _reminderWork;
  }

  @override
  Future<void> feedback() =>
      safe(() => SystemSound.play(SystemSoundType.alert));
  @override
  Future<void> share(Uint8List bytes) async {
    if (!await Printing.sharePdf(
      bytes: bytes,
      filename: 'HobbyTracker_Report.pdf',
    )) {
      throw const DataFailure('Chưa chia sẻ được PDF. Bạn có thể thử lại.');
    }
  }

  @override
  Future<void> shortcut(String kind, String term) async {
    final q = Uri.encodeQueryComponent(term);
    final url = switch (kind) {
      'spotify' => 'https://open.spotify.com/search/$q',
      'youtube' => 'https://www.youtube.com/results?search_query=$q',
      'coccoc' => 'https://coccoc.com/search?query=$q',
      'google' => 'https://www.google.com/search?q=$q',
      _ => throw const DataFailure('Shortcut không hợp lệ.'),
    };
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw const DataFailure('Không mở được ứng dụng ngoài.');
    }
  }

  @override
  Future<void> crashTest() async {
    if (!kDebugMode || !const bool.fromEnvironment('ENABLE_CRASH_TEST')) {
      throw const DataFailure(
        'Test crash chỉ bật trong debug bằng ENABLE_CRASH_TEST=true.',
      );
    }
    await crashes.setCustomKey('intentional_test', true);
    crashes.crash();
  }
}
