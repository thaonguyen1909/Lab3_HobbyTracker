import 'dart:async';
import '../models/group_moment.dart';

class MomentUploadCancellation {
  bool cancelled = false;
  Future<void> Function()? _handler;
  void bind(Future<void> Function() handler) {
    _handler = handler;
    if (cancelled) unawaited(handler().catchError((Object _) {}));
  }

  void unbind() => _handler = null;
  Future<void> cancel() async {
    cancelled = true;
    try {
      await _handler?.call();
    } catch (_) {
      /* Task may already have finished. */
    }
  }
}

abstract class MomentRepository {
  Future<MomentUploadTicket> begin(String uid, MomentDraft draft);
  Future<void> upload(
    String uid,
    MomentUploadTicket ticket,
    MomentPhoto photo, {
    required void Function(double) progress,
    required MomentUploadCancellation cancellation,
  });
  Future<GroupMoment> publish(String uid, String momentId);
  Future<MomentPage> list(String uid, String groupId, {MomentCursor? cursor});
  Future<MomentDetail> get(String uid, String groupId, String momentId);
  Future<MomentImage> image(
    String uid,
    String groupId,
    String momentId, {
    required bool thumbnail,
  });
  Future<void> retract(String uid, String groupId, String momentId);
}

abstract class MomentPhotoPicker {
  Future<MomentPhoto?> pick(String uid, MomentPhotoSource source);
  Future<MomentPhoto?> recover(String uid);
}

abstract class MomentDraftStore {
  Future<MomentDraft?> read(String uid, String groupId);
  Future<void> save(String uid, MomentDraft draft);
  Future<void> clear(String uid, String groupId);
}
