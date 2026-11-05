import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_moment_repository.dart';
import 'moment_http_transport.dart';

FirebaseMomentRepository createMomentRepository(
  FirebaseApp app, {
  bool emulators = false,
}) {
  final auth = FirebaseAuth.instanceFor(app: app);
  return FirebaseMomentRepository(
    FirebaseFunctions.instanceFor(app: app, region: 'asia-southeast1'),
    FirebaseStorage.instanceFor(app: app),
    auth,
    http: emulators
        ? null
        : MomentHttpTransport(
            baseUrl: MomentHttpTransport.configuredUrl,
            token: () => auth.currentUser?.getIdToken() ?? Future.value(null),
            isOwner: () => auth.currentUser != null,
          ),
  );
}
