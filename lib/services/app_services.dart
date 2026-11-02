import '../l10n/language_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase/firestore_hobby_repository.dart';
import '../firebase/firebase_device_services.dart';
import '../firebase/firebase_report_uploader.dart';
import 'hobby_repository.dart';
import 'device_services.dart';
import 'local_owner_store.dart';
import 'pdf_report_exporter.dart';

final repositoryProvider = Provider<HobbyRepository>(
  (ref) => FirestoreHobbyRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  ),
);
final deviceServicesProvider = Provider<DeviceServices>(
  (ref) => FirebaseDeviceServices(
    auth: FirebaseAuth.instance,
    db: FirebaseFirestore.instance,
    analytics: FirebaseAnalytics.instance,
    crashes: FirebaseCrashlytics.instance,
    config: FirebaseRemoteConfig.instance,
    messaging: FirebaseMessaging.instance,
    local: LocalOwnerStore(),
  ),
);
final reportExporterProvider = Provider<ReportExporter>(
  (ref) => PdfReportExporter(languageCode: ref.watch(languageProvider).code),
);
final reportUploaderProvider = Provider<ReportUploader>(
  (ref) =>
      FirebaseReportUploader(FirebaseStorage.instance, FirebaseAuth.instance),
);
