import 'package:hobby_tracker/services/pdf_report_exporter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/l10n/app_strings.dart';
import 'package:hobby_tracker/l10n/language_controller.dart';
import 'package:hobby_tracker/l10n/messages.dart';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/auth_service_provider.dart';
import 'package:hobby_tracker/services/app_services.dart';
import 'package:hobby_tracker/viewmodels/feature_actions.dart';
import 'package:hobby_tracker/app/router/app_router.dart';
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
  test(
    'language persists across controller recreation, invalid values rejected and failed saves rollback',
    () async {
      final store = TestLanguageStore(code: 'vi');
      final c = LanguageController(store);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.code, 'vi');
      expect(await c.select('en'), true);
      expect(store.code, 'en');
      store.failWrites = true;
      expect(await c.select('vi'), false);
      expect(c.state.code, 'en');
      expect(c.state.error, isNotNull);
      expect(await c.select('fr'), false);
      c.dispose();
      final restored = LanguageController(store);
      await Future<void>.delayed(Duration.zero);
      expect(restored.state.code, 'en');
      restored.dispose();
    },
  );
  test(
    'catalog covers both languages, dynamic errors, counts and branded names',
    () {
      for (final entry in localizedMessages.entries) {
        expect(entry.value.length, 2, reason: entry.key);
        if (entry.value[0] != 'Cốc Cốc') {
          expect(
            RegExp(r'[À-ỹ]').hasMatch(entry.value[0]),
            false,
            reason: 'Vietnamese leaked into English catalog: ${entry.key}',
          );
        }
        expect(entry.value.every((v) => v.isNotEmpty), true, reason: entry.key);
      }
      expect(const AppStrings('en').text('Đã lưu cài đặt.'), 'Settings saved.');
      expect(const AppStrings('vi').text('Settings'), 'Cài đặt');
      expect(
        const AppStrings('en').text(
          'Không thể mở đăng nhập Google (sign_in_failed). Kiểm tra cấu hình OAuth/SHA.',
        ),
        contains('Could not open Google sign-in (sign_in_failed)'),
      );
      expect(const AppStrings('vi').text('3 saved'), 'Đã lưu 3 phiên');
      expect(const AppStrings('en').text('15 phút'), '15 minutes');
      expect(const AppStrings('vi').text('Hobby Tracker'), 'Hobby Tracker');
      expect(
        const AppStrings('en').text('Name{1} — 2 phút — today'),
        'Name{1} — 2 minutes — today',
      );
    },
  );
  testWidgets(
    'language setting switches immediately, keeps current route and survives sign out',
    (tester) async {
      final store = TestLanguageStore();
      final c = await mount(tester, languageStore: store);
      final router = c.read(appRouterProvider);
      router.go('/settings/language');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-vi')));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/settings/language',
      );
      expect(find.text('Ngôn ngữ ứng dụng'), findsOneWidget);
      expect(store.code, 'vi');
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsWidgets);
      expect(find.text('Home'), findsNothing);
      await c.read(authServiceProvider).signOut();
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Continue with Google'), findsNothing);
      expect(store.code, 'vi');
    },
  );
  testWidgets(
    'language-save failure leaves previous language selected and allows retry',
    (tester) async {
      final store = TestLanguageStore()..failWrites = true;
      final c = await mount(tester, languageStore: store);
      c.read(appRouterProvider).go('/settings/language');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-vi')));
      await tester.pumpAndSettle();
      expect(c.read(languageProvider).code, 'en');
      expect(
        find.text('Could not save language. Please try again.'),
        findsOneWidget,
      );
      store.failWrites = false;
      await tester.tap(find.byKey(const ValueKey('language-vi')));
      await tester.pumpAndSettle();
      expect(c.read(languageProvider).code, 'vi');
      expect(c.read(languageProvider).error, isNull);
    },
  );
  for (final code in ['en', 'vi']) {
    for (final width in [360.0, 412.0]) {
      testWidgets('all screens and user content render in $code at $width dp', (
        tester,
      ) async {
        final c = await mount(
          tester,
          width: width,
          languageStore: TestLanguageStore(code: code),
        );
        final router = c.read(appRouterProvider);
        final repo = c.read(repositoryProvider) as TestRepository;
        // Names matching translation keys must remain user content.
        repo.hobbyData['owner-001']!['h1'] = const Hobby(
          id: 'h1',
          name: 'Home',
          description: 'Settings',
          icon: 'music',
          color: 'mint',
          priority: 'interested',
        );
        repo.groupData.add(
          const SocialEntry(
            id: 'group',
            data: {
              'name': 'Settings',
              'topic': 'Home',
              'description': 'Language',
            },
          ),
        );
        repo.emit();
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
          '/community/chat/empty',
          '/settings',
          '/settings/profile',
          '/settings/apps',
          '/settings/notifications',
          '/settings/hyper',
          '/settings/privacy',
          '/settings/appearance',
          '/settings/language',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$code $path');
          final appText = tester.widgetList<AppText>(find.byType(AppText));
          final untranslated = <String>[];
          for (final w in appText) {
            final shown = AppStrings(code).text(w.data);
            final english = RegExp(
              r'[A-Za-z]{3,}',
            ).hasMatch(w.data.replaceFirst(RegExp(r'^✓\s*'), ''));
            final vietnamese = RegExp(
              r'[À-ỹ]',
            ).hasMatch(w.data.replaceFirst(RegExp(r'^✓\s*'), ''));
            final neutral = RegExp(
              r'^(?:[0-9: ./·]+|hobby|CRASH|(?:Google|Spotify|YouTube|Cốc Cốc)(?: ↗)?)$',
            ).hasMatch(w.data.replaceFirst(RegExp(r'^✓\s*'), ''));
            if (code == 'vi' &&
                english &&
                !vietnamese &&
                !neutral &&
                shown == w.data) {
              untranslated.add(w.data);
            }
          }
          expect(
            untranslated,
            isEmpty,
            reason: 'Missing Vietnamese UI copy at $path',
          );
          if (path == '/hobbies/h1') {
            expect(find.text('Home'), findsWidgets);
            expect(
              tester
                  .widget<Text>(
                    find.byKey(const ValueKey('hobby-description-content')),
                  )
                  .data,
              'Settings',
            );
          }
        }
        // App-owned errors and success feedback use the selected language.
        repo.failWrites = true;
        await c
            .read(featureActionsProvider.notifier)
            .preferences(const AppPreferences(displayName: 'Owner'));
        await tester.pumpAndSettle();
        expect(
          find.byTooltip(code == 'vi' ? 'Đóng thông báo lỗi' : 'Dismiss error'),
          findsOneWidget,
        );
        await c.read(authServiceProvider).signOut();
        await tester.pumpAndSettle();
        for (final path in [
          '/auth/login',
          '/auth/register',
          '/auth/forgot-password',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$code $path');
        }
      });
    }
  }
  testWidgets(
    'Vietnamese Material date picker and field validation use Vietnamese',
    (tester) async {
      final c = await mount(
        tester,
        languageStore: TestLanguageStore(code: 'vi'),
      );
      c.read(appRouterProvider).go('/home');
      await tester.pumpAndSettle();
      final context = tester.element(find.text('Trang chủ').first);
      expect(Localizations.localeOf(context).languageCode, 'vi');
      expect(
        MaterialLocalizations.of(context).cancelButtonLabel.toLowerCase(),
        anyOf('hủy', 'huỷ'),
      );
      showDatePicker(
        context: context,
        initialDate: DateTime(2026, 11, 3),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final code in ['en', 'vi']) {
    testWidgets(
      'creation sheets, validation and schedules are localized in $code',
      (tester) async {
        final c = await mount(
          tester,
          languageStore: TestLanguageStore(code: code),
        );
        final strings = AppStrings(code);
        final router = c.read(appRouterProvider);
        router.go('/hobbies');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('create-hobby')));
        await tester.pumpAndSettle();
        expect(find.text(strings.text('Hobby name *')), findsOneWidget);
        expect(tester.takeException(), isNull);
        final save = find.byKey(const ValueKey('save-hobby'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          find.text(strings.text('Tên cần 2–50 ký tự và không chứa dấu /.')),
          findsWidgets,
        );
        await tester.tap(find.byTooltip(strings.text('Close')));
        await tester.pumpAndSettle();
        router.go('/home');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('add-schedule')));
        await tester.pumpAndSettle();
        expect(find.text(strings.text('Tên buổi luyện tập')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(strings.text('Close')));
        await tester.pumpAndSettle();
        router.go('/community/feed');
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.text('+ Write a post')));
        await tester.pumpAndSettle();
        expect(find.text(strings.text('Your post')), findsOneWidget);
        expect(find.text(strings.text('Publish')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('large text screens are usable in $code', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await mount(
        tester,
        languageStore: TestLanguageStore(code: code),
      );
      for (final path in [
        '/home',
        '/hobbies',
        '/home/hyper?hobby=h1',
        '/community/feed',
        '/settings',
        '/settings/language',
      ]) {
        c.read(appRouterProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$code $path');
      }
    });
    test('PDF output and headings follow $code', () async {
      final exporter = PdfReportExporter(languageCode: code);
      expect(
        exporter.t('Hobby Tracker — Báo cáo hoạt động'),
        code == 'vi'
            ? 'Hobby Tracker — Báo cáo hoạt động'
            : 'Hobby Tracker — Activity report',
      );
      expect(exporter.t('12 phút'), code == 'vi' ? '12 phút' : '12 minutes');
      final bytes = await exporter.export([], []);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });
  }
}
