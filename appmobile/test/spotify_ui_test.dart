import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/features/practice/screens/spotify_panel.dart';
import 'package:hobby_tracker/l10n/app_strings.dart';
import 'package:hobby_tracker/services/spotify_session.dart';
import 'package:hobby_tracker/theme/hobby_theme.dart';
import 'package:hobby_tracker/viewmodels/spotify_controller.dart';
import 'spotify_test.dart'
    show TestOAuth, TestSpotifyApi, TestRemote, TestPlaylistStore, playlist;

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 412.0]) {
    for (final language in ['en', 'vi']) {
      testWidgets(
        'Spotify controls/picker/link at ${width}dp $language and 200% text',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 960);
          final remote = TestRemote();
          final preview = GlobalKey();
          final session = SpotifySession(
            owner: 'test-owner',
            oauth: TestOAuth(),
            api: TestSpotifyApi(),
            remote: remote,
            store: TestPlaylistStore(),
            isOwner: () => true,
          );
          final container = ProviderContainer(
            overrides: [spotifyMusicProvider.overrideWithValue(session)],
          );
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
            container.dispose();
            session.dispose();
            await remote.events.close();
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: HobbyTheme.forVariant(AppThemeVariant.light),
                locale: Locale(language),
                supportedLocales: AppStrings.supportedLocales,
                localizationsDelegates: const [
                  AppStrings.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: RepaintBoundary(
                  key: preview,
                  child: const Scaffold(
                    body: SingleChildScrollView(child: SpotifyPanel()),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(remote.connects, 0);
          await tester.ensureVisible(
            find.byKey(const ValueKey('spotify-connect')),
          );
          await tester.tap(find.byKey(const ValueKey('spotify-connect')));
          await tester.pumpAndSettle();
          expect(container.read(spotifyControllerProvider).linked, true);
          expect(remote.controls, isEmpty);
          if (const bool.fromEnvironment('SPOTIFY_SCREENSHOTS')) {
            await expectLater(
              find.byKey(preview),
              matchesGoldenFile(
                '../deployment-artifacts/spotify-ui/$language-${width.toInt()}-text200.png',
              ),
            );
          }
          await tester.ensureVisible(
            find.byKey(const ValueKey('spotify-playlists')),
          );
          await tester.tap(find.byKey(const ValueKey('spotify-playlists')));
          await tester.pumpAndSettle();
          expect(find.text(playlist.name), findsOneWidget);
          await tester.tap(find.text(playlist.name));
          await tester.pumpAndSettle();
          expect(remote.controls.single, contains(playlist.uri));
          await tester.ensureVisible(
            find.byKey(const ValueKey('spotify-paste')),
          );
          await tester.tap(find.byKey(const ValueKey('spotify-paste')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextField),
            'https://evil.example/playlist',
          );
          await tester.tap(
            find.widgetWithText(
              FilledButton,
              language == 'vi' ? 'Phát playlist' : 'Play playlist',
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(remote.controls.length, 1);
          await tester.enterText(
            find.byType(TextField),
            'https://open.spotify.com/playlist/${playlist.id}',
          );
          await tester.tap(
            find.widgetWithText(
              FilledButton,
              language == 'vi' ? 'Phát playlist' : 'Play playlist',
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(remote.controls.length, 2);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
