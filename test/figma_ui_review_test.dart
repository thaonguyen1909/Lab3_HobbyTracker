import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/app.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';
import 'package:hobby_tracker/theme/hobby_theme.dart';
import 'package:hobby_tracker/widgets/figma_assets.dart';
import 'full_ui_test.dart' show mount;
import 'support/fakes.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 410.0, 412.0]) {
    testWidgets('Figma screens, sheets and seven themes at ${width}dp', (
      tester,
    ) async {
      final c = await mount(tester, width: width);
      tester.view.physicalSize = Size(width, 930);
      final repo = c.read(repositoryProvider) as TestRepository;
      repo.hobbyData['owner-001'] = {
        'h1': const Hobby(
          id: 'h1',
          name: 'Photography',
          description: 'Photo walks and everyday discoveries.',
          icon: 'camera',
          color: 'mint',
          priority: 'active',
        ),
      };
      final now = DateTime.now();
      repo.planData['owner-001'] = {
        'p1': PracticePlan(
          id: 'p1',
          hobbyId: 'h1',
          title: 'Photography practice',
          startsAt: DateTime(now.year, now.month, now.day, 17),
          minutes: 30,
        ),
      };
      repo.posts.clear();
      repo.posts.add(
        const SocialEntry(
          id: 'post',
          data: {
            'authorName': 'Mai',
            'text':
                'I tried my first photo walk today! Any beginner composition tips?',
            'topic': 'Photography',
          },
        ),
      );
      repo.groupData.add(
        const SocialEntry(
          id: 'g1',
          data: {
            'name': 'Photo Circle',
            'topic': 'Photography',
            'description': 'Beginner photo walks and friendly critique.',
          },
        ),
      );
      repo.eventData.add(
        SocialEntry(
          id: 'e1',
          data: {
            'title': 'Beginner Photo Walk',
            'topic': 'Photography',
            'startsAt': now.add(const Duration(days: 1)),
          },
        ),
      );
      repo.peopleData.add(
        const SocialEntry(
          id: 'mai',
          data: {
            'displayName': 'Mai',
            'bio': 'Photography',
            'allowMessages': true,
          },
        ),
      );
      repo.chatData['owner-001'] = [
        const SocialEntry(
          id: 'test',
          data: {
            'participants': ['owner-001', 'mai'],
          },
        ),
      ];
      repo.messageData['test'] = [
        const SocialEntry(
          id: 'm1',
          data: {
            'senderId': 'mai',
            'text': 'Hey! Have you tried photography around campus?',
          },
        ),
      ];
      repo.emit();
      await tester.pumpAndSettle();
      final router = c.read(appRouterProvider);
      Future<void> capture(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$name at $width');
        if (const bool.fromEnvironment('CAPTURE_FIGMA')) {
          await expectLater(
            find.byType(HobbyTrackerApp),
            matchesGoldenFile('figma_review/${name}_${width.toInt()}.png'),
          );
        }
      }

      for (final (path, name) in [
        ('/home', 'home'),
        ('/hobbies', 'hobbies'),
        ('/hobbies/h1', 'detail'),
        ('/home/hyper?hobby=h1', 'hyper'),
        ('/community/feed', 'feed'),
        ('/community/groups', 'groups'),
        ('/community/activities', 'activities'),
        ('/community/people', 'people'),
        ('/community/chats', 'inbox'),
        ('/community/chat/test', 'conversation'),
        ('/settings', 'settings'),
        for (final s in [
          'profile',
          'apps',
          'notifications',
          'hyper',
          'privacy',
          'appearance',
        ])
          ('/settings/$s', 'settings_$s'),
      ]) {
        router.go(path);
        await capture(name);
      }
      router.go('/hobbies');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('create-hobby')));
      await capture('create_hobby');
      expect(find.text('LIVE CARD PREVIEW'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      router.go('/community/feed');
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Write a post'));
      await capture('create_post');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      router.go('/settings');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('sign-out')));
      await tester.tap(find.byKey(const ValueKey('sign-out')));
      await capture('signout');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      for (final variant in AppThemeVariant.values) {
        await repo.savePreferences(
          'owner-001',
          AppPreferences(theme: variant.label, displayName: 'Test Owner'),
        );
        router.go('/home');
        await capture('theme_${variant.name}');
        expect(find.byType(ThemeMotif), findsWidgets);
      }
      await repo.savePreferences('owner-001', const AppPreferences());
      await c.read(authServiceProvider).signOut();
      await tester.pumpAndSettle();
      for (final (path, name) in [
        ('/auth/login', 'signin'),
        ('/auth/register', 'register'),
        ('/auth/forgot-password', 'forgot'),
      ]) {
        router.go(path);
        await capture(name);
      }
    });
  }
}
