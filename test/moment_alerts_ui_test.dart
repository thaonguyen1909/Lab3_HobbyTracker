import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hobby_tracker/app.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/app/router/route_paths.dart';
import 'package:hobby_tracker/l10n/language_controller.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/models/moment_alert.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';
import 'package:hobby_tracker/services/local_owner_store.dart';
import 'package:hobby_tracker/services/moment_alert_providers.dart';
import 'package:hobby_tracker/services/moment_providers.dart';
import 'package:hobby_tracker/viewmodels/hyper_view_model.dart';
import 'router_test.dart' show FakeAuthService;
import 'support/fakes.dart';
import 'support/moment_fakes.dart';
import 'support/moment_alert_fakes.dart';

class AlertPreferences extends Mock implements SharedPreferencesAsync {
  final values = <String, Object>{'active_owner': 'owner-001'};
  @override
  Future<String?> getString(String key) async => values[key] as String?;
  @override
  Future<bool?> getBool(String key) async => values[key] as bool?;
  @override
  Future<void> setBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    values[key] = value;
  }

  @override
  Future<Map<String, Object?>> getAll({Set<String>? allowList}) async =>
      Map.fromEntries(
        values.entries.where(
          (e) => allowList == null || allowList.contains(e.key),
        ),
      );

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

void main() {
  final bytes = File('test/fixtures/moment.jpg').readAsBytesSync();
  late TestMomentAlertRepository alerts;
  late TestMomentRepository moments;
  late StreamController<Map<String, dynamic>> pushes;
  late TestRepository repo;
  late FakeAuthService auth;
  late TestMomentClock clock;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });
  setUp(() {
    alerts = TestMomentAlertRepository();
    repo = TestRepository();
    auth = FakeAuthService(
      user: const AuthUser(uid: 'owner-001', displayName: 'Test'),
    );
    clock = TestMomentClock(DateTime.utc(2026, 11, 4));
    moments = TestMomentRepository(clock, bytes);
    moments.moments['m1'] = moments.sample(authorId: 'another');
    pushes = StreamController.broadcast();
    repo.joined['owner-001'] = [
      const SocialEntry(id: 'g1', data: {'name': 'Badminton'}),
    ];
  });
  MomentAlert event() => MomentAlert(
    eventId: 'moment_m1',
    groupId: 'g1',
    momentId: 'm1',
    expiresAt: moments.moments['m1']!.expiresAt,
  );
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 360,
    String language = 'en',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    final c = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        repositoryProvider.overrideWithValue(repo),
        deviceServicesProvider.overrideWithValue(TestDeviceServices()),
        languageStoreProvider.overrideWithValue(
          TestLanguageStore(code: language),
        ),
        momentRepositoryProvider.overrideWithValue(moments),
        momentClockProvider.overrideWithValue(clock),
        momentAlertRepositoryProvider.overrideWithValue(alerts),
        momentPushProvider.overrideWithValue(pushes.stream),
        momentAlertLocalStoreProvider.overrideWithValue(
          LocalOwnerStore(preferences: AlertPreferences()),
        ),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      c.dispose();
      await pushes.close();
      await alerts.changes.close();
      await repo.dispose();
      await auth.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const HobbyTrackerApp()),
    );
    await tester.pumpAndSettle();
    return c;
  }

  for (final width in [360.0, 412.0]) {
    for (final language in ['en', 'vi']) {
      testWidgets(
        'verified popup and settings/inbox at $width dp in $language',
        (tester) async {
          final c = await mount(tester, width: width, language: language);
          final alert = event();
          alerts.entries = [alert];
          alerts.emit();
          pushes.add(alert.payload('owner-001'));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('moment-popup')), findsOneWidget);
          await tester.tap(
            find.text(language == 'en' ? 'View moment' : 'Xem khoảnh khắc'),
          );
          await tester.pumpAndSettle();
          expect(
            c.read(appRouterProvider).routeInformationProvider.value.uri.path,
            alert.path,
          );
          expect(alerts.entries.single.read, true);
          c.read(appRouterProvider).go(RoutePaths.momentAlerts);
          await tester.pumpAndSettle();
          expect(
            find.text(
              language == 'en' ? 'Moment alerts' : 'Nhận thông báo khoảnh khắc',
            ),
            findsOneWidget,
          );
          await tester.ensureVisible(find.text('Badminton'));
          await tester.tap(find.byType(SwitchListTile).last);
          await tester.pumpAndSettle();
          expect(alerts.muted, {'g1'});
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'Hyper practice stays running without navigation when a moment arrives',
    (tester) async {
      final c = await mount(tester);
      final vm = c.read(hyperProvider.notifier);
      vm.select(
        const Hobby(
          id: 'h1',
          name: 'Badminton',
          description: '',
          icon: 'sport',
          color: 'mint',
          priority: 'active',
        ),
      );
      vm.start();
      await tester.pump();
      final before = c
          .read(appRouterProvider)
          .routeInformationProvider
          .value
          .uri
          .path;
      pushes.add(event().payload('owner-001'));
      await tester.pump();
      await tester.pump();
      expect(c.read(hyperProvider).running, true);
      expect(find.byKey(const ValueKey('moment-popup')), findsNothing);
      expect(
        c.read(appRouterProvider).routeInformationProvider.value.uri.path,
        before,
      );
      vm.pause();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('moment-popup')), findsOneWidget);
      c.read(momentAlertControllerProvider.notifier).dismiss();
      await tester.pump();
    },
  );
  testWidgets(
    'wrong-owner push is ignored and large notification settings remain usable',
    (tester) async {
      final c = await mount(tester);
      pushes.add(event().payload('old-owner'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('moment-popup')), findsNothing);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      c.read(appRouterProvider).go(RoutePaths.momentAlerts);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Moment inbox'));
      expect(tester.takeException(), isNull);
    },
  );
}
