import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/local_owner_store.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/viewmodels/hyper_view_model.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
import 'package:hobby_tracker/widgets/design_widgets.dart';
import 'full_ui_test.dart' show mount;
import 'support/fakes.dart';

class MemoryPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  const hobby = Hobby(
    id: 'h1',
    name: 'Guitar',
    description: '',
    icon: 'music',
    color: 'mint',
    priority: 'active',
  );
  test(
    'switching plans of same hobby updates link, protects an active draft and finishes only chosen plan',
    () async {
      final repo = TestRepository(), device = TestDeviceServices();
      final vm = HyperViewModel('alice', repo, device, tick: false);
      addTearDown(() async {
        vm.dispose();
        await repo.dispose();
      });
      for (final id in ['A', 'B']) {
        await repo.savePlan(
          'alice',
          PracticePlan(
            id: id,
            hobbyId: 'h1',
            title: id,
            startsAt: DateTime(2027),
            minutes: 30,
          ),
        );
      }
      vm.select(hobby, planId: 'A');
      final first = vm.state.sessionId;
      expect(vm.select(hobby, planId: 'B'), true);
      expect(vm.state.planId, 'B');
      expect(vm.state.sessionId, isNot(first));
      vm.notes('keep draft');
      expect(vm.select(hobby, planId: 'A'), false);
      expect(vm.state.planId, 'B');
      expect(vm.state.notes, 'keep draft');
      expect(await vm.finish(hobby), true);
      expect(repo.planData['alice']!['A']!.done, false);
      expect(repo.planData['alice']!['B']!.done, true);
      expect(repo.recordData['alice']!.values.single.planId, 'B');
    },
  );
  test(
    'inbox ignores preferences and malformed records, isolates owners and preserves valid notifications',
    () async {
      final prefs = MemoryPreferences();
      final data = <String, String>{};
      when(() => prefs.getKeys()).thenAnswer((_) async => data.keys.toSet());
      when(
        () => prefs.getString(any()),
      ).thenAnswer((i) async => data[i.positionalArguments[0]]);
      when(() => prefs.setString(any(), any())).thenAnswer((i) async {
        data[i.positionalArguments[0] as String] =
            i.positionalArguments[1] as String;
      });
      when(() => prefs.remove(any())).thenAnswer((i) async {
        data.remove(i.positionalArguments[0]);
      });
      final store = LocalOwnerStore(preferences: prefs);
      await store.setOwner('alice');
      final config = '${store.prefix('alice')}notification_preferences';
      data[config] = jsonEncode(const AppPreferences().toJson());
      data['${store.prefix('alice')}notification_bad'] = '{"id":null}';
      data['${store.prefix('alice')}notification_broken'] = 'not json';
      await store.saveNotification(
        'alice',
        InboxItem(
          id: 'one',
          title: 'Reminder',
          body: 'Practice',
          path: '/home',
          receivedAt: DateTime(2026),
        ),
      );
      await store.saveNotification(
        'bob',
        InboxItem(
          id: 'other',
          title: 'Private',
          body: 'Hidden',
          path: '/home',
          receivedAt: DateTime(2026),
        ),
      );
      expect((await store.notifications('alice')).map((i) => i.id), ['one']);
      expect(await store.notifications('bob'), isEmpty);
      expect(data[config], isNotNull);
      expect(
        data.containsKey('${store.prefix('alice')}notification_bad'),
        false,
      );
    },
  );
  for (final pause in [true, false]) {
    testWidgets('switch tab honors pauseOnExit=$pause without losing draft', (
      tester,
    ) async {
      final c = await mount(tester);
      final repo = c.read(repositoryProvider) as TestRepository;
      repo.preferenceData['owner-001'] = AppPreferences(
        displayName: 'Test Owner',
        pauseOnExit: pause,
      );
      repo.emit();
      await tester.pumpAndSettle();
      c.read(appRouterProvider).go('/home/hyper?hobby=h1');
      await tester.pumpAndSettle();
      final vm = c.read(hyperProvider.notifier);
      vm.notes('preserved');
      vm.start();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tab-community')));
      await tester.pumpAndSettle();
      final running = vm.state.running;
      vm.pause();
      c.read(appRouterProvider).go('/home');
      await tester.pumpAndSettle();
      expect(running, !pause);
      expect(vm.state.notes, 'preserved');
    });
  }
  testWidgets(
    'failed preference save rolls back and explicit retry persists choice',
    (tester) async {
      final c = await mount(tester);
      final repo = c.read(repositoryProvider) as TestRepository;
      repo.failWrites = true;
      c.read(appRouterProvider).go('/settings/apps');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spotify'));
      await tester.pumpAndSettle();
      final choices = tester.widgetList<DesignChoice>(
        find.byType(DesignChoice),
      );
      expect(choices.singleWhere((w) => w.label == 'YouTube').selected, true);
      expect(choices.singleWhere((w) => w.label == 'Spotify').selected, false);
      expect(repo.preferenceData['owner-001'], isNull);
      repo.failWrites = false;
      final retry = find.byKey(const ValueKey('retry-preferences'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.preferenceData['owner-001']!.music, 'spotify');
      expect(find.byKey(const ValueKey('retry-preferences')), findsNothing);
    },
  );
  testWidgets(
    'People directs sender without DM opt-in to privacy before creating chat',
    (tester) async {
      final c = await mount(tester);
      final repo = c.read(repositoryProvider) as TestRepository;
      repo.peopleData.add(
        const SocialEntry(
          id: 'bob',
          data: {'displayName': 'Bob', 'visible': true, 'allowMessages': true},
        ),
      );
      c.read(appRouterProvider).go('/community/people');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enable chat'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy & Safety'), findsOneWidget);
      expect(repo.chatData, isEmpty);
    },
  );
  testWidgets(
    'long chat shows newest message and composer stays visible with keyboard; send retries keep draft',
    (tester) async {
      final c = await mount(tester);
      final repo = c.read(repositoryProvider) as TestRepository;
      repo.messageData['long'] = List.generate(
        100,
        (i) => SocialEntry(
          id: 'm$i',
          data: {'senderId': 'bob', 'text': 'message $i'},
        ),
      );
      c.read(appRouterProvider).go('/community/chat/long');
      await tester.pumpAndSettle();
      expect(find.text('message 99'), findsOneWidget);
      final composer = find.descendant(
        of: find.byKey(const ValueKey('message-composer')),
        matching: find.byType(TextField),
      );
      await tester.enterText(composer, 'hello');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final send = find.byKey(const ValueKey('send-message'));
      expect(tester.getBottomRight(send).dy, lessThan(600));
      repo.failWrites = true;
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(composer).controller!.text, 'hello');
      repo.failWrites = false;
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(composer).controller!.text, isEmpty);
      expect(
        repo.messageData['long']!
            .where((m) => m.text('text') == 'hello')
            .length,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [360.0, 412.0]) {
    testWidgets(
      'Home at ${width}dp supports 200 percent text and 48dp calendar targets',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final c = await mount(tester, width: width);
        c.read(appRouterProvider).go('/home');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final dateButtons = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              RegExp(r'^\d+/\d+/\d+$').hasMatch(w.properties.label ?? ''),
        );
        expect(dateButtons, findsNWidgets(7));
        for (final e in dateButtons.evaluate()) {
          expect(
            (e.renderObject as RenderBox).size.width,
            greaterThanOrEqualTo(48),
          );
        }
      },
    );
  }
  testWidgets('all signed-in screens support large text at 360dp', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await mount(tester);
    for (final path in [
      '/hobbies',
      '/hobbies/h1',
      '/home/hyper?hobby=h1',
      '/community/feed',
      '/community/groups',
      '/community/activities',
      '/community/people',
      '/community/chats',
      '/community/chat/empty',
      '/settings',
      '/settings/profile',
      '/settings/apps',
      '/settings/notifications',
      '/settings/hyper',
      '/settings/privacy',
      '/settings/appearance',
    ]) {
      c.read(appRouterProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
    }
  });
}
