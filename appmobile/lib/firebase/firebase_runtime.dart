import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig({
    this.emulators = false,
    this.host = '127.0.0.1',
  });
  static const fromEnvironment = FirebaseRuntimeConfig(
    emulators: bool.fromEnvironment('USE_FIREBASE_EMULATORS'),
    host: String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '127.0.0.1',
    ),
  );
  static const demoProject = 'demo-hobbytracker-moments';
  final bool emulators;
  final String host;
  void validate({required bool debug}) {
    if (!emulators) return;
    if (!debug) throw StateError('Firebase emulators require a debug build.');
    final parts = host.split('.').map(int.tryParse).toList();
    final privateIp =
        parts.length == 4 &&
        parts.every((part) => part != null && part >= 0 && part <= 255) &&
        (parts[0] == 127 ||
            parts[0] == 10 ||
            (parts[0] == 192 && parts[1] == 168) ||
            (parts[0] == 172 && parts[1]! >= 16 && parts[1]! <= 31));
    if (host != 'localhost' && !privateIp) {
      throw StateError(
        'Use a local/private emulator host without scheme or port.',
      );
    }
  }
}

final firebaseRuntimeConfigProvider = Provider<FirebaseRuntimeConfig>(
  (ref) => const FirebaseRuntimeConfig(),
);
final firebaseAppProvider = Provider<FirebaseApp>((ref) => Firebase.app());
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instanceFor(app: ref.watch(firebaseAppProvider)),
);
final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instanceFor(app: ref.watch(firebaseAppProvider)),
);
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instanceFor(app: ref.watch(firebaseAppProvider)),
);
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  final functions = FirebaseFunctions.instanceFor(
    app: ref.watch(firebaseAppProvider),
    region: 'asia-southeast1',
  );
  final config = ref.watch(firebaseRuntimeConfigProvider);
  if (config.emulators) {
    functions.useFunctionsEmulator(
      config.host,
      5001,
      automaticHostMapping: false,
    );
  }
  return functions;
});

Future<FirebaseApp> initializeHobbyFirebase(
  FirebaseRuntimeConfig config,
) async {
  config.validate(debug: kDebugMode);
  final app = config.emulators
      ? await Firebase.initializeApp(
          name: 'hobbytracker-local',
          options: const FirebaseOptions(
            // Explicit demo credentials, valid only with the isolated emulator APIs.
            apiKey: 'demo-api-key',
            appId: '1:1:android:1',
            messagingSenderId: '1',
            projectId: FirebaseRuntimeConfig.demoProject,
            storageBucket: '${FirebaseRuntimeConfig.demoProject}.appspot.com',
          ),
        )
      : await Firebase.initializeApp();
  final db = FirebaseFirestore.instanceFor(app: app);
  db.settings = const Settings(persistenceEnabled: false);
  if (config.emulators) {
    await FirebaseAuth.instanceFor(
      app: app,
    ).useAuthEmulator(config.host, 9099, automaticHostMapping: false);
    db.useFirestoreEmulator(config.host, 8080, automaticHostMapping: false);
    await FirebaseStorage.instanceFor(
      app: app,
    ).useStorageEmulator(config.host, 9199, automaticHostMapping: false);
  }
  return app;
}
