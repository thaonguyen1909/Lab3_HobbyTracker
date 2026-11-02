import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';

import '../models/auth_user.dart';
import '../services/auth_service.dart';

/// Firebase is strictly confined to service layer, never imported in widgets.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
    required GoogleSignIn google,
    this.onBeforeSignOut,
  }) : _auth = auth,
       _db = db,
       _google = google;
  final Future<void> Function(String?)? onBeforeSignOut;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  AuthUser _mapUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    emailVerified: user.emailVerified,
    providers: user.providerData
        .map((p) => p.providerId)
        .toList(growable: false),
  );

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.userChanges().map((user) => user == null ? null : _mapUser(user));

  @override
  Future<void> ensureOwnProfile(AuthUser user) => _ensureProfile(user);

  Future<void> _ensureProfile(AuthUser user, {String? registrationName}) async {
    // Never overwrite an existing role (especially a future staff/admin role).
    final doc = _db.collection('users').doc(user.uid);
    final rawName =
        (registrationName ?? user.displayName ?? 'Hobby Tracker user').trim();
    final name = String.fromCharCodes(rawName.runes.take(80));
    // Atomic create-if-absent. Another device cannot overwrite existing role.
    await _db.runTransaction<void>((transaction) async {
      final existing = await transaction.get(doc);
      if (!existing.exists) {
        transaction.set(doc, {
          'role': 'user',
          'displayName': name.isEmpty ? 'Hobby Tracker user' : name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (registrationName != null) {
        // An initial auth event may already have created a fallback profile.
        // Explicit registration edits the name only; role is never overwritten.
        transaction.update(doc, {'displayName': name});
      }
    });
  }

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final account = await _google.signIn();
    if (account == null) throw const AuthCancelled();
    final tokens = await account.authentication;
    if (tokens.idToken == null) {
      throw const AuthFailure(
        'Không nhận được ID token từ Google. Kiểm tra SHA/OAuth Android.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
    );
    await _auth.signInWithCredential(credential);
  });

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _guard(() async {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    required String displayName,
  }) => _guard(() async {
    final name = displayName.trim();
    if (name.runes.length < 2 || name.runes.length > 80) {
      throw const AuthFailure('Tên phải có từ 2 đến 80 ký tự.');
    }
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user;
    if (user == null) {
      throw const AuthFailure('Không nhận được tài khoản vừa tạo.');
    }
    await user.updateDisplayName(name);
    await _ensureProfile(_mapUser(user), registrationName: name);
  });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  });

  @override
  Future<void> linkGoogleToCurrentAccount() => _guard(() async {
    final current = _auth.currentUser;
    if (current == null) {
      throw const AuthFailure('Bạn cần đăng nhập trước khi liên kết Google.');
    }
    if (current.providerData.any((p) => p.providerId == 'google.com')) {
      throw const AuthFailure('Google đã được liên kết với tài khoản này.');
    }
    final googleAccount = await _google.signIn();
    if (googleAccount == null) throw const AuthCancelled();
    // Link only after current user explicitly authorizes it. Do not merge by email.
    final currentEmail = current.email?.trim().toLowerCase();
    if (currentEmail == null ||
        currentEmail != googleAccount.email.trim().toLowerCase()) {
      await _google.signOut();
      throw const AuthFailure(
        'Email Google khác email tài khoản đang đăng nhập; đã hủy liên kết.',
      );
    }
    final tokens = await googleAccount.authentication;
    if (tokens.idToken == null) {
      throw const AuthFailure('Không nhận được ID token Google.');
    }
    if (_auth.currentUser?.uid != current.uid) {
      throw const AuthFailure(
        'Phiên đăng nhập đã thay đổi. Hãy thử liên kết lại.',
      );
    }
    await current.linkWithCredential(
      GoogleAuthProvider.credential(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      ),
    );
    await current.reload();
  });

  @override
  Future<void> signOut() => _guard(() async {
    // The cloud session is the authority. A Google picker cleanup failure
    // must not leave a Firebase session active.
    try {
      await onBeforeSignOut?.call(_auth.currentUser?.uid);
    } catch (_) {}
    await _auth.signOut();
    try {
      await _google.signOut();
    } catch (_) {
      /* Firebase user is already signed out. */
    }
  });

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' ||
          e.code == 'sign_in_cancelled' ||
          e.code == 'canceled') {
        throw const AuthCancelled();
      }
      throw AuthFailure(
        e.code == 'network_error'
            ? 'Không có mạng. Kiểm tra kết nối rồi thử lại.'
            : 'Không thể mở đăng nhập Google (${e.code}). Kiểm tra cấu hình OAuth/SHA.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        _firebaseAuthError(e.code),
        isConflict: e.code == 'account-exists-with-different-credential',
      );
    } on FirebaseException catch (e) {
      throw AuthFailure(switch (e.code) {
        'permission-denied' =>
          'Không có quyền truy cập hồ sơ. Kiểm tra Firestore Rules.',
        'unavailable' =>
          'Không kết nối được Firebase. Kiểm tra mạng rồi thử lại.',
        _ => 'Lỗi Firebase (${e.code}). Vui lòng thử lại.',
      });
    }
  }
}

String _firebaseAuthError(String code) => switch (code) {
  'invalid-email' => 'Email không hợp lệ.',
  'wrong-password' || 'invalid-credential' || 'user-not-found' =>
    'Email hoặc mật khẩu không đúng. Hãy thử lại hoặc đặt lại mật khẩu.',
  'email-already-in-use' =>
    'Email đã được đăng ký. Hãy đăng nhập hoặc đặt lại mật khẩu.',
  'weak-password' => 'Mật khẩu quá yếu. Dùng ít nhất 6 ký tự.',
  'account-exists-with-different-credential' =>
    'Email này đang dùng phương thức đăng nhập khác. Hãy đăng nhập bằng phương thức cũ rồi xác nhận liên kết Google trong Settings.',
  'credential-already-in-use' =>
    'Google này đã liên kết với tài khoản khác. Không thể tự gộp.',
  'provider-already-linked' => 'Google đã liên kết với tài khoản này.',
  'requires-recent-login' => 'Hãy đăng nhập lại để hoàn tất liên kết Google.',
  'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
  'too-many-requests' => 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
  'network-request-failed' => 'Không có mạng. Kiểm tra kết nối rồi thử lại.',
  'operation-not-allowed' =>
    'Chưa bật phương thức đăng nhập trong Firebase Console.',
  _ => 'Không thể xác thực ($code). Vui lòng thử lại.',
};
