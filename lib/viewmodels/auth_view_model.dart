import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/auth_service_provider.dart';

/// Observe identity independently so slow profile I/O never delays sign-out.
final authIdentityProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Only a different UID starts a new profile gate. Token/name/provider updates
/// for the same account must not destroy the current route or unsaved forms.
final authSessionProvider = FutureProvider<AuthUser?>((ref) async {
  final service = ref.watch(authServiceProvider);
  final uid = await ref.watch(
    authIdentityProvider.selectAsync((user) => user?.uid),
  );
  if (uid == null) return null;
  final user = ref.read(authIdentityProvider).requireValue!;
  await service.ensureOwnProfile(user).timeout(const Duration(seconds: 20));
  return user;
});

/// Current account metadata, separate from the UID-based authorization gate.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  final identity = ref.watch(authIdentityProvider).valueOrNull;
  return session != null && session.uid == identity?.uid ? identity : null;
});

class AuthActionState {
  const AuthActionState({
    this.busy = false,
    this.message,
    this.isError = false,
    this.isConflict = false,
  });
  final bool busy;
  final String? message;
  final bool isError;
  final bool isConflict;
}

/// Actions remain independently testable with fake AuthService.
class AuthViewModel extends StateNotifier<AuthActionState> {
  AuthViewModel(this._service) : super(const AuthActionState());
  final AuthService _service;

  void clear() {
    if (!state.busy) state = const AuthActionState();
  }

  Future<bool> _run(Future<void> Function() action, {String? success}) async {
    if (!mounted || state.busy) return false;
    state = const AuthActionState(busy: true);
    try {
      await action();
      if (!mounted) return false;
      state = AuthActionState(message: success);
      return true;
    } on AuthCancelled {
      if (!mounted) return false;
      state = const AuthActionState(
        message: 'Đã hủy đăng nhập Google. Bạn có thể thử lại.',
      );
    } catch (error) {
      if (!mounted) return false;
      state = AuthActionState(
        message: _errorMessage(error),
        isError: true,
        isConflict: error is AuthFailure && error.isConflict,
      );
    }
    return false;
  }

  Future<bool> googleSignIn() => _run(_service.signInWithGoogle);
  Future<bool> emailSignIn(String email, String password) =>
      _run(() => _service.signInWithEmail(email, password));
  Future<bool> register(
    String email,
    String password, {
    required String displayName,
  }) => _run(
    () => _service.registerWithEmail(email, password, displayName: displayName),
  );
  Future<bool> reset(String email) => _run(
    () => _service.sendPasswordReset(email),
    success: 'Nếu email hợp lệ, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.',
  );
  Future<bool> linkGoogle() => _run(
    _service.linkGoogleToCurrentAccount,
    success: 'Đã liên kết tài khoản Google.',
  );
  Future<bool> signOut() => _run(_service.signOut);
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthActionState>(
      (ref) => AuthViewModel(ref.watch(authServiceProvider)),
    );

String _errorMessage(Object error) {
  if (error is AuthFailure) return error.message;
  return 'Đã xảy ra lỗi kết nối hoặc xác thực. Hãy thử lại.';
}
