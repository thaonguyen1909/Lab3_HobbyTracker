import 'package:hobby_tracker/l10n/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/app.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/viewmodels/data_providers.dart';
import 'router_test.dart' show FakeAuthService;
import 'support/fakes.dart';

Future<ProviderContainer> mount(
  WidgetTester tester, {
  double width = 360,
  FakeAuthService? authService,
  TestRepository? repository,
  LanguageStore? languageStore,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  final auth =
      authService ??
      FakeAuthService(
        user: const AuthUser(uid: 'owner-001', displayName: 'Test Owner'),
      );
  final repo = repository ?? TestRepository(), device = TestDeviceServices();
  repo.hobbyData['owner-001'] = {
    'h1': const Hobby(
      id: 'h1',
      name: 'Đàn guitar',
      description: 'Luyện tập mỗi ngày',
      icon: 'music',
      color: 'mint',
      priority: 'interested',
    ),
  };
  repo.posts.add(
    const SocialEntry(
      id: 'post',
      data: {
        'authorName': 'Test fixture',
        'text': 'Một bước tiến mới',
        'topic': 'Đàn guitar',
      },
    ),
  );
  final c = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      languageStoreProvider.overrideWithValue(
        languageStore ?? TestLanguageStore(),
      ),
      repositoryProvider.overrideWithValue(repo),
      deviceServicesProvider.overrideWithValue(device),
      reportUploaderProvider.overrideWithValue(TestReportUploader()),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await auth.dispose();
    await repo.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const HobbyTrackerApp()),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final width in [360.0, 412.0]) {
    testWidgets('All signed-in destinations render at ${width}dp', (
      tester,
    ) async {
      final c = await mount(tester, width: width);
      final router = c.read(appRouterProvider);
      for (final (path, key) in [
        ('/home', 'home'),
        ('/hobbies', 'hobbies'),
        ('/hobbies/h1', 'detail'),
        ('/home/hyper', 'hyper'),
        ('/community/feed', 'feed'),
        ('/community/groups', 'groups'),
        ('/community/activities', 'activities'),
        ('/community/people', 'people'),
        ('/community/chats', 'chats'),
        ('/community/chat/test', 'conversation'),
        ('/settings', 'settings'),
        for (final section in [
          'profile',
          'apps',
          'notifications',
          'hyper',
          'privacy',
          'appearance',
        ])
          ('/settings/$section', 'settings-detail'),
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('screen-$key')),
          findsOneWidget,
          reason: path,
        );
        expect(tester.takeException(), isNull, reason: path);
        if (const bool.fromEnvironment('CAPTURE_PREVIEWS') &&
            ['home', 'hobbies', 'hyper', 'feed', 'settings'].contains(key)) {
          await expectLater(
            find.byType(HobbyTrackerApp),
            matchesGoldenFile('goldens/${key}_${width.toInt()}.png'),
          );
        }
      }
    });
  }
  testWidgets('hobby editor preserves draft on duplicate and recovers', (
    tester,
  ) async {
    final c = await mount(tester);
    c.read(appRouterProvider).go('/hobbies');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('create-hobby')));
    await tester.pumpAndSettle();
    final name = find.descendant(
      of: find.byKey(const ValueKey('hobby-name')),
      matching: find.byType(TextField),
    );
    await tester.enterText(name, 'Đàn guitar');
    final priority = find.textContaining('Interested').last;
    await tester.ensureVisible(priority);
    await tester.tap(priority);
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('save-hobby'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('already exists'), findsWidgets);
    expect(tester.widget<TextField>(name).controller!.text, 'Đàn guitar');
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Vẽ tranh');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Vẽ tranh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Remote Config community flag changes visible behavior', (
    tester,
  ) async {
    final c = await mount(tester);
    final device = c.read(deviceServicesProvider) as TestDeviceServices;
    device.config = const RuntimeFlags(community: false, feedLimit: 5);
    c.invalidate(flagsProvider);
    c.read(appRouterProvider).go('/community/feed');
    await tester.pumpAndSettle();
    expect(find.text('Community is taking a break'), findsOneWidget);
    expect(find.text('Chia sẻ tiến bộ'), findsNothing);
  });
  testWidgets('all seven saved theme choices apply without clearing hobbies', (
    tester,
  ) async {
    final c = await mount(tester);
    final repo = c.read(repositoryProvider) as TestRepository;
    for (final label in [
      'Light',
      'Dark',
      'Energetic',
      'Cyber',
      'Art',
      'Sad',
      'Rainy Day',
    ]) {
      await repo.savePreferences(
        'owner-001',
        AppPreferences(theme: label, displayName: 'Test Owner'),
      );
      await tester.pumpAndSettle();
      expect(repo.hobbyData['owner-001']!.length, 1);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'Figma settings choices persist immediately and preserve hobbies',
    (tester) async {
      final c = await mount(tester);
      final repo = c.read(repositoryProvider) as TestRepository;
      c.read(appRouterProvider).go('/settings/apps');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();
      expect(repo.preferenceData['owner-001']!.music, 'spotify');
      c.read(appRouterProvider).go('/settings/appearance');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(repo.preferenceData['owner-001']!.theme, 'Dark');
      expect(repo.hobbyData['owner-001']!.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
