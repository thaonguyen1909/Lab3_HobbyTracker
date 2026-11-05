import 'dart:async';
import 'package:hobby_tracker/models/moment_alert.dart';
import 'package:hobby_tracker/services/moment_alert_repository.dart';

class TestMomentAlertRepository implements MomentAlertRepository {
  MomentAlertSettings value = const MomentAlertSettings(enabled: true);
  Set<String> muted = {};
  List<MomentAlert> entries = [];
  bool permitted = true;
  final changes = StreamController<void>.broadcast();
  void emit() => changes.add(null);
  @override
  Stream<List<MomentAlert>> inbox(String uid) async* {
    yield entries;
    yield* changes.stream.map((_) => entries);
  }

  @override
  Stream<MomentAlertSettings> settings(String uid) async* {
    yield value;
    yield* changes.stream.map((_) => value);
  }

  @override
  Stream<Set<String>> mutedGroups(String uid) async* {
    yield muted;
    yield* changes.stream.map((_) => muted);
  }

  @override
  Future<bool> allowed(String uid, String groupId) async =>
      permitted && value.enabled && !muted.contains(groupId);
  @override
  Future<MomentAlertSettings> readSettings(String uid) async => value;
  @override
  Future<void> saveSettings(String uid, MomentAlertSettings value) async {
    this.value = value;
    emit();
  }

  @override
  Future<void> mute(String uid, String groupId, bool muted) async {
    muted ? this.muted.add(groupId) : this.muted.remove(groupId);
    emit();
  }

  @override
  Future<void> markRead(String uid, String eventId) async {
    entries = entries
        .map(
          (a) => a.eventId == eventId
              ? MomentAlert(
                  eventId: a.eventId,
                  groupId: a.groupId,
                  momentId: a.momentId,
                  expiresAt: a.expiresAt,
                  read: true,
                )
              : a,
        )
        .toList();
    emit();
  }
}
