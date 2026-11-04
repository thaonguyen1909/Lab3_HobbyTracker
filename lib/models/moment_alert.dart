import 'group_moment.dart';
import '../app/router/route_paths.dart';

bool isMomentRoute(String path) => RegExp(
  r'^/community/groups/[A-Za-z0-9_-]{1,128}/moments/[A-Za-z0-9_-]{1,128}$',
).hasMatch(path);

class MomentAlert {
  const MomentAlert({
    required this.eventId,
    required this.groupId,
    required this.momentId,
    required this.expiresAt,
    this.read = false,
  });
  final String eventId, groupId, momentId;
  final DateTime expiresAt;
  final bool read;
  String get path => RoutePaths.groupMoment(groupId, momentId);
  Map<String, Object> payload(String uid) => {
    'kind': 'moment',
    'ownerId': uid,
    'eventId': eventId,
    'groupId': groupId,
    'momentId': momentId,
    'expiresAt': expiresAt.toIso8601String(),
  };
  static MomentAlert? parse(Map<String, dynamic> data) {
    final gid = data['groupId'],
        mid = data['momentId'],
        event = data['eventId'];
    final expires = DateTime.tryParse(data['expiresAt']?.toString() ?? '');
    if (gid is! String ||
        mid is! String ||
        !validMomentId(gid) ||
        !validMomentId(mid) ||
        event != 'moment_$mid' ||
        expires == null) {
      return null;
    }
    return MomentAlert(
      eventId: event as String,
      groupId: gid,
      momentId: mid,
      expiresAt: expires.toUtc(),
      read: data['read'] == true,
    );
  }
}

class MomentAlertSettings {
  const MomentAlertSettings({
    this.enabled = false,
    this.previewOnLockScreen = false,
  });
  final bool enabled, previewOnLockScreen;
  Map<String, Object> toJson() => {
    'enabled': enabled,
    'previewOnLockScreen': previewOnLockScreen,
  };
}

class MomentPopup {
  const MomentPopup(this.alert, this.moment, this.thumbnail);
  final MomentAlert alert;
  final GroupMoment moment;
  final MomentImage? thumbnail;
}
