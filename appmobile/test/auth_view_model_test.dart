import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:hobby_tracker/services/auth_service.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';
import 'package:hobby_tracker/viewmodels/auth_view_model.dart';

class ControlledAuthService implements AuthService {
  final changes = StreamController<AuthUser?>.broadcast();
  final profiles = <String, Completer<void>>{};
  Completer<void>? action;
  Object? actionError;
  int calls = 0;
  @override
  Stream<AuthUser?> authStateChanges() => changes.stream;
  @override
  Future<void> ensureOwnProfile(AuthUser user) =>
      profiles.putIfAbsent(user.uid, Completer<void>.new).future;
  Future<void> perform() async {
    calls++;
    if (actionError != null) throw actionError!;
    if (action != null) await action!.future;
  }

  @override
  Future<void> signInWithGoogle() => perform();
  @override
  Future<void> signInWithEmail(String email, String password) => perform();
  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    required String displayName,
  }) => perform();
  @override
  Future<void> sendPasswordReset(String email) => perform();
  @override
  Future<void> linkGoogleToCurrentAccount() => perform();
  @override
  Future<void> signOut() async {
    await perform();
    changes.add(null);
  }
}

Future<void> flush() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late ControlledAuthService service;
  late ProviderContainer container;
  setUp(() {
    service = ControlledAuthService();
    container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(service)],
    );
  });
  tearDown(() async {
    container.dispose();
    await service.changes.close();
  });

  test('double submit calls service once while action is pending', () async {
    final vm = container.read(authViewModelProvider.notifier);
    service.action = Completer<void>();
    final pending = vm.googleSignIn();
    expect(vm.state.busy, isTrue);
    expect(await vm.googleSignIn(), isFalse);
    expect(service.calls, 1);
    service.action!.complete();
    expect(await pending, isTrue);
    expect(vm.state.busy, isFalse);
  });

  test('cancel is nonfatal; network/conflict errors can be retried', () async {
    final vm = container.read(authViewModelProvider.notifier);
    service.actionError = const AuthCancelled();
    expect(await vm.googleSignIn(), isFalse);
    expect(vm.state.isError, isFalse);
    expect(vm.state.message, contains('Đã hủy'));
    service.actionError = const AuthFailure('Conflict', isConflict: true);
    expect(await vm.googleSignIn(), isFalse);
    expect(vm.state.isError, isTrue);
    expect(vm.state.isConflict, isTrue);
    service.actionError = null;
    expect(await vm.googleSignIn(), isTrue);
    expect(vm.state.isConflict, isFalse);
  });

  test(
    'completed action after provider disposal does not write state',
    () async {
      final vm = container.read(authViewModelProvider.notifier);
      service.action = Completer<void>();
      final pending = vm.googleSignIn();
      container.invalidate(authViewModelProvider);
      await flush();
      service.action!.complete();
      expect(await pending, isFalse);
    },
  );

  test(
    'sign-out is not blocked by pending profile; stale result ignored',
    () async {
      final states = <AsyncValue<AuthUser?>>[];
      container.listen(
        authSessionProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      await flush();
      service.changes.add(const AuthUser(uid: 'alice'));
      await flush();
      expect(container.read(authSessionProvider).isLoading, isTrue);
      service.changes.add(null);
      await flush();
      expect(await container.read(authSessionProvider.future), isNull);
      service.profiles['alice']!.complete();
      await flush();
      expect(container.read(authSessionProvider).valueOrNull, isNull);
      expect(states.where((s) => s.valueOrNull?.uid == 'alice'), isEmpty);
    },
  );

  test('switching accounts discards old profile error', () async {
    container.listen(authSessionProvider, (_, next) {});
    await flush();
    service.changes.add(const AuthUser(uid: 'alice'));
    await flush();
    service.changes.add(const AuthUser(uid: 'bob'));
    await flush();
    service.profiles['bob']!.complete();
    await flush();
    expect((await container.read(authSessionProvider.future))?.uid, 'bob');
    service.profiles['alice']!.completeError(
      const AuthFailure('Old profile failed'),
    );
    await flush();
    expect(container.read(authSessionProvider).hasError, isFalse);
    expect(container.read(authSessionProvider).valueOrNull?.uid, 'bob');
  });

  test(
    'profile failure blocks session; invalidation retries same identity',
    () async {
      container.listen(authSessionProvider, (_, next) {});
      await flush();
      service.changes.add(const AuthUser(uid: 'alice'));
      await flush();
      service.profiles['alice']!.completeError(const AuthFailure('Offline'));
      await flush();
      expect(container.read(authSessionProvider).hasError, isTrue);
      service.profiles['alice'] = Completer<void>()..complete();
      container.invalidate(authSessionProvider);
      await flush();
      expect((await container.read(authSessionProvider.future))?.uid, 'alice');
    },
  );
}
