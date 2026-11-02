import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/language_controller.dart';
import 'l10n/app_strings.dart';
import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'firebase/firebase_device_services.dart';
import 'firebase/notification_background.dart';
import 'services/local_owner_store.dart';
import 'services/app_services.dart';
import 'theme/hobby_theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Android-only Phase 02: flutterfire configure installs Android's
    // google-services.json / Gradle configuration for native default app.
    // Do not put invented project IDs or credentials into this repository.
    await Firebase.initializeApp();
    // No on-disk owner data remains across sign-out/account switching.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessage);
    final device = FirebaseDeviceServices(
      auth: FirebaseAuth.instance,
      db: FirebaseFirestore.instance,
      analytics: FirebaseAnalytics.instance,
      crashes: FirebaseCrashlytics.instance,
      config: FirebaseRemoteConfig.instance,
      messaging: FirebaseMessaging.instance,
      local: LocalOwnerStore(),
    );
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        device.recordError(
          details.exception,
          details.stack ?? StackTrace.current,
          reason: 'flutter_error',
          fatal: true,
        ),
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        device.recordError(error, stack, reason: 'platform_error', fatal: true),
      );
      return true;
    };
    runApp(
      ProviderScope(
        overrides: [deviceServicesProvider.overrideWithValue(device)],
        child: const HobbyTrackerApp(),
      ),
    );
  } catch (_) {
    runApp(const ProviderScope(child: _FirebaseSetupRequiredApp()));
  }
}

class _FirebaseSetupRequiredApp extends ConsumerWidget {
  const _FirebaseSetupRequiredApp();
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    locale: Locale(ref.watch(languageProvider).code),
    supportedLocales: AppStrings.supportedLocales,
    localizationsDelegates: const [
      AppStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
    theme: HobbyTheme.forVariant(AppThemeVariant.light),
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 48),
                SizedBox(height: AppSpacing.md),
                AppText(
                  'Chưa kết nối được Firebase',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                AppText(
                  'Chạy flutterfire configure, bật Authentication và Firestore, '
                  'kiểm tra cấu hình Android rồi khởi chạy lại ứng dụng.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
