import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/models/spotify_music.dart';
import 'package:hobby_tracker/services/spotify_music.dart';
import 'package:hobby_tracker/services/spotify_session.dart';
import 'package:hobby_tracker/viewmodels/spotify_controller.dart';
import 'package:hobby_tracker/services/spotify_adapters.dart';
import 'package:hobby_tracker/services/local_owner_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

const playlist = SpotifyPlaylist(
  id: '0123456789ABCDEFGHIJKL',
  name: 'Focus fixture',
);
final future = DateTime(2040);

class TestOAuth implements SpotifyOAuth {
  int authorizations = 0, refreshes = 0;
  SpotifyTokens tokens = SpotifyTokens('test-access', 'test-refresh', future);
  Future<SpotifyTokens> Function()? onAuthorize;
  Completer<SpotifyTokens>? pendingRefresh;
  final refreshedWith = <String>[];
  @override
  Future<SpotifyTokens> authorize() async {
    authorizations++;
    return onAuthorize == null ? tokens : onAuthorize!();
  }

  @override
  Future<SpotifyTokens> refresh(String refreshToken) async {
    refreshes++;
    refreshedWith.add(refreshToken);
    return pendingRefresh?.future ?? SpotifyTokens('refreshed', null, future);
  }
}

class TestSpotifyApi implements SpotifyWebApi {
  int unauthorized = 0, requests = 0;
  final usedTokens = <String>[];
  @override
  Future<SpotifyProfile> profile(String token) async =>
      const SpotifyProfile('spotify-a', 'Spotify fixture');
  @override
  Future<SpotifyPlaylistPage> playlists(String token, int offset) async {
    requests++;
    usedTokens.add(token);
    if (unauthorized-- > 0) {
      throw const SpotifyFailure('unauthenticated', 'Expired');
    }
    return const SpotifyPlaylistPage([playlist], nextOffset: null);
  }
}

class TestRemote implements SpotifyRemote {
  @override
  bool supported = true;
  bool hasApp = true;
  int connects = 0, disconnects = 0;
  final controls = <String>[];
  final events = StreamController<SpotifyPlayback>.broadcast();
  @override
  Future<bool> installed() async => hasApp;
  @override
  Stream<SpotifyPlayback> states(String owner) => events.stream;
  @override
  Future<void> connect(String owner, {bool silent = false}) async {
    connects++;
  }

  @override
  Future<void> command(String owner, String command, {String? uri}) async {
    controls.add('$owner:$command:${uri ?? ''}');
  }

  @override
  Future<void> disconnect(String owner) async {
    disconnects++;
  }
}

class TestPlaylistStore implements SpotifyPlaylistStore {
  final values = <String, SpotifyPlaylist>{};
  bool fail = false;
  @override
  Future<SpotifyPlaylist?> read(String owner, String spotifyUser) async =>
      values['$owner/$spotifyUser'];
  @override
  Future<void> write(
    String owner,
    String spotifyUser,
    SpotifyPlaylist value,
  ) async {
    if (fail) throw StateError('Storage unavailable');
    values['$owner/$spotifyUser'] = value;
  }
}

class MemorySpotifyPreferences extends Mock implements SharedPreferencesAsync {}

void main() {
  group('Playlist input validation', () {
    for (final input in [
      playlist.uri,
      'https://open.spotify.com/playlist/${playlist.id}?si=abc',
      'open.spotify.com/playlist/${playlist.id}',
      'https://open.spotify.com/intl-vi/playlist/${playlist.id}',
    ]) {
      test(
        'accepts $input',
        () => expect(spotifyPlaylistId(input), playlist.id),
      );
    }
    for (final input in [
      'https://evil.example/playlist/${playlist.id}',
      'https://open.spotify.com@evil.example/playlist/${playlist.id}',
      'http://open.spotify.com/playlist/${playlist.id}',
      'https://open.spotify.com:8080/playlist/${playlist.id}',
      'https://open.spotify.com/track/${playlist.id}',
      'https://spotify.link/short',
      'spotify:playlist:bad',
    ]) {
      test(
        'rejects $input',
        () => expect(
          () => spotifyPlaylistId(input),
          throwsA(isA<SpotifyFailure>()),
        ),
      );
    }
  });
  group('Owner-scoped Spotify session', () {
    late TestOAuth oauth;
    late TestSpotifyApi api;
    late TestRemote remote;
    late TestPlaylistStore store;
    late SpotifySession session;
    var ownerActive = true;
    setUp(() {
      oauth = TestOAuth();
      api = TestSpotifyApi();
      remote = TestRemote();
      store = TestPlaylistStore();
      ownerActive = true;
      session = SpotifySession(
        owner: 'owner-a',
        oauth: oauth,
        api: api,
        remote: remote,
        store: store,
        isOwner: () => ownerActive,
      );
    });
    tearDown(() async {
      session.dispose();
      await remote.events.close();
    });
    test(
      'requires installed app before authorization, does not autoplay',
      () async {
        remote.hasApp = false;
        await expectLater(session.connect(), throwsA(isA<SpotifyFailure>()));
        expect(oauth.authorizations, 0);
        remote.hasApp = true;
        await session.connect();
        expect(remote.controls, isEmpty);
      },
    );
    test('cancelled OAuth can be retried', () async {
      oauth.onAuthorize = () async =>
          throw const SpotifyFailure('cancelled', 'Cancelled');
      await expectLater(session.connect(), throwsA(isA<SpotifyFailure>()));
      oauth.onAuthorize = null;
      await session.connect();
      expect(oauth.authorizations, 2);
    });
    test(
      'late OAuth result after owner change cannot connect or save',
      () async {
        final pending = Completer<SpotifyTokens>();
        oauth.onAuthorize = () => pending.future;
        final connection = session.connect();
        final expectation = expectLater(
          connection,
          throwsA(isA<SpotifyFailure>()),
        );
        await Future<void>.delayed(Duration.zero);
        ownerActive = false;
        pending.complete(oauth.tokens);
        await expectation;
        expect(remote.connects, 0);
        expect(store.values, isEmpty);
      },
    );
    test(
      'refreshes expired access and preserves omitted refresh token',
      () async {
        await session.connect();
        api.unauthorized = 1;
        await session.playlists(0);
        api.unauthorized = 1;
        await session.playlists(0);
        expect(oauth.refreshedWith, ['test-refresh', 'test-refresh']);
        expect(api.usedTokens.last, 'refreshed');
      },
    );
    test('401 retries once, never loops', () async {
      await session.connect();
      api.unauthorized = 3;
      await expectLater(session.playlists(0), throwsA(isA<SpotifyFailure>()));
      expect(api.requests, 2);
      expect(oauth.refreshes, 1);
    });
    test('concurrent expired requests share one refresh', () async {
      var now = DateTime(2030);
      session.dispose();
      session = SpotifySession(
        owner: 'owner-a',
        oauth: oauth,
        api: api,
        remote: remote,
        store: store,
        isOwner: () => true,
        now: () => now,
      );
      await session.connect();
      now = DateTime(2041);
      oauth.pendingRefresh = Completer<SpotifyTokens>();
      final one = session.playlists(0), two = session.playlists(20);
      await Future<void>.delayed(Duration.zero);
      expect(oauth.refreshes, 1);
      oauth.pendingRefresh!.complete(
        SpotifyTokens('new-access', 'rotated-refresh', DateTime(2050)),
      );
      await Future.wait([one, two]);
      now = DateTime(2051);
      oauth.pendingRefresh = null;
      await session.playlists(0);
      expect(oauth.refreshedWith.last, 'rotated-refresh');
    });
    test(
      'disconnect invalidates pending refresh and clears credentials',
      () async {
        await session.connect();
        api.unauthorized = 1;
        oauth.pendingRefresh = Completer<SpotifyTokens>();
        final call = session.playlists(0);
        final expectation = expectLater(call, throwsA(isA<SpotifyFailure>()));
        await Future<void>.delayed(Duration.zero);
        await session.disconnect();
        oauth.pendingRefresh!.complete(
          SpotifyTokens('late-access', null, future),
        );
        await expectation;
        await expectLater(session.playlists(0), throwsA(isA<SpotifyFailure>()));
        await session.connect();
        expect(oauth.authorizations, 2);
      },
    );
    test(
      'saves last choice under Firebase owner and Spotify id only after play',
      () async {
        await session.connect();
        await session.play(playlist);
        expect(store.values['owner-a/spotify-a']?.id, playlist.id);
        expect(store.values['owner-b/spotify-a'], isNull);
        expect(store.values['owner-a/spotify-b'], isNull);
        store.fail = true;
        await session.play(
          playlist,
        ); // Playback must not report failure for an optional preference.
        await expectLater(
          session.command('delete'),
          throwsA(isA<SpotifyFailure>()),
        );
      },
    );
  });
  test(
    'local preference excludes credentials and checks active owner',
    () async {
      final prefs = MemorySpotifyPreferences(),
          values = <String, String>{'active_owner': 'owner-a'};
      when(
        () => prefs.getString(any()),
      ).thenAnswer((call) async => values[call.positionalArguments[0]]);
      when(() => prefs.setString(any(), any())).thenAnswer((call) async {
        values[call.positionalArguments[0] as String] =
            call.positionalArguments[1] as String;
      });
      final local = LocalSpotifyPlaylistStore(
        LocalOwnerStore(preferences: prefs),
      );
      await local.write('owner-a', 'spotify-a', playlist);
      expect((await local.read('owner-a', 'spotify-a'))?.id, playlist.id);
      expect(await local.read('owner-a', 'spotify-b'), isNull);
      values['active_owner'] = 'owner-b';
      expect(await local.read('owner-a', 'spotify-a'), isNull);
      await local.write('owner-b', 'spotify-a', playlist);
      expect(values.length, 3);
      expect(values.values.join(), isNot(contains('test-access')));
    },
  );
  test(
    'controller recovers empty/error pages without losing connection',
    () async {
      final remote = TestRemote(), api = TestSpotifyApi();
      final session = SpotifySession(
        owner: 'owner-a',
        oauth: TestOAuth(),
        api: api,
        remote: remote,
        store: TestPlaylistStore(),
        isOwner: () => true,
      );
      final vm = SpotifyController(session);
      await vm.connect();
      expect(vm.state.linked, true);
      expect(vm.state.items.single.id, playlist.id);
      await vm.playLink('https://evil.example');
      expect(vm.state.error, isNotNull);
      expect(remote.controls, isEmpty);
      await vm.playLink(playlist.uri);
      expect(vm.state.error, isNull);
      expect(vm.state.selected?.id, playlist.id);
      remote.events.add(
        const SpotifyPlayback(
          connected: true,
          paused: false,
          track: 'Test track',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.playback.paused, false);
      await vm.disconnect();
      expect(vm.state.items, isEmpty);
      expect(vm.state.profile, isNull);
      vm.dispose();
      session.dispose();
      await remote.events.close();
    },
  );
}
