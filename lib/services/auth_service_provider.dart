import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_auth_service.dart';
import 'auth_service.dart';
import 'app_services.dart';

/// Composition root: inject SDK-backed implementation behind a domain service.
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(
    auth: FirebaseAuth.instance,
    db: FirebaseFirestore.instance,
    google: GoogleSignIn(),
    onBeforeSignOut: (uid) => ref.read(deviceServicesProvider).endSession(uid),
  ),
);
