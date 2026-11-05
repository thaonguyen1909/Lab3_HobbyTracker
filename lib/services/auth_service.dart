import '../models/auth_user.dart';

/// Domain boundary. UI and ViewModels never depend on Firebase SDK objects.
abstract class AuthService {
  Stream<AuthUser?> authStateChanges();
  Future<void> ensureOwnProfile(AuthUser user);
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> registerWithEmail(
    String email,
    String password, {
    required String displayName,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> linkGoogleToCurrentAccount();
  Future<void> signOut();
}

class AuthCancelled implements Exception {
  const AuthCancelled();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.isConflict = false});
  final String message;
  final bool isConflict;
}
