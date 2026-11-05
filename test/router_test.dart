import 'support/fakes.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/app.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/app/router/route_paths.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:hobby_tracker/services/auth_service.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({this.user});
  AuthUser? user;
  final changes = StreamController<AuthUser?>.broadcast();
  bool cancelGoogle = false;
  bool profileUnavailable = false;
  int signouts = 0;
  int resets = 0;
  int links = 0;
  final registeredNames = <String>[];

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield user;
    yield* changes.stream;
  }

  @override
  Future<void> ensureOwnProfile(AuthUser u) async {
    if (profileUnavailable) throw const AuthFailure('Firestore không khả dụng');
  }

  @override
  Future<void> signInWithGoogle() async {
    if (cancelGoogle) throw const AuthCancelled();
    user = const AuthUser(
      uid: 'google-uid',
      email: 'google@test.invalid',
      providers: ['google.com'],
    );
    changes.add(user);
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    if (password == 'bad') {
      throw const AuthFailure('Email hoặc mật khẩu không đúng.');
    }
    user = AuthUser(uid: 'email-uid', email: email);
    changes.add(user);
  }

  @override
  Future<void> registerWithEmail(
    String email,
    String password, {
    required String displayName,
  }) async {
    registeredNames.add(displayName);
    await signInWithEmail(email, password);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resets++;
  }

  @override
  Future<void> linkGoogleToCurrentAccount() async {
    links++;
  }

  @override
  Future<void> signOut() async {
    signouts++;
    user = null;
    changes.add(null);
  }

  Future<void> dispose() => changes.close();
}

Widget appWith(FakeAuthService fake) => ProviderScope(
  overrides: [
    authServiceProvider.overrideWithValue(fake),
    repositoryProvider.overrideWithValue(TestRepository()),
    deviceServicesProvider.overrideWithValue(TestDeviceServices()),
  ],
  child: const HobbyTrackerApp(),
);

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  const signedIn = AuthUser(uid: 'owner-001', email: 'owner@test.invalid');

  testWidgets('Unauthenticated deep link always redirects to Login', (
    tester,
  ) async {
    final fake = FakeAuthService();
    addTearDown(fake.dispose);
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(fake),
        repositoryProvider.overrideWithValue(TestRepository()),
        deviceServicesProvider.overrideWithValue(TestDeviceServices()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(RoutePaths.hobbies);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HobbyTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-navigation')), findsNothing);
  });

  testWidgets('Signed-in account opens Home and switches 4 tabs', (
    tester,
  ) async {
    final fake = FakeAuthService(user: signedIn);
    addTearDown(fake.dispose);
    await tester.pumpWidget(appWith(fake));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
    for (final (tab, screen) in [
      ('tab-community', 'screen-feed'),
      ('tab-hobbies', 'screen-hobbies'),
      ('tab-settings', 'screen-settings'),
      ('tab-home', 'screen-home'),
    ]) {
      await tester.tap(find.byKey(ValueKey(tab)));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(screen)), findsOneWidget);
    }
  });

  testWidgets('Sign out requires confirmation, then returns to Login', (
    tester,
  ) async {
    final fake = FakeAuthService(user: signedIn);
    addTearDown(fake.dispose);
    await tester.pumpWidget(appWith(fake));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('sign-out')));
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(fake.signouts, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fake.signouts, 0);
    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out').last);
    await tester.pumpAndSettle();
    expect(fake.signouts, 1);
    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
  });

  testWidgets(
    'Google cancellation is visible and does not open a protected route',
    (tester) async {
      final fake = FakeAuthService()..cancelGoogle = true;
      addTearDown(fake.dispose);
      await tester.pumpWidget(appWith(fake));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('login-google')));
      await tester.tap(find.byKey(const ValueKey('login-google')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Google sign-in canceled'), findsOneWidget);
      expect(find.byKey(const ValueKey('bottom-navigation')), findsNothing);
    },
  );

  testWidgets('Register rejects mismatched password before calling service', (
    tester,
  ) async {
    final fake = FakeAuthService();
    addTearDown(fake.dispose);
    await tester.pumpWidget(appWith(fake));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('Create account'));
    await tester.tap(find.textContaining('Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('register-email')),
        matching: find.byType(TextField),
      ),
      'name@example.com',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('register-password')),
        matching: find.byType(TextField),
      ),
      'secret123',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('register-confirm')),
        matching: find.byType(TextField),
      ),
      'not-matching',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('register-submit')));
    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();
    expect(find.textContaining('do not match'), findsOneWidget);
    expect(fake.user, isNull);
  });

  testWidgets('Forgot password calls service and confirms request', (
    tester,
  ) async {
    final fake = FakeAuthService();
    addTearDown(fake.dispose);
    await tester.pumpWidget(appWith(fake));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot?'));
    await tester.tap(find.text('Forgot?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('reset-email')),
        matching: find.byType(TextField),
      ),
      'me@example.com',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('reset-submit')));
    await tester.tap(find.byKey(const ValueKey('reset-submit')));
    await tester.pumpAndSettle();
    expect(fake.resets, 1);
    expect(find.textContaining('password reset instructions'), findsWidgets);
  });

  testWidgets('Firestore profile failure shows retry gate instead of Home', (
    tester,
  ) async {
    final fake = FakeAuthService(user: signedIn)..profileUnavailable = true;
    addTearDown(fake.dispose);
    await tester.pumpWidget(appWith(fake));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not sync your account profile'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('screen-home')), findsNothing);
  });
  for (final width in [360.0, 412.0]) {
    testWidgets('Register validates name and submits draft at ${width}dp', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fake = FakeAuthService();
      addTearDown(fake.dispose);
      await tester.pumpWidget(appWith(fake));
      await tester.pumpAndSettle();
      final registerLink = find.textContaining('Create account');
      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();
      for (final entry in {
        'register-email': 'alice@example.com',
        'register-password': 'secret123',
        'register-confirm': 'secret123',
      }.entries) {
        final field = find.byKey(ValueKey(entry.key));
        await tester.ensureVisible(field);
        await tester.enterText(
          find.descendant(of: field, matching: find.byType(TextField)),
          entry.value,
        );
      }
      final submit = find.byKey(const ValueKey('register-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(fake.registeredNames, isEmpty);
      expect(
        find.text('Name must contain 2 to 80 characters.'),
        findsOneWidget,
      );
      final nameField = find.byKey(const ValueKey('register-name'));
      await tester.ensureVisible(nameField);
      await tester.enterText(
        find.descendant(of: nameField, matching: find.byType(TextField)),
        ' Alice ',
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(fake.registeredNames, ['Alice']);
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
