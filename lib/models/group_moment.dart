import 'dart:typed_data';

class MomentFailure implements Exception {
  const MomentFailure(this.code, this.message);
  final String code, message;
  @override
  String toString() => message;
}

Map<String, dynamic> momentMap(Object? value) {
  if (value is! Map) {
    throw const MomentFailure(
      'invalid-response',
      'The moment service returned an invalid response.',
    );
  }
  return Map<String, dynamic>.from(value);
}

String momentString(Map<String, dynamic> value, String key) {
  final field = value[key];
  if (field is! String) {
    throw const MomentFailure(
      'invalid-response',
      'The moment service returned an invalid response.',
    );
  }
  return field;
}

DateTime momentDate(Map<String, dynamic> value, String key) =>
    DateTime.parse(momentString(value, key)).toUtc();

bool validMomentId(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value);

class GroupMoment {
  const GroupMoment({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.hobbyName,
    required this.caption,
    required this.publishedAt,
    required this.expiresAt,
  });
  final String id, groupId, authorId, authorName, hobbyName, caption;
  final DateTime publishedAt, expiresAt;
  factory GroupMoment.fromJson(Map<String, dynamic> value) => GroupMoment(
    id: momentString(value, 'momentId'),
    groupId: momentString(value, 'groupId'),
    authorId: momentString(value, 'authorId'),
    authorName: momentString(value, 'authorName'),
    hobbyName: momentString(value, 'hobbyName'),
    caption: momentString(value, 'caption'),
    publishedAt: momentDate(value, 'publishedAt'),
    expiresAt: momentDate(value, 'expiresAt'),
  );
}

class MomentCursor {
  const MomentCursor(this.expiresAtMs, this.momentId);
  final int expiresAtMs;
  final String momentId;
  Map<String, Object> toJson() => {
    'expiresAtMs': expiresAtMs,
    'momentId': momentId,
  };
}

class MomentPage {
  const MomentPage(
    this.items,
    this.serverNow, {
    this.nextCursor,
    this.roundTrip = Duration.zero,
  });
  final List<GroupMoment> items;
  final DateTime serverNow;
  final MomentCursor? nextCursor;
  final Duration roundTrip;
}

class MomentDetail {
  const MomentDetail(
    this.moment,
    this.serverNow, {
    this.roundTrip = Duration.zero,
  });
  final GroupMoment moment;
  final DateTime serverNow;
  final Duration roundTrip;
}

class MomentImage {
  const MomentImage(
    this.bytes,
    this.expiresAt,
    this.serverNow, {
    this.roundTrip = Duration.zero,
  });
  final Uint8List bytes;
  final DateTime expiresAt, serverNow;
  final Duration roundTrip;
}

class MomentUploadTicket {
  const MomentUploadTicket({
    required this.id,
    required this.groupId,
    required this.bucket,
    required this.path,
    required this.deadline,
    required this.status,
  });
  final String id, groupId, bucket, path, status;
  final DateTime deadline;
}

enum MomentPhotoSource { camera, gallery }

class MomentPhoto {
  const MomentPhoto(this.bytes, this.contentType);
  final Uint8List bytes;
  final String contentType;
  static const maxBytes = 5 * 1024 * 1024;
  factory MomentPhoto.checked(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const MomentFailure(
        'invalid-photo',
        'Choose an image smaller than 5 MB.',
      );
    }
    String? mime;
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      mime = 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71) {
      mime = 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      mime = 'image/webp';
    }
    if (mime == null) {
      throw const MomentFailure(
        'invalid-photo',
        'Choose a JPEG, PNG or WebP photo.',
      );
    }
    return MomentPhoto(bytes, mime);
  }
}

abstract class MomentClock {
  DateTime get now;
  void sync(DateTime serverNow, Duration roundTrip);
}

/// Conservatively add the measured round trip; never extend expiry using a stale
/// response or a user-adjusted wall clock. Backend remains the authorization gate.
class MonotonicMomentClock implements MomentClock {
  DateTime? _base;
  final Stopwatch _elapsed = Stopwatch();
  @override
  DateTime get now =>
      (_base ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)).add(
        _elapsed.elapsed,
      );
  @override
  void sync(DateTime serverNow, Duration roundTrip) {
    final candidate = serverNow.toUtc().add(roundTrip);
    final current = now;
    _base = _base != null && current.isAfter(candidate) ? current : candidate;
    _elapsed
      ..reset()
      ..start();
  }
}

class MomentDraft {
  const MomentDraft({
    required this.groupId,
    required this.hobbyId,
    required this.caption,
    required this.requestId,
    this.picking = false,
  });
  final String groupId, hobbyId, caption, requestId;
  final bool picking;
  Map<String, Object> toJson() => {
    'groupId': groupId,
    'hobbyId': hobbyId,
    'caption': caption,
    'requestId': requestId,
    'picking': picking,
  };
}
