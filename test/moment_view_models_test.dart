import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hobby_tracker/models/group_moment.dart';
import 'package:hobby_tracker/viewmodels/moment_view_models.dart';
import 'package:hobby_tracker/services/local_moment_draft_store.dart';
import 'package:hobby_tracker/services/local_owner_store.dart';
import 'package:hobby_tracker/firebase/firebase_runtime.dart';
import 'package:hobby_tracker/firebase/firebase_moment_repository.dart';
import 'support/moment_fakes.dart';

class MemoryMomentPreferences extends Mock implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  final bytes = File('test/fixtures/moment.jpg').readAsBytesSync();
  late TestMomentClock clock;
  late TestMomentRepository repo;
  late TestMomentPicker picker;
  late TestMomentDraftStore store;
  late MomentComposer composer;
  setUp(() {
    clock = TestMomentClock(DateTime.utc(2026, 11, 4, 12));
    repo = TestMomentRepository(clock, bytes);
    picker = TestMomentPicker(MomentPhoto.checked(bytes));
    store = TestMomentDraftStore();
    var sequence = 0;
    composer = MomentComposer(
      'owner-001',
      'g1',
      repo,
      picker,
      store,
      newId: () => 'request${++sequence}',
    );
  });
  tearDown(() {
    if (composer.mounted) composer.dispose();
  });
  Future<void> ready() async {
    await composer.restore();
    composer.edit(hobbyId: 'h1', caption: 'My notes');
    await composer.choosePhoto(MomentPhotoSource.gallery);
  }

  test(
    'expired server session is distinct from an ambiguous transport timeout',
    () {
      expect(
        momentBackendFailure('deadline-exceeded').code,
        'deadline-exceeded',
      );
      expect(
        momentBackendFailure(
          'deadline-exceeded',
          serverMessage: 'Upload session expired.',
        ).code,
        'upload-expired',
      );
      expect(
        momentBackendFailure(
          'deadline-exceeded',
          serverMessage: 'Upload session expired. Start a new upload.',
        ).code,
        'upload-expired',
      );
    },
  );

  test(
    'definitively expired session keeps photo and starts a fresh request on retry',
    () async {
      await ready();
      final requestId = composer.state.draft.requestId;
      repo.publishFailure = momentBackendFailure(
        'deadline-exceeded',
        serverMessage: 'Upload session expired.',
      );
      expect(await composer.submit(), false);
      expect(composer.state.uncertain, false);
      expect(composer.state.draft.requestId, isNot(requestId));
      expect(composer.state.photo, isNotNull);
      expect(composer.state.draft.caption, 'My notes');
      repo.publishFailure = null;
      expect(await composer.submit(), true);
      expect(repo.moments.length, 1);
    },
  );

  test(
    'validates required photo/hobby and Unicode caption before network access',
    () async {
      await composer.restore();
      expect(await composer.submit(), false);
      expect(repo.calls, isEmpty);
      await ready();
      composer.edit(caption: '🏸' * 161);
      expect(await composer.submit(), false);
      expect(repo.calls, isEmpty);
    },
  );

  test(
    'picker cancellation and permission failure keep selected photo, text and request',
    () async {
      await ready();
      final photo = composer.state.photo,
          requestId = composer.state.draft.requestId;
      picker.photo = null;
      await composer.choosePhoto(MomentPhotoSource.camera);
      expect(composer.state.photo, same(photo));
      expect(composer.state.draft.requestId, requestId);
      picker.error = const MomentFailure('permission-denied', 'Camera denied');
      await composer.choosePhoto(MomentPhotoSource.camera);
      expect(composer.state.error, 'Camera denied');
      expect(composer.state.draft.caption, 'My notes');
      expect(composer.state.photo, same(photo));
    },
  );

  test(
    'upload acknowledgement lost: retry publishes existing source without overwrite',
    () async {
      await ready();
      repo.failUploadAfterWrite = true;
      expect(await composer.submit(), false);
      expect(composer.state.draft.caption, 'My notes');
      expect(composer.state.photo, isNotNull);
      expect(await composer.submit(), true);
      expect(repo.uploads, 1);
      expect(repo.moments.length, 1);
    },
  );

  test(
    'lost publish acknowledgement locks edits and retries same ID without extending expiry',
    () async {
      await ready();
      repo.failPublishAfterCommit = true;
      expect(await composer.submit(), false);
      expect(composer.state.uncertain, true);
      final requestId = composer.state.draft.requestId,
          expiresAt = repo.moments.values.single.expiresAt;
      composer.edit(caption: 'Must not create a new request');
      expect(composer.state.draft.requestId, requestId);
      clock.value = clock.now.add(const Duration(minutes: 1));
      expect(await composer.submit(), true);
      expect(repo.moments.values.single.expiresAt, expiresAt);
      expect(repo.uploads, 1);
      expect(repo.moments.length, 1);
      expect(store.values, isEmpty);
    },
  );

  test(
    'double submit only starts one upload; cancelling retains draft for a retry',
    () async {
      await ready();
      repo.uploadGate = Completer<void>();
      final pending = composer.submit();
      await Future<void>.delayed(Duration.zero);
      expect(await composer.submit(), false);
      expect(repo.uploads, 1);
      await composer.cancelUpload();
      expect(await pending, false);
      expect(composer.state.photo, isNotNull);
      repo.uploadGate = null;
      expect(await composer.submit(), true);
      expect(repo.moments.length, 1);
    },
  );

  test(
    'disposed composer ignores late publish completion and cancels upload',
    () async {
      await ready();
      repo.uploadGate = Completer<void>();
      final pending = composer.submit();
      await Future<void>.delayed(Duration.zero);
      composer.dispose();
      expect(await pending, false);
      expect(repo.moments, isEmpty);
    },
  );

  test(
    'draft restore remains scoped to owner and group; image-picker recovery is explicit',
    () async {
      store.values[store.key('other-owner', 'g1')] = const MomentDraft(
        groupId: 'g1',
        hobbyId: 'h2',
        caption: 'Other account',
        requestId: 'r',
      );
      await composer.restore();
      expect(composer.state.draft.caption, isEmpty);
      expect(composer.state.photo, isNull);
    },
  );

  test(
    'local persisted drafts cannot cross UID or return after owner switches',
    () async {
      final prefs = MemoryMomentPreferences()..values['active_owner'] = 'alice';
      final local = LocalMomentDraftStore(LocalOwnerStore(preferences: prefs));
      const draft = MomentDraft(
        groupId: 'g1',
        hobbyId: 'h1',
        caption: 'Alice only',
        requestId: 'r',
      );
      await local.save('alice', draft);
      expect((await local.read('alice', 'g1'))?.caption, 'Alice only');
      prefs.values['active_owner'] = 'bob';
      expect(await local.read('bob', 'g1'), isNull);
      expect(await local.read('alice', 'g1'), isNull);
      await local.save('alice', draft);
      expect(await local.read('bob', 'g1'), isNull);
    },
  );

  test('server clock never moves back when an older response arrives', () {
    final clock = MonotonicMomentClock();
    clock.sync(DateTime.utc(2026, 1, 1), const Duration(seconds: 2));
    final before = clock.now;
    clock.sync(DateTime.utc(2025, 1, 1), Duration.zero);
    expect(clock.now.isBefore(before), false);
    expect(clock.now.year, 2026);
  });

  test(
    'list removes expired records and merges pages without duplicate IDs',
    () async {
      final one = repo.sample(),
          expired = repo.sample(id: 'old', life: const Duration(seconds: -1));
      repo.pages = [
        MomentPage(
          [one, expired],
          clock.now,
          nextCursor: const MomentCursor(123, 'm1'),
        ),
        MomentPage([one, repo.sample(id: 'm2')], clock.now),
      ];
      final vm = MomentsList('owner-001', 'g1', repo, clock);
      addTearDown(vm.dispose);
      await vm.refresh();
      expect(vm.state.items.map((item) => item.id), ['m1']);
      await vm.more();
      expect(vm.state.items.map((item) => item.id), ['m1', 'm2']);
      vm.suspend();
      expect(vm.state.items, isEmpty);
    },
  );

  testWidgets('viewer clears bytes exactly on expiry', (tester) async {
    repo.moments['m1'] = repo.sample(life: const Duration(seconds: 2));
    final vm = MomentViewer('owner-001', 'g1', 'm1', repo, clock);
    addTearDown(vm.dispose);
    await vm.load();
    expect(vm.state.image, isNotNull);
    clock.value = clock.now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(vm.state.expired, true);
    expect(vm.state.image, isNull);
  });

  test(
    'expiry or suspension during image IO never exposes a stale response',
    () async {
      final moment = repo.sample();
      repo.moments['m1'] = moment;
      repo.imageGate = Completer<MomentImage>();
      final vm = MomentViewer('owner-001', 'g1', 'm1', repo, clock);
      addTearDown(vm.dispose);
      final pending = vm.load();
      await Future<void>.delayed(Duration.zero);
      vm.suspend();
      repo.imageGate!.complete(MomentImage(bytes, moment.expiresAt, clock.now));
      await pending;
      expect(vm.state.image, isNull);
    },
  );

  test(
    'removed membership clears previously loaded image when rechecking',
    () async {
      repo.moments['m1'] = repo.sample();
      final vm = MomentViewer('owner-001', 'g1', 'm1', repo, clock);
      addTearDown(vm.dispose);
      await vm.load();
      expect(vm.state.image, isNotNull);
      repo.readFailure = const MomentFailure(
        'permission-denied',
        'You no longer have access to this group.',
      );
      await vm.load();
      expect(vm.state.image, isNull);
      expect(vm.state.error, contains('no longer'));
    },
  );

  test(
    'emulator mode rejects release and external hosts, accepts ADB loopback',
    () {
      expect(
        () =>
            const FirebaseRuntimeConfig(emulators: true).validate(debug: false),
        throwsStateError,
      );
      expect(
        () => const FirebaseRuntimeConfig(
          emulators: true,
          host: 'firebase.google.com',
        ).validate(debug: true),
        throwsStateError,
      );
      expect(
        () => const FirebaseRuntimeConfig(
          emulators: true,
          host: 'http://127.0.0.1:9099',
        ).validate(debug: true),
        throwsStateError,
      );
      const FirebaseRuntimeConfig(emulators: true).validate(debug: true);
      const FirebaseRuntimeConfig(
        emulators: true,
        host: '10.0.2.2',
      ).validate(debug: true);
      const FirebaseRuntimeConfig().validate(debug: false);
    },
  );
}
