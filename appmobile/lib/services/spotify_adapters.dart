import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../models/spotify_music.dart';
import 'local_owner_store.dart';
import 'spotify_music.dart';

const _endpoints = AuthorizationServiceConfiguration(
  authorizationEndpoint: 'https://accounts.spotify.com/authorize',
  tokenEndpoint: 'https://accounts.spotify.com/api/token',
);

class AppAuthSpotifyOAuth implements SpotifyOAuth {
  final FlutterAppAuth _auth = const FlutterAppAuth();
  @override
  Future<SpotifyTokens> authorize() async {
    try {
      final result = await _auth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          SpotifyConfig.clientId,
          SpotifyConfig.redirectUri,
          serviceConfiguration: _endpoints,
          scopes: SpotifyConfig.scopes,
          additionalParameters: {'show_dialog': 'true'},
        ),
      );
      return _tokens(
        result.accessToken,
        result.refreshToken,
        result.accessTokenExpirationDateTime,
      );
    } on FlutterAppAuthUserCancelledException {
      throw const SpotifyFailure(
        'cancelled',
        'Spotify connection was cancelled.',
      );
    } on PlatformException {
      throw const SpotifyFailure(
        'authorization',
        'Spotify authorization failed. Check the redirect URI and allowed users.',
      );
    }
  }

  SpotifyTokens _tokens(String? access, String? refresh, DateTime? expiry) {
    if (access == null || access.isEmpty || expiry == null) {
      throw const SpotifyFailure(
        'authorization',
        'Spotify authorization failed. Check the redirect URI and allowed users.',
      );
    }
    return SpotifyTokens(access, refresh, expiry);
  }

  @override
  Future<SpotifyTokens> refresh(String refreshToken) async {
    try {
      final result = await _auth.token(
        TokenRequest(
          SpotifyConfig.clientId,
          SpotifyConfig.redirectUri,
          refreshToken: refreshToken,
          serviceConfiguration: _endpoints,
        ),
      );
      return _tokens(
        result.accessToken,
        result.refreshToken,
        result.accessTokenExpirationDateTime,
      );
    } on PlatformException {
      throw const SpotifyFailure(
        'expired',
        'Spotify session expired. Connect again.',
      );
    }
  }
}

class HttpSpotifyWebApi implements SpotifyWebApi {
  HttpSpotifyWebApi({HttpClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? HttpClient.new;
  final HttpClient Function() _clientFactory;
  Future<Map<String, dynamic>> _get(
    String token,
    String path, [
    Map<String, String>? query,
  ]) async {
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client
          .getUrl(Uri.https('api.spotify.com', path, query))
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      switch (response.statusCode) {
        case 401:
          throw const SpotifyFailure(
            'unauthenticated',
            'Spotify session expired. Connect again.',
          );
        case 403:
          throw const SpotifyFailure(
            'forbidden',
            'Spotify denied access. Check playlist permissions and the app user allowlist.',
          );
        case 429:
          throw const SpotifyFailure(
            'rate-limit',
            'Spotify is busy. Wait a moment and try again.',
          );
      }
      if (response.statusCode != 200) {
        throw const SpotifyFailure(
          'unavailable',
          'Could not load Spotify playlists. Try again.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        bytes.addAll(chunk);
        if (bytes.length > 2097152) {
          throw const FormatException('Response too large');
        }
      }
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } on SpotifyFailure {
      rethrow;
    } catch (_) {
      throw const SpotifyFailure(
        'network',
        'Could not load Spotify playlists. Check your connection and retry.',
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<SpotifyProfile> profile(String accessToken) async {
    final json = await _get(accessToken, '/v1/me');
    final id = json['id'];
    if (id is! String || id.isEmpty || id.length > 256) {
      throw const SpotifyFailure(
        'profile',
        'Could not read your Spotify account. Connect again.',
      );
    }
    return SpotifyProfile(
      id,
      json['display_name'] is String ? json['display_name'] as String : id,
    );
  }

  @override
  Future<SpotifyPlaylistPage> playlists(String accessToken, int offset) async {
    if (offset < 0 || offset > 100000) {
      throw const SpotifyFailure(
        'page',
        'Could not load Spotify playlists. Try again.',
      );
    }
    final json = await _get(accessToken, '/v1/me/playlists', {
      'limit': '20',
      'offset': '$offset',
    });
    final items = <SpotifyPlaylist>[];
    final raw = json['items'];
    if (raw is! List) {
      throw const SpotifyFailure(
        'response',
        'Could not load Spotify playlists. Try again.',
      );
    }
    for (final item in raw) {
      if (item is! Map || item['id'] is! String || item['name'] is! String) {
        continue;
      }
      final id = item['id'] as String;
      if (!RegExp(r'^[A-Za-z0-9]{22}$').hasMatch(id)) continue;
      items.add(SpotifyPlaylist(id: id, name: item['name'] as String));
    }
    // Never follow a response-provided URL with the bearer token.
    return SpotifyPlaylistPage(
      items,
      nextOffset: json['next'] != null && raw.isNotEmpty ? offset + 20 : null,
    );
  }
}

class PlatformSpotifyRemote implements SpotifyRemote {
  static const _methods = MethodChannel('hobbytracker/spotify');
  static const _events = EventChannel('hobbytracker/spotify/events');
  Stream<dynamic>? _stream;
  @override
  bool get supported => !kIsWeb && Platform.isAndroid;
  @override
  Future<bool> installed() async =>
      supported && (await _methods.invokeMethod<bool>('installed') ?? false);
  @override
  Stream<SpotifyPlayback> states(String owner) {
    if (!supported) return const Stream.empty();
    _stream ??= _events.receiveBroadcastStream();
    return _stream!
        .where((event) => event is Map && event['owner'] == owner)
        .map((event) {
          final data = event as Map;
          return SpotifyPlayback(
            connected: data['connected'] == true,
            paused: data['paused'] != false,
            track: data['track'] as String? ?? '',
            artist: data['artist'] as String? ?? '',
            positionMs: (data['positionMs'] as num?)?.toInt() ?? 0,
            durationMs: (data['durationMs'] as num?)?.toInt() ?? 0,
          );
        });
  }

  Future<void> _call(
    String owner,
    String method, [
    Map<String, Object?> extra = const {},
  ]) async {
    try {
      await _methods
          .invokeMethod<void>(method, {'owner': owner, ...extra})
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      if (method == 'connect') {
        unawaited(disconnect(owner).catchError((Object _) {}));
      }
      throw const SpotifyFailure(
        'timeout',
        'Spotify took too long. Return to the app and reconnect.',
      );
    } on PlatformException catch (error) {
      final message = switch (error.code) {
        'cancelled' => 'Spotify connection was cancelled.',
        'not-installed' => 'Install Spotify and sign in, then try again.',
        'not-connected' => 'Reconnect Spotify to use playback controls.',
        'not-authorized' =>
          'Allow Hobby Tracker to control Spotify, then reconnect.',
        'background' => 'Return to the app and reconnect Spotify.',
        'control-failed' =>
          'Spotify could not play this item. Check your Premium account and playlist access.',
        _ =>
          'Could not connect to Spotify. Check the Android package, SHA-1 and redirect URI.',
      };
      throw SpotifyFailure(error.code, message);
    } on MissingPluginException {
      throw const SpotifyFailure(
        'unsupported',
        'Rebuild the Android app to enable Spotify.',
      );
    }
  }

  @override
  Future<void> connect(String owner, {bool silent = false}) =>
      _call(owner, 'connect', {
        'clientId': SpotifyConfig.clientId,
        'redirectUri': SpotifyConfig.redirectUri,
        'silent': silent,
      });
  @override
  Future<void> command(String owner, String command, {String? uri}) =>
      _call(owner, command, {'uri': uri});
  @override
  Future<void> disconnect(String owner) =>
      supported ? _call(owner, 'disconnect') : Future.value();
}

class LocalSpotifyPlaylistStore implements SpotifyPlaylistStore {
  LocalSpotifyPlaylistStore(this.local);
  final LocalOwnerStore local;
  String _key(String owner, String spotifyUser) =>
      '${local.prefix(owner)}spotify_${base64Url.encode(utf8.encode(spotifyUser))}';
  @override
  Future<SpotifyPlaylist?> read(String owner, String spotifyUser) async {
    if (await local.prefs.getString('active_owner') != owner) return null;
    final text = await local.prefs.getString(_key(owner, spotifyUser));
    if (text == null || await local.prefs.getString('active_owner') != owner) {
      return null;
    }
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final id = spotifyPlaylistId(json['uri'] as String);
      return SpotifyPlaylist(id: id, name: json['name'] as String);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
    String owner,
    String spotifyUser,
    SpotifyPlaylist playlist,
  ) async {
    final key = _key(owner, spotifyUser);
    if (await local.prefs.getString('active_owner') != owner) return;
    await local.prefs.setString(
      key,
      jsonEncode({'uri': playlist.uri, 'name': playlist.name}),
    );
    if (await local.prefs.getString('active_owner') != owner) {
      await local.prefs.remove(key);
    }
  }
}
