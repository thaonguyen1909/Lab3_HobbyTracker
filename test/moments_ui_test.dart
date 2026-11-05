import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/app.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/app/router/route_paths.dart';
import 'package:hobby_tracker/l10n/language_controller.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:hobby_tracker/models/group_moment.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';
import 'package:hobby_tracker/services/moment_providers.dart';
import 'package:hobby_tracker/features/community/screens/moments/moment_widgets.dart';
import 'router_test.dart' show FakeAuthService;
import 'support/fakes.dart';
import 'support/moment_fakes.dart';

void main() {
  final bytes = File('test/fixtures/moment.jpg').readAsBytesSync();
  late TestMomentClock clock;
  late TestMomentRepository moments;
  late TestRepository repo;
  late FakeAuthService auth;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  });
  setUp(() {
    clock = TestMomentClock(DateTime.utc(2026, 11, 4, 12));
    moments = TestMomentRepository(clock, bytes);
    repo = TestRepository();
    auth = FakeAuthService(
      user: const AuthUser(uid: 'owner-001', displayName: 'Test Owner'),
    );
    repo.hobbyData['owner-001'] = {
      'h1': const Hobby(
        id: 'h1',
        name: 'Guitar',
        description: '',
        icon: 'music',
        color: 'mint',
        priority: 'interested',
      ),
    };
    repo.joined['owner-001'] = [
      const SocialEntry(id: 'g1', data: {'name': 'Test Group'}),
    ];
  });

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 360,
    String language = 'en',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        repositoryProvider.overrideWithValue(repo),
        deviceServicesProvider.overrideWithValue(TestDeviceServices()),
        languageStoreProvider.overrideWithValue(
          TestLanguageStore(code: language),
        ),
        momentRepositoryProvider.overrideWithValue(moments),
        momentClockProvider.overrideWithValue(clock),
        momentPhotoPickerProvider.overrideWithValue(
          TestMomentPicker(MomentPhoto.checked(bytes)),
        ),
        momentDraftStoreProvider.overrideWithValue(TestMomentDraftStore()),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await repo.dispose();
      await auth.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HobbyTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final width in [360.0, 412.0]) {
    for (final language in ['en', 'vi']) {
      testWidgets('post/retry/view/expire at $width dp in $language', (
        tester,
      ) async {
        final container = await mount(tester, width: width, language: language);
        final router = container.read(appRouterProvider);
        router.go(RoutePaths.momentsForGroup('g1'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('create-moment')));
        await tester.tap(find.byKey(const ValueKey('create-moment')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('moment-gallery')));
        await tester.pumpAndSettle();
        final hobby = find.byKey(const ValueKey('moment-hobby-none'));
        await tester.ensureVisible(hobby);
        await tester.tap(hobby);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guitar').last);
        await tester.pumpAndSettle();
        final caption = find.descendant(
          of: find.byKey(const ValueKey('moment-caption')),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(caption);
        await tester.enterText(caption, 'Nội dung của người dùng');
        await tester.pump();
        moments.failPublishAfterCommit = true;
        final post = find.byKey(const ValueKey('post-moment'));
        await tester.ensureVisible(post);
        await tester.tap(post);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(caption).enabled, false);
        expect(moments.moments.length, 1);
        await tester.ensureVisible(post);
        await tester.tap(post);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          RoutePaths.moments,
        );
        expect(moments.uploads, 1);
        expect(find.text('Nội dung của người dùng'), findsOneWidget);
        final posted = moments.moments.values.single;
        clock.value = posted.expiresAt.subtract(const Duration(seconds: 2));
        router.go(RoutePaths.groupMoment('g1', posted.id));
        await tester.pumpAndSettle();
        expect(find.byType(PrivateMomentPhoto), findsOneWidget);
        clock.value = posted.expiresAt;
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(find.byType(PrivateMomentPhoto), findsNothing);
        expect(
          find.text(
            language == 'en'
                ? 'This moment has expired or is no longer available.'
                : 'Khoảnh khắc đã hết hạn hoặc không còn khả dụng.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('joining a group is required before opening the composer', (
    tester,
  ) async {
    repo.joined.clear();
    final container = await mount(tester);
    container.read(appRouterProvider).go(RoutePaths.moments);
    await tester.pumpAndSettle();
    expect(find.text('Join a group to share moments'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-moment')), findsNothing);
    expect(moments.calls, isEmpty);
  });

  testWidgets(
    'viewer clears image on background, rechecks permission on resume and restricts remove to author',
    (tester) async {
      moments.moments['m1'] = moments.sample(authorId: 'other-member');
      final container = await mount(tester);
      container.read(appRouterProvider).go(RoutePaths.groupMoment('g1', 'm1'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivateMomentPhoto), findsOneWidget);
      expect(find.text('Remove moment'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      // Flutter suspends frame rendering while paused. Verify private VM state
      // immediately; rendered widgets are replaced on the next resumed frame.
      expect(
        container.read(momentViewerProvider((groupId: 'g1', id: 'm1'))).image,
        isNull,
      );
      moments.readFailure = const MomentFailure(
        'permission-denied',
        'You no longer have access to this group.',
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.text('You no longer have access to this group.'),
        findsOneWidget,
      );
      expect(find.byType(PrivateMomentPhoto), findsNothing);
    },
  );

  testWidgets('large text does not overflow new photo form', (tester) async {
    final container = await mount(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    container.read(appRouterProvider).go(RoutePaths.createMoment('g1'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('post-moment')));
    expect(tester.takeException(), isNull);
  });
}
