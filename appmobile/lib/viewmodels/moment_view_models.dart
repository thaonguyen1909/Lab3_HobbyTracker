import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/group_moment.dart';
import '../services/moment_repository.dart';

String momentErrorText(Object error) => error is MomentFailure
    ? error.message
    : 'Could not connect to moments. Please try again.';

class MomentComposerState {
  const MomentComposerState({
    required this.draft,
    this.photo,
    this.restoring = false,
    this.busy = false,
    this.picking = false,
    this.publishing = false,
    this.uncertain = false,
    this.progress = 0,
    this.error,
    this.posted,
  });
  final MomentDraft draft;
  final MomentPhoto? photo;
  final bool restoring, busy, picking, publishing, uncertain;
  final double progress;
  final String? error;
  final GroupMoment? posted;
  MomentComposerState copy({
    MomentDraft? draft,
    MomentPhoto? photo,
    bool? restoring,
    bool? busy,
    bool? picking,
    bool? publishing,
    bool? uncertain,
    double? progress,
    String? error,
    bool clearError = false,
    GroupMoment? posted,
  }) => MomentComposerState(
    draft: draft ?? this.draft,
    photo: photo ?? this.photo,
    restoring: restoring ?? this.restoring,
    busy: busy ?? this.busy,
    picking: picking ?? this.picking,
    publishing: publishing ?? this.publishing,
    uncertain: uncertain ?? this.uncertain,
    progress: progress ?? this.progress,
    error: clearError ? null : error ?? this.error,
    posted: posted ?? this.posted,
  );
}

class MomentComposer extends StateNotifier<MomentComposerState> {
  MomentComposer(
    this.uid,
    String groupId,
    this.repository,
    this.picker,
    this.store, {
    String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4,
       super(
         MomentComposerState(
           restoring: true,
           draft: MomentDraft(
             groupId: groupId,
             hobbyId: '',
             caption: '',
             requestId: (newId ?? const Uuid().v4)(),
           ),
         ),
       );
  final String uid;
  final MomentRepository repository;
  final MomentPhotoPicker picker;
  final MomentDraftStore store;
  final String Function() _newId;
  MomentUploadTicket? _ticket;
  MomentUploadCancellation? _cancellation;
  bool _uploaded = false, _uploadAttempted = false;
  int _revision = 0;
  Future<void> _saving = Future.value();

  Future<void> restore() async {
    try {
      final saved = await store.read(uid, state.draft.groupId);
      if (!mounted) return;
      if (saved != null && saved.groupId == state.draft.groupId) {
        state = state.copy(draft: saved);
      }
      final recovered = await picker.recover(uid);
      if (!mounted) return;
      if (recovered != null) {
        state = state.copy(photo: recovered, draft: _draft(newRequest: true));
      }
      state = state.copy(restoring: false);
    } catch (error) {
      if (mounted) {
        state = state.copy(restoring: false, error: momentErrorText(error));
      }
    }
  }

  MomentDraft _draft({
    String? hobbyId,
    String? caption,
    bool picking = false,
    bool newRequest = false,
  }) => MomentDraft(
    groupId: state.draft.groupId,
    hobbyId: hobbyId ?? state.draft.hobbyId,
    caption: caption ?? state.draft.caption,
    requestId: newRequest ? _newId() : state.draft.requestId,
    picking: picking,
  );

  Future<void> _persist({bool picking = false}) {
    final snapshot = _draft(picking: picking);
    _saving = _saving.then((_) => store.save(uid, snapshot)).catchError((
      Object _,
    ) {
      if (mounted && state.error == null) {
        state = state.copy(
          error:
              'Could not save the draft on this device. Keep this screen open and retry.',
        );
      }
    });
    return _saving;
  }

  void edit({String? hobbyId, String? caption}) {
    if (state.busy ||
        state.restoring ||
        state.uncertain ||
        state.posted != null) {
      return;
    }
    _ticket = null;
    _uploaded = false;
    _uploadAttempted = false;
    state = state.copy(
      draft: _draft(hobbyId: hobbyId, caption: caption, newRequest: true),
      clearError: true,
    );
    unawaited(_persist());
  }

  Future<void> choosePhoto(MomentPhotoSource source) async {
    if (state.busy || state.restoring || state.uncertain) return;
    state = state.copy(busy: true, picking: true, clearError: true);
    final revision = ++_revision;
    try {
      await _persist(picking: true);
      if (!mounted || revision != _revision) return;
      final photo = await picker.pick(uid, source);
      if (!mounted || revision != _revision) return;
      if (photo != null) {
        _ticket = null;
        _uploaded = false;
        _uploadAttempted = false;
        state = state.copy(photo: photo, draft: _draft(newRequest: true));
      }
      state = state.copy(busy: false, picking: false);
      await _persist();
    } catch (error) {
      if (mounted && revision == _revision) {
        state = state.copy(
          busy: false,
          picking: false,
          error: momentErrorText(error),
        );
      }
    }
  }

  Future<void> _complete(GroupMoment moment, int revision) async {
    if (!mounted || revision != _revision) return;
    await _saving;
    await store.clear(uid, state.draft.groupId).catchError((Object _) {});
    if (mounted && revision == _revision) {
      state = state.copy(
        busy: false,
        publishing: false,
        uncertain: false,
        posted: moment,
        clearError: true,
      );
    }
  }

  Future<bool> submit() async {
    if (!mounted || state.busy || state.restoring || state.posted != null) {
      return false;
    }
    final photo = state.photo;
    if (uid.isEmpty ||
        !validMomentId(state.draft.groupId) ||
        !validMomentId(state.draft.hobbyId) ||
        photo == null) {
      state = state.copy(
        error: 'Choose a group, a hobby and a photo before posting.',
      );
      return false;
    }
    if (state.draft.caption.trim().runes.length > 160) {
      state = state.copy(error: 'Caption must be at most 160 characters.');
      return false;
    }
    state = state.copy(busy: true, progress: 0, clearError: true);
    final revision = ++_revision;
    _cancellation = MomentUploadCancellation();
    try {
      await _persist();
      _ticket ??= await repository.begin(uid, state.draft);
      if (!mounted || revision != _revision) return false;
      final ticket = _ticket!;
      if (ticket.status == 'published') _uploaded = true;
      if (_uploadAttempted && !_uploaded) {
        // A lost upload acknowledgement may leave the source already written.
        // Ask the backend to publish it before attempting a forbidden overwrite.
        state = state.copy(publishing: true);
        try {
          final moment = await repository.publish(uid, ticket.id);
          await _complete(moment, revision);
          return true;
        } on MomentFailure catch (error) {
          if (error.code != 'failed-precondition') rethrow;
          if (!mounted || revision != _revision) return false;
          state = state.copy(publishing: false);
        }
      }
      if (!_uploaded) {
        _uploadAttempted = true;
        await repository.upload(
          uid,
          ticket,
          photo,
          cancellation: _cancellation!,
          progress: (value) {
            if (mounted && revision == _revision) {
              state = state.copy(progress: value.clamp(0, 1));
            }
          },
        );
        if (!mounted || revision != _revision) return false;
        _uploaded = true;
      }
      state = state.copy(publishing: true, uncertain: true);
      final moment = await repository.publish(uid, ticket.id);
      await _complete(moment, revision);
      return mounted && state.posted != null;
    } catch (error) {
      if (!mounted || revision != _revision) return false;
      final failure = error is MomentFailure ? error : null;
      final uncertain =
          state.publishing &&
          (failure == null ||
              [
                'deadline-exceeded',
                'unavailable',
                'unknown',
                'internal',
                'aborted',
              ].contains(failure.code));
      if (failure?.code == 'unauthorized' ||
          failure?.code == 'upload-expired' ||
          failure?.code == 'invalid-argument') {
        _ticket = null;
        _uploaded = false;
        _uploadAttempted = false;
        state = state.copy(draft: _draft(newRequest: true));
      }
      state = state.copy(
        busy: false,
        publishing: false,
        uncertain: uncertain,
        error: momentErrorText(error),
      );
      return false;
    }
  }

  Future<void> cancelUpload() async {
    if (!state.busy || state.picking || state.publishing) return;
    ++_revision;
    await _cancellation?.cancel();
    if (mounted) {
      state = state.copy(
        busy: false,
        publishing: false,
        error: 'Upload cancelled. Your draft is kept.',
      );
    }
  }

  @override
  void dispose() {
    ++_revision;
    unawaited(_cancellation?.cancel() ?? Future.value());
    super.dispose();
  }
}

class MomentsListState {
  const MomentsListState({
    this.items = const [],
    this.loading = false,
    this.error,
    this.nextCursor,
  });
  final List<GroupMoment> items;
  final bool loading;
  final String? error;
  final MomentCursor? nextCursor;
}

class MomentsList extends StateNotifier<MomentsListState> {
  MomentsList(this.uid, this.groupId, this.repository, this.clock)
    : super(const MomentsListState());
  final String uid, groupId;
  final MomentRepository repository;
  final MomentClock clock;
  int _revision = 0;
  Future<void> refresh() => _load(false);
  Future<void> more() => _load(true);
  Future<void> _load(bool more) async {
    if (more && (state.loading || state.nextCursor == null)) return;
    final previous = more ? state.items : <GroupMoment>[];
    final cursor = more ? state.nextCursor : null;
    final revision = ++_revision;
    state = MomentsListState(items: previous, loading: true);
    try {
      final page = await repository.list(uid, groupId, cursor: cursor);
      if (!mounted || revision != _revision) return;
      clock.sync(page.serverNow, page.roundTrip);
      final unique = {
        for (final moment in [...previous, ...page.items]) moment.id: moment,
      };
      state = MomentsListState(
        items: unique.values
            .where((moment) => moment.expiresAt.isAfter(clock.now))
            .toList(),
        nextCursor: page.nextCursor,
      );
    } catch (error) {
      if (mounted && revision == _revision) {
        state = MomentsListState(error: momentErrorText(error));
      }
    }
  }

  void suspend() {
    ++_revision;
    state = const MomentsListState();
  }

  @override
  void dispose() {
    ++_revision;
    super.dispose();
  }
}

class MomentViewerState {
  const MomentViewerState({
    this.moment,
    this.image,
    this.loading = false,
    this.expired = false,
    this.retracting = false,
    this.error,
  });
  final GroupMoment? moment;
  final MomentImage? image;
  final bool loading, expired, retracting;
  final String? error;
}

class MomentViewer extends StateNotifier<MomentViewerState> {
  MomentViewer(this.uid, this.groupId, this.id, this.repository, this.clock)
    : super(const MomentViewerState());
  final String uid, groupId, id;
  final MomentRepository repository;
  final MomentClock clock;
  Timer? _expiry;
  int _revision = 0;
  Future<void> load() async {
    _expiry?.cancel();
    final revision = ++_revision;
    state = const MomentViewerState(loading: true);
    try {
      final detail = await repository.get(uid, groupId, id);
      if (!mounted || revision != _revision) return;
      clock.sync(detail.serverNow, detail.roundTrip);
      if (!detail.moment.expiresAt.isAfter(clock.now)) {
        state = const MomentViewerState(expired: true);
        return;
      }
      final image = await repository.image(uid, groupId, id, thumbnail: false);
      if (!mounted || revision != _revision) return;
      clock.sync(image.serverNow, image.roundTrip);
      final expires = detail.moment.expiresAt.isBefore(image.expiresAt)
          ? detail.moment.expiresAt
          : image.expiresAt;
      if (!expires.isAfter(clock.now)) {
        state = const MomentViewerState(expired: true);
        return;
      }
      state = MomentViewerState(moment: detail.moment, image: image);
      _expiry = Timer(expires.difference(clock.now), () {
        if (mounted) state = const MomentViewerState(expired: true);
      });
    } catch (error) {
      if (mounted && revision == _revision) {
        state = MomentViewerState(
          expired: error is MomentFailure && error.code == 'not-found',
          error: momentErrorText(error),
        );
      }
    }
  }

  Future<bool> retract() async {
    if (state.retracting || state.moment?.authorId != uid) return false;
    final moment = state.moment;
    state = MomentViewerState(moment: moment, retracting: true);
    final revision = ++_revision;
    _expiry?.cancel();
    try {
      await repository.retract(uid, groupId, id);
      if (!mounted || revision != _revision) return false;
      state = const MomentViewerState(expired: true);
      return true;
    } catch (error) {
      if (mounted && revision == _revision) {
        state = MomentViewerState(error: momentErrorText(error));
      }
      return false;
    }
  }

  void suspend() {
    ++_revision;
    _expiry?.cancel();
    state = const MomentViewerState();
  }

  @override
  void dispose() {
    ++_revision;
    _expiry?.cancel();
    super.dispose();
  }
}
