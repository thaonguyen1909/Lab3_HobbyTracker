import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import '../models/group_moment.dart';
import '../models/moment_alert.dart';
import '../services/local_owner_store.dart';
import '../services/moment_local_notifications.dart';
import '../services/moment_local_retention.dart';
import 'firebase_moment_alert_repository.dart';
import 'moment_repository_factory.dart';

const momentBackgroundTask = 'hobby.moment.notification';
bool supportsMomentExpedited(String osVersion) {
  final api = int.tryParse(
    RegExp(r'\bAPI\s+(\d+)\b').firstMatch(osVersion)?.group(1) ?? '',
  );
  return api != null && api >= 31;
}

Future<void> enqueueMomentNotification(Map<String, dynamic> data) async {
  if (data['kind'] != 'moment' ||
      data['ownerId'] is! String ||
      MomentAlert.parse(data) == null) {
    return;
  }
  final uid = data['ownerId'] as String;
  if (await LocalOwnerStore().prefs.getString('active_owner') != uid) return;
  await Workmanager().registerOneOffTask(
    'moment:$uid:${data['eventId']}',
    momentBackgroundTask,
    inputData: {...data, 'kind': 'moment'},
    tag: 'moment:$uid',
    existingWorkPolicy: ExistingWorkPolicy.keep,
    // This plugin's worker lacks getForegroundInfoAsync for expedited work on
    // pre-Android 12. Unknown/older OS versions safely use regular WorkManager.
    outOfQuotaPolicy: supportsMomentExpedited(Platform.operatingSystemVersion)
        ? OutOfQuotaPolicy.runAsNonExpeditedWorkRequest
        : null,
    constraints: Constraints(networkType: NetworkType.connected),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(seconds: 30),
  );
}

@pragma('vm:entry-point')
void momentWorkerDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != momentBackgroundTask || input == null) return true;
    const localMode = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    if (localMode) {
      return true; // No background/cloud work in isolated development mode.
    }
    try {
      final alert = MomentAlert.parse(input), uid = input['ownerId'];
      if (alert == null || uid is! String) return true;
      final local = LocalOwnerStore();
      final app = await Firebase.initializeApp();
      final auth = FirebaseAuth.instanceFor(app: app);
      bool owner() => auth.currentUser?.uid == uid;
      if (!owner() || await local.prefs.getString('active_owner') != uid) {
        return true;
      }
      await MomentLocalRetention(local).prune(uid);
      final db = FirebaseFirestore.instanceFor(app: app);
      final alerts = FirebaseMomentAlertRepository(db, auth);
      if (!await alerts.allowed(uid, alert.groupId)) return true;
      final seen = '${local.prefix(uid)}moment_seen_${alert.eventId}';
      if (await local.prefs.getBool(seen) == true) return true;
      final repository = createMomentRepository(app);
      final clock = MonotonicMomentClock();
      final detail = await repository
          .get(uid, alert.groupId, alert.momentId)
          .timeout(const Duration(seconds: 20));
      clock.sync(detail.serverNow, detail.roundTrip);
      if (detail.moment.authorId == uid ||
          !detail.moment.expiresAt.isAfter(clock.now)) {
        return true;
      }
      MomentImage? image;
      try {
        image = await repository
            .image(uid, alert.groupId, alert.momentId, thumbnail: true)
            .timeout(const Duration(seconds: 12));
        clock.sync(image.serverNow, image.roundTrip);
      } on TimeoutException {
        /* Verified metadata allows generic text fallback. */
      } on MomentFailure catch (e) {
        if (![
          'unavailable',
          'deadline-exceeded',
          'resource-exhausted',
        ].contains(e.code)) {
          rethrow;
        }
      }
      if (!owner() ||
          await local.prefs.getString('active_owner') != uid ||
          !await alerts.allowed(uid, alert.groupId)) {
        return true;
      }
      final setting = await alerts.readSettings(uid);
      // Revalidate the moment after slow media work, including text fallback.
      final current = await repository
          .get(uid, alert.groupId, alert.momentId)
          .timeout(const Duration(seconds: 20));
      clock.sync(current.serverNow, current.roundTrip);
      final remaining = current.moment.expiresAt.difference(clock.now);
      if (!owner() ||
          remaining <= Duration.zero ||
          await local.prefs.getString('active_owner') != uid) {
        return true;
      }
      final notifications = MomentLocalNotifications(local);
      await notifications.init();
      await notifications.show(
        uid,
        MomentPopup(alert, current.moment, image),
        current.moment.expiresAt.difference(clock.now),
        previewOnLockScreen: setting.previewOnLockScreen,
      );
      if (!owner() || !await alerts.allowed(uid, alert.groupId)) {
        await notifications.clear(uid, groupId: alert.groupId);
        return true;
      }
      await MomentLocalRetention(local).remember(uid, alert.eventId);
      return true;
    } on MomentFailure catch (error) {
      return ![
        'unavailable',
        'deadline-exceeded',
        'aborted',
        'resource-exhausted',
      ].contains(error.code);
    } on FirebaseException catch (error) {
      return ![
        'unavailable',
        'deadline-exceeded',
        'aborted',
        'resource-exhausted',
        'network-request-failed',
      ].contains(error.code);
    } catch (_) {
      return false;
    } // WorkManager backs off; every retry rechecks server expiry and owner.
  });
}
