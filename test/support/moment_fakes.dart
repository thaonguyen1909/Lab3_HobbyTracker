import 'dart:async';
import 'dart:typed_data';
import 'package:hobby_tracker/models/group_moment.dart';
import 'package:hobby_tracker/services/moment_repository.dart';

class TestMomentClock implements MomentClock {
  TestMomentClock(this.value);
  DateTime value;
  @override
  DateTime get now => value;
  @override
  void sync(DateTime serverNow, Duration roundTrip) =>
      value = serverNow.add(roundTrip);
}

class TestMomentPicker implements MomentPhotoPicker {
  TestMomentPicker(this.photo);
  MomentPhoto? photo, recovered;
  Object? error;
  final pickedBy = <String>[];
  @override
  Future<MomentPhoto?> pick(String uid, MomentPhotoSource source) async {
    pickedBy.add(uid);
    if (error != null) throw error!;
    return photo;
  }

  @override
  Future<MomentPhoto?> recover(String uid) async => recovered;
}

class TestMomentDraftStore implements MomentDraftStore {
  final values = <String, MomentDraft>{};
  String key(String uid, String groupId) => '$uid:$groupId';
  @override
  Future<MomentDraft?> read(String uid, String groupId) async =>
      values[key(uid, groupId)];
  @override
  Future<void> save(String uid, MomentDraft draft) async =>
      values[key(uid, draft.groupId)] = draft;
  @override
  Future<void> clear(String uid, String groupId) async =>
      values.remove(key(uid, groupId));
}

/// Fixtures are only used by tests; production always calls real Firebase APIs.
class TestMomentRepository implements MomentRepository {
  TestMomentRepository(this.clock, this.bytes);
  final TestMomentClock clock;
  final Uint8List bytes;
  final moments = <String, GroupMoment>{};
  final tickets = <String, MomentUploadTicket>{};
  final drafts = <String, MomentDraft>{};
  final calls = <String>[];
  int uploads = 0, publishes = 0, serial = 0;
  bool sourceExists = false,
      failPublishAfterCommit = false,
      failUploadAfterWrite = false;
  MomentFailure? readFailure, publishFailure;
  Completer<void>? uploadGate;
  Completer<MomentImage>? imageGate;
  List<MomentPage>? pages;

  GroupMoment sample({
    String id = 'm1',
    String authorId = 'owner-001',
    Duration life = const Duration(hours: 3),
  }) => GroupMoment(
    id: id,
    groupId: 'g1',
    authorId: authorId,
    authorName: 'Test Member',
    hobbyName: 'Guitar',
    caption: 'User content remains unchanged',
    publishedAt: clock.now,
    expiresAt: clock.now.add(life),
  );

  @override
  Future<MomentUploadTicket> begin(String uid, MomentDraft draft) async {
    calls.add('begin:$uid:${draft.requestId}');
    return tickets.putIfAbsent(draft.requestId, () {
      final id = 'posted${++serial}';
      drafts[id] = draft;
      return MomentUploadTicket(
        id: id,
        groupId: draft.groupId,
        bucket: 'test-only',
        path: 'momentStaging/$uid/$id/source',
        deadline: clock.now.add(const Duration(minutes: 10)),
        status: 'uploading',
      );
    });
  }

  @override
  Future<void> upload(
    String uid,
    MomentUploadTicket ticket,
    MomentPhoto photo, {
    required void Function(double) progress,
    required MomentUploadCancellation cancellation,
  }) async {
    uploads++;
    progress(0.4);
    cancellation.bind(() async {
      if (uploadGate != null && !uploadGate!.isCompleted) {
        uploadGate!.completeError(
          const MomentFailure(
            'cancelled',
            'Upload cancelled. Your draft is kept.',
          ),
        );
      }
    });
    if (uploadGate != null) await uploadGate!.future;
    if (cancellation.cancelled) {
      throw const MomentFailure(
        'cancelled',
        'Upload cancelled. Your draft is kept.',
      );
    }
    sourceExists = true;
    progress(1);
    if (failUploadAfterWrite) {
      failUploadAfterWrite = false;
      throw const MomentFailure(
        'unavailable',
        'Could not upload the photo. Your draft is kept.',
      );
    }
  }

  @override
  Future<GroupMoment> publish(String uid, String momentId) async {
    publishes++;
    if (publishFailure != null) throw publishFailure!;
    if (!sourceExists && !moments.containsKey(momentId)) {
      throw const MomentFailure('failed-precondition', 'Upload image first.');
    }
    final draft = drafts[momentId];
    final moment = moments.putIfAbsent(
      momentId,
      () => GroupMoment(
        id: momentId,
        groupId: draft!.groupId,
        authorId: uid,
        authorName: 'Test Member',
        hobbyName: 'Guitar',
        caption: draft.caption,
        publishedAt: clock.now,
        expiresAt: clock.now.add(const Duration(hours: 3)),
      ),
    );
    if (failPublishAfterCommit) {
      failPublishAfterCommit = false;
      throw const MomentFailure(
        'unavailable',
        'Could not connect to moments. Please try again.',
      );
    }
    return moment;
  }

  @override
  Future<MomentPage> list(
    String uid,
    String groupId, {
    MomentCursor? cursor,
  }) async {
    calls.add('list:$uid:$groupId');
    if (readFailure != null) throw readFailure!;
    if (pages != null && pages!.isNotEmpty) return pages!.removeAt(0);
    return MomentPage(
      moments.values.where((item) => item.groupId == groupId).toList(),
      clock.now,
    );
  }

  @override
  Future<MomentDetail> get(String uid, String groupId, String momentId) async {
    calls.add('get:$uid:$momentId');
    if (readFailure != null) throw readFailure!;
    final moment = moments[momentId];
    if (moment == null) {
      throw const MomentFailure(
        'not-found',
        'This moment has expired or is no longer available.',
      );
    }
    return MomentDetail(moment, clock.now);
  }

  @override
  Future<MomentImage> image(
    String uid,
    String groupId,
    String momentId, {
    required bool thumbnail,
  }) async {
    calls.add('image:$uid:$momentId');
    if (readFailure != null) throw readFailure!;
    if (imageGate != null) return imageGate!.future;
    return MomentImage(bytes, moments[momentId]!.expiresAt, clock.now);
  }

  @override
  Future<void> retract(String uid, String groupId, String momentId) async {
    calls.add('retract:$uid:$momentId');
    moments.remove(momentId);
  }
}
