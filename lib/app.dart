import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/language_controller.dart';
import 'l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/router/app_router.dart';
import 'theme/hobby_theme.dart';
import 'viewmodels/data_providers.dart';
import 'viewmodels/feature_actions.dart';
import 'viewmodels/runtime_controller.dart';
import 'firebase/firebase_runtime.dart';
import 'features/community/screens/moments/moment_alert_overlay.dart';

class HobbyTrackerApp extends ConsumerStatefulWidget {
  const HobbyTrackerApp({super.key});
  @override
  ConsumerState<HobbyTrackerApp> createState() => _HobbyTrackerAppState();
}

class _HobbyTrackerAppState extends ConsumerState<HobbyTrackerApp> {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final GoRouter router;
  late String route;
  int routeRevision = 0;

  @override
  void initState() {
    super.initState();
    router = ref.read(appRouterProvider);
    route = router.routeInformationProvider.value.uri.toString();
    router.routeInformationProvider.addListener(onRouteChanged);
  }

  void onRouteChanged() {
    final next = router.routeInformationProvider.value.uri.toString();
    if (next == route) return;
    route = next;
    routeRevision++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      messengerKey.currentState?.clearSnackBars();
      ref.read(featureActionsProvider.notifier).clearFeedback();
    });
  }

  void feedback(FeatureActionState state) {
    if (state.busy) {
      messengerKey.currentState?.clearSnackBars();
      return;
    }
    final message = state.message;
    if (message == null) return;
    final revision = routeRevision;
    final uid = ref.read(ownerIdProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          revision != routeRevision ||
          uid != ref.read(ownerIdProvider)) {
        return;
      }
      final messenger = messengerKey.currentState;
      if (messenger == null) return;
      // Replace, rather than queue, feedback from repeated actions.
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          key: const ValueKey('feature-feedback'),
          content: AppText(message),
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    router.routeInformationProvider.removeListener(onRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(runtimeControllerProvider);
    ref.listen(featureActionsProvider, (previous, next) => feedback(next));
    final label = ref.watch(preferencesProvider).valueOrNull?.theme;
    final variant =
        AppThemeVariant.values.where((v) => v.label == label).firstOrNull ??
        AppThemeVariant.light;
    final language = ref.watch(languageProvider);
    return MaterialApp.router(
      title: 'Hobby Tracker',
      builder: (context, child) => language.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : ref.watch(firebaseRuntimeConfigProvider).emulators
          ? Banner(
              message: 'LOCAL EMULATORS',
              location: BannerLocation.topEnd,
              child: MomentAlertOverlay(child: child!),
            )
          : MomentAlertOverlay(child: child!),
      locale: Locale(language.code),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: HobbyTheme.forVariant(variant),
      routerConfig: router,
    );
  }
}
