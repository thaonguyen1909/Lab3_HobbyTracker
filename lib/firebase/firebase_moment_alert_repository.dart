import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_moment.dart';
import '../models/moment_alert.dart';
import '../services/moment_alert_repository.dart';
import '../services/moment_local_notifications.dart';
import '../services/local_owner_store.dart';
import 'package:workmanager/workmanager.dart';

class FirebaseMomentAlertRepository implements MomentAlertRepository {
  FirebaseMomentAlertRepository(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  void _owner(String uid) {
    if (uid.isEmpty || auth.currentUser?.uid != uid) {
      throw const MomentFailure(
        'unauthenticated',
        'Your account changed. Please sign in again.',
      );
    }
  }

  DocumentReference<Map<String, dynamic>> _settings(String uid) =>
      db.doc('users/$uid/settings/momentNotifications');
  MomentAlertSettings _decode(Map<String, dynamic>? data) =>
      MomentAlertSettings(
        enabled: data?['enabled'] == true,
        previewOnLockScreen: data?['previewOnLockScreen'] == true,
      );
  @override
  Stream<List<MomentAlert>> inbox(String uid) {
    _owner(uid);
    return db
        .collection('users/$uid/momentInbox')
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          _owner(uid);
          return snapshot.docs
              .map((doc) {
                final data = doc.data(), expiry = doc.data()['expiresAt'];
                return MomentAlert.parse({
                  ...data,
                  'expiresAt': expiry is Timestamp
                      ? expiry.toDate().toIso8601String()
                      : null,
                });
              })
              .whereType<MomentAlert>()
              .toList();
        });
  }

  @override
  Stream<MomentAlertSettings> settings(String uid) {
    _owner(uid);
    return _settings(uid).snapshots().map((d) {
      _owner(uid);
      return _decode(d.data());
    });
  }

  @override
  Stream<Set<String>> mutedGroups(String uid) {
    _owner(uid);
    return db.collection('users/$uid/momentGroupSettings').snapshots().map((s) {
      _owner(uid);
      return s.docs
          .where((d) => d.data()['muted'] == true)
          .map((d) => d.id)
          .toSet();
    });
  }

  @override
  Future<void> saveSettings(String uid, MomentAlertSettings value) async {
    _owner(uid);
    await _settings(uid).set(value.toJson());
    _owner(uid);
    try {
      await MomentLocalNotifications(LocalOwnerStore()).clear(uid);
      if (!value.enabled) await Workmanager().cancelByTag('moment:$uid');
    } catch (_) {
      /* Permission is also enforced by every new worker/API read. */
    }
  }

  @override
  Future<void> mute(String uid, String groupId, bool muted) async {
    _owner(uid);
    await db.doc('users/$uid/momentGroupSettings/$groupId').set({
      'muted': muted,
    });
    _owner(uid);
    if (muted) {
      try {
        await MomentLocalNotifications(
          LocalOwnerStore(),
        ).clear(uid, groupId: groupId);
      } catch (_) {}
    }
  }

  @override
  Future<void> markRead(String uid, String eventId) async {
    _owner(uid);
    await db.doc('users/$uid/momentInbox/$eventId').update({'read': true});
    _owner(uid);
  }

  @override
  Future<MomentAlertSettings> readSettings(String uid) async {
    _owner(uid);
    final doc = await _settings(
      uid,
    ).get(const GetOptions(source: Source.server));
    _owner(uid);
    return _decode(doc.data());
  }

  @override
  Future<bool> allowed(String uid, String groupId) async {
    _owner(uid);
    final docs = await Future.wait([
      _settings(uid).get(const GetOptions(source: Source.server)),
      db
          .doc('users/$uid/momentGroupSettings/$groupId')
          .get(const GetOptions(source: Source.server)),
      db
          .doc('users/$uid/settings/preferences')
          .get(const GetOptions(source: Source.server)),
    ]);
    _owner(uid);
    return _decode(docs[0].data()).enabled &&
        docs[1].data()?['muted'] != true &&
        docs[2].data()?['groups'] != false;
  }
}
