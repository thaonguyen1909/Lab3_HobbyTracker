import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/viewmodels/auth_view_model.dart';
import 'package:hobby_tracker/viewmodels/feature_actions.dart';
import 'package:hobby_tracker/viewmodels/hyper_view_model.dart';
import 'full_ui_test.dart' show mount;
import 'router_test.dart' show FakeAuthService;
import 'support/fakes.dart';

class ProfileCountingAuth extends FakeAuthService {
  ProfileCountingAuth()
    : super(
        user: const AuthUser(uid: 'owner-001', displayName: 'Test Owner'),
      );
  int profileChecks = 0;
  @override
  Future<void> ensureOwnProfile(AuthUser user) async {
    profileChecks++;
    await super.ensureOwnProfile(user);
  }

  void metadata(String name) {
    user = AuthUser(
      uid: user!.uid,
      displayName: name,
      providers: const ['google.com'],
    );
    changes.add(user);
  }
}

class AuthUpdatingRepository extends TestRepository {
  AuthUpdatingRepository(this.auth);
  final ProfileCountingAuth auth;
  @override
  Future<void> savePreferences(String uid, AppPreferences p) async {
    await super.savePreferences(uid, p);
    // Firebase userChanges fires after updateDisplayName, including same UID.
    auth.metadata(p.displayName);
  }
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'all six Settings saves keep route and only bootstrap account once',
    (tester) async {
      final auth = ProfileCountingAuth();
      final c = await mount(
        tester,
        authService: auth,
        repository: AuthUpdatingRepository(auth),
      );
      final router = c.read(appRouterProvider);
      final seen = <String>[];
      void record() => seen.add(router.routeInformationProvider.value.uri.path);
      router.routeInformationProvider.addListener(record);
      addTearDown(() => router.routeInformationProvider.removeListener(record));
      for (final section in [
        'profile',
        'apps',
        'notifications',
        'hyper',
        'privacy',
        'appearance',
      ]) {
        router.go('/settings/$section');
        await tester.pumpAndSettle();
        expect(
          await c
              .read(featureActionsProvider.notifier)
              .preferences(AppPreferences(displayName: 'Saved $section')),
          true,
        );
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/settings/$section',
        );
        expect(c.read(currentUserProvider)?.displayName, 'Saved $section');
        expect(auth.profileChecks, 1);
        expect(find.byType(SnackBar), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text('Đã lưu cài đặt.'), findsNothing);
      }
      expect(seen, isNot(contains('/auth/loading')));
      expect(seen, isNot(contains('/home')));
    },
  );
  testWidgets(
    'same-account metadata keeps every feature page; changed UID still rechecks gate',
    (tester) async {
      final auth = ProfileCountingAuth();
      final c = await mount(tester, authService: auth);
      final router = c.read(appRouterProvider);
      auth.profileUnavailable = true;
      for (final path in [
        '/home',
        '/home/hyper?hobby=h1',
        '/hobbies',
        '/hobbies/h1',
        '/community/feed',
        '/community/groups',
        '/community/activities',
        '/community/people',
        '/community/chats',
        '/community/chat/test',
        '/settings',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        auth.metadata('Updated account');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.toString(), path);
        expect(auth.profileChecks, 1);
      }
      c.read(hyperProvider.notifier).pause();
      auth.user = const AuthUser(uid: 'different-owner', displayName: 'Other');
      auth.changes.add(auth.user);
      await tester.pumpAndSettle();
      expect(auth.profileChecks, 2);
      expect(router.routeInformationProvider.value.uri.path, '/auth/error');
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/auth/login');
    },
  );
  testWidgets(
    'metadata refresh preserves unsaved profile and provider metadata updates',
    (tester) async {
      final auth = ProfileCountingAuth();
      final c = await mount(tester, authService: auth);
      c.read(appRouterProvider).go('/settings/profile');
      await tester.pumpAndSettle();
      final field = find.byType(TextField).first;
      await tester.enterText(field, 'Unsaved draft');
      auth.metadata('Refreshed name');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'Unsaved draft');
      expect(c.read(currentUserProvider)!.hasGoogle, true);
      expect(c.read(currentUserProvider)!.displayName, 'Refreshed name');
      expect(auth.profileChecks, 1);
    },
  );
  testWidgets(
    'success can be dismissed and does not reappear on another page or theme rebuild',
    (tester) async {
      final c = await mount(tester);
      final actions = c.read(featureActionsProvider.notifier);
      await actions.preferences(const AppPreferences(displayName: 'Saved'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      c.read(appRouterProvider).go('/hobbies');
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(c.read(featureActionsProvider).message, isNull);
      await actions.exportReport([], []);
      await tester.pumpAndSettle();
      expect(c.read(featureActionsProvider).pdf, isNotNull);
      c.read(appRouterProvider).go('/settings/profile');
      await tester.pumpAndSettle();
      expect(c.read(featureActionsProvider).pdf, isNotNull);
      expect(find.byType(SnackBar), findsNothing);
    },
  );
}
