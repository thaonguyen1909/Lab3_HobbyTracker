import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase/firebase_runtime.dart';
import '../firebase/moment_repository_factory.dart';
import '../models/group_moment.dart';
import '../viewmodels/data_providers.dart';
import '../viewmodels/moment_view_models.dart';
import 'moment_repository.dart';
import 'moment_photo_picker.dart';
import 'local_moment_draft_store.dart';
import 'local_owner_store.dart';

final momentRepositoryProvider = Provider<MomentRepository>(
  (ref) => createMomentRepository(
    ref.watch(firebaseAppProvider),
    emulators: ref.watch(firebaseRuntimeConfigProvider).emulators,
  ),
);
final momentPhotoPickerProvider = Provider<MomentPhotoPicker>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return PlatformMomentPhotoPicker(
    isOwner: (uid) => auth.currentUser?.uid == uid,
  );
});
final momentDraftStoreProvider = Provider<MomentDraftStore>(
  (ref) => LocalMomentDraftStore(LocalOwnerStore()),
);
final momentClockProvider = Provider.autoDispose<MomentClock>((ref) {
  ref.watch(ownerIdProvider);
  return MonotonicMomentClock();
});
final momentComposerProvider = StateNotifierProvider.autoDispose
    .family<MomentComposer, MomentComposerState, String>((ref, groupId) {
      final vm = MomentComposer(
        ref.watch(ownerIdProvider) ?? '',
        groupId,
        ref.watch(momentRepositoryProvider),
        ref.watch(momentPhotoPickerProvider),
        ref.watch(momentDraftStoreProvider),
      );
      unawaited(Future.microtask(vm.restore));
      return vm;
    });
final momentsListProvider = StateNotifierProvider.autoDispose
    .family<MomentsList, MomentsListState, String>((ref, groupId) {
      final vm = MomentsList(
        ref.watch(ownerIdProvider) ?? '',
        groupId,
        ref.watch(momentRepositoryProvider),
        ref.watch(momentClockProvider),
      );
      unawaited(Future.microtask(vm.refresh));
      return vm;
    });
typedef MomentKey = ({String groupId, String id});
final momentViewerProvider = StateNotifierProvider.autoDispose
    .family<MomentViewer, MomentViewerState, MomentKey>((ref, key) {
      final vm = MomentViewer(
        ref.watch(ownerIdProvider) ?? '',
        key.groupId,
        key.id,
        ref.watch(momentRepositoryProvider),
        ref.watch(momentClockProvider),
      );
      unawaited(Future.microtask(vm.load));
      return vm;
    });
final momentThumbnailProvider = FutureProvider.autoDispose
    .family<MomentImage, MomentKey>((ref, key) async {
      final uid = ref.watch(ownerIdProvider) ?? '';
      final clock = ref.watch(momentClockProvider);
      var active = true;
      ref.onDispose(() => active = false);
      final image = await ref
          .watch(momentRepositoryProvider)
          .image(uid, key.groupId, key.id, thumbnail: true);
      if (!active) {
        throw const MomentFailure('cancelled', 'The moment is no longer open.');
      }
      clock.sync(image.serverNow, image.roundTrip);
      if (!image.expiresAt.isAfter(clock.now)) {
        throw const MomentFailure(
          'not-found',
          'This moment has expired or is no longer available.',
        );
      }
      return image;
    });
