import 'dart:async';
import '../models/spotify_music.dart';
import 'spotify_music.dart';

class SpotifySession implements SpotifyMusic {
  SpotifySession({
    required this.owner,
    required this.oauth,
    required this.api,
    required this.remote,
    required this.store,
    required this.isOwner,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final String owner;
  final SpotifyOAuth oauth;
  final SpotifyWebApi api;
  final SpotifyRemote remote;
  final SpotifyPlaylistStore store;
  final bool Function() isOwner;
  final DateTime Function() now;
  SpotifyTokens? _tokens;
  SpotifyProfile? _profile;
  Future<void>? _refreshing;
  bool _disposed = false;
  int _generation = 0;
  void check([int? generation]) {
    if (_disposed ||
        !isOwner() ||
        (generation != null && generation != _generation)) {
      throw const SpotifyFailure(
        'cancelled',
        'Your account changed. Connect Spotify again.',
      );
    }
  }

  @override
  bool get supported => remote.supported;
  @override
  Stream<SpotifyPlayback> get states =>
      remote.states(owner).where((_) => !_disposed && isOwner());
  @override
  Future<SpotifyConnection> connect() async {
    check();
    final generation = _generation;
    if (!supported) {
      throw const SpotifyFailure(
        'unsupported',
        'Spotify playback is available on Android.',
      );
    }
    if (!await remote.installed()) {
      throw const SpotifyFailure(
        'not-installed',
        'Install Spotify and sign in, then try again.',
      );
    }
    check(generation);
    if (_tokens == null || _profile == null) {
      final tokens = await oauth.authorize();
      check(generation);
      _tokens = tokens;
      try {
        final profile = await authenticated(api.profile);
        check(generation);
        _profile = profile;
      } on SpotifyFailure {
        if (!_disposed && generation == _generation) {
          _tokens = null;
        }
        rethrow;
      }
    }
    check(generation);
    await remote.connect(owner);
    check(generation);
    final profile = _profile!;
    SpotifyPlaylist? saved;
    try {
      saved = await store.read(owner, profile.id);
    } catch (_) {
      /* Nonessential preference. */
    }
    check(generation);
    return SpotifyConnection(profile, saved);
  }

  Future<void> refresh({bool force = false}) async {
    check();
    final tokens = _tokens;
    if (tokens == null) {
      throw const SpotifyFailure('not-connected', 'Connect Spotify first.');
    }
    if (!force &&
        tokens.expiresAt.isAfter(now().add(const Duration(seconds: 30)))) {
      return;
    }
    if (tokens.refreshToken == null) {
      _tokens = null;
      throw const SpotifyFailure(
        'expired',
        'Spotify session expired. Connect again.',
      );
    }
    final existing = _refreshing;
    if (existing != null) return existing;
    final generation = _generation;
    Future<void> perform() async {
      try {
        final updated = await oauth.refresh(tokens.refreshToken!);
        check(generation);
        _tokens = SpotifyTokens(
          updated.accessToken,
          updated.refreshToken ?? tokens.refreshToken,
          updated.expiresAt,
        );
      } on SpotifyFailure {
        if (!_disposed && generation == _generation) _tokens = null;
        rethrow;
      }
    }

    final pending = perform();
    _refreshing = pending;
    try {
      await pending;
    } finally {
      if (identical(_refreshing, pending)) _refreshing = null;
    }
  }

  Future<T> authenticated<T>(Future<T> Function(String) request) async {
    check();
    final generation = _generation;
    await refresh();
    check(generation);
    try {
      final value = await request(_tokens!.accessToken);
      check(generation);
      return value;
    } on SpotifyFailure catch (error) {
      if (error.code != 'unauthenticated') rethrow;
      await refresh(force: true);
      check(generation);
      final value = await request(_tokens!.accessToken);
      check(generation);
      return value;
    }
  }

  @override
  Future<void> resumeConnection() async {
    check();
    if (_tokens == null || _profile == null) return;
    final generation = _generation;
    await remote.connect(owner, silent: true);
    check(generation);
  }

  @override
  Future<SpotifyPlaylistPage> playlists(int offset) =>
      authenticated((token) => api.playlists(token, offset));
  @override
  Future<void> play(SpotifyPlaylist playlist) async {
    check();
    final generation = _generation;
    spotifyPlaylistId(playlist.uri);
    if (_profile == null) {
      throw const SpotifyFailure('not-connected', 'Connect Spotify first.');
    }
    await remote.command(owner, 'play', uri: playlist.uri);
    check(generation);
    try {
      await store.write(owner, _profile!.id, playlist);
    } catch (_) {
      /* Playback succeeded; optional preference can fail. */
    }
    check(generation);
  }

  @override
  Future<void> command(String command) async {
    check();
    final generation = _generation;
    if (!['pause', 'resume', 'next', 'previous'].contains(command)) {
      throw const SpotifyFailure(
        'invalid-command',
        'Unsupported playback control.',
      );
    }
    await remote.command(owner, command);
    check(generation);
  }

  @override
  Future<void> disconnect() async {
    _generation++;
    _tokens = null;
    _profile = null;
    _refreshing = null;
    await remote.disconnect(owner);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _tokens = null;
    _profile = null;
    unawaited(remote.disconnect(owner).catchError((Object _) {}));
  }
}
