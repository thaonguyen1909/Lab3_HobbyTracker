import '../models/moment_alert.dart';

abstract class MomentAlertRepository {
  Stream<List<MomentAlert>> inbox(String uid);
  Stream<MomentAlertSettings> settings(String uid);
  Stream<Set<String>> mutedGroups(String uid);
  Future<void> saveSettings(String uid, MomentAlertSettings value);
  Future<void> mute(String uid, String groupId, bool muted);
  Future<void> markRead(String uid, String eventId);
  Future<bool> allowed(String uid, String groupId);
  Future<MomentAlertSettings> readSettings(String uid);
}
