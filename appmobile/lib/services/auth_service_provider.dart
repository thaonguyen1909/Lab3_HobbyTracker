import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_auth_service.dart';
import 'auth_service.dart';
import 'app_services.dart';
import '../firebase/firebase_runtime.dart';

/// Composition root: inject SDK-backed implementation behind a domain service.
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firebaseFirestoreProvider),
    google: GoogleSignIn(),
    onBeforeSignOut: (uid) => ref.read(deviceServicesProvider).endSession(uid),
    localOnly: ref.watch(firebaseRuntimeConfigProvider).emulators,
  ),
);
