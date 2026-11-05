import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spotify_music.dart';
import '../services/local_owner_store.dart';
import '../services/spotify_adapters.dart';
import '../services/spotify_music.dart';
import '../services/spotify_session.dart';
import 'data_providers.dart';

final spotifyRemoteProvider = Provider<SpotifyRemote>(
  (ref) => PlatformSpotifyRemote(),
);
final spotifyMusicProvider = Provider.autoDispose<SpotifyMusic?>((ref) {
  final owner = ref.watch(ownerIdProvider);
  if (owner == null) return null;
  final remote = ref.watch(spotifyRemoteProvider);
  if (!remote.supported) return null;
  final session = SpotifySession(
    owner: owner,
    oauth: AppAuthSpotifyOAuth(),
    api: HttpSpotifyWebApi(),
    remote: remote,
    store: LocalSpotifyPlaylistStore(LocalOwnerStore()),
    isOwner: () => ref.read(ownerIdProvider) == owner,
  );
  ref.onDispose(session.dispose);
  return session;
});
final spotifyControllerProvider =
    StateNotifierProvider.autoDispose<SpotifyController, SpotifyUiState>(
      (ref) => SpotifyController(ref.watch(spotifyMusicProvider)),
    );

class SpotifyUiState {
  const SpotifyUiState({
    this.supported = false,
    this.linked = false,
    this.busy = false,
    this.loading = false,
    this.playback = const SpotifyPlayback(),
    this.profile,
    this.items = const [],
    this.nextOffset,
    this.selected,
    this.error,
  });
  final bool supported, linked, busy, loading;
  final SpotifyPlayback playback;
  final SpotifyProfile? profile;
  final List<SpotifyPlaylist> items;
  final int? nextOffset;
  final SpotifyPlaylist? selected;
  final String? error;
  SpotifyUiState copy({
    bool? linked,
    bool? busy,
    bool? loading,
    SpotifyPlayback? playback,
    SpotifyProfile? profile,
    List<SpotifyPlaylist>? items,
    int? nextOffset,
    bool replacePage = false,
    SpotifyPlaylist? selected,
    String? error,
  }) => SpotifyUiState(
    supported: supported,
    linked: linked ?? this.linked,
    busy: busy ?? this.busy,
    loading: loading ?? this.loading,
    playback: playback ?? this.playback,
    profile: profile ?? this.profile,
    items: items ?? this.items,
    nextOffset: replacePage ? nextOffset : this.nextOffset,
    selected: selected ?? this.selected,
    error: error,
  );
}

class SpotifyController extends StateNotifier<SpotifyUiState> {
  SpotifyController(this.music)
    : super(SpotifyUiState(supported: music?.supported == true)) {
    _subscription = music?.states.listen(
      (playback) {
        if (mounted) state = state.copy(playback: playback, error: state.error);
      },
      onError: (Object _) {
        if (mounted) {
          state = state.copy(
            playback: const SpotifyPlayback(),
            error: 'Reconnect Spotify to use playback controls.',
          );
        }
      },
    );
  }
  final SpotifyMusic? music;
  StreamSubscription<SpotifyPlayback>? _subscription;
  int _generation = 0;
  bool _current(int generation) => mounted && generation == _generation;
  String _message(Object error) => error is SpotifyFailure
      ? error.message
      : 'Could not connect to Spotify. Try again.';
  Future<void> connect() async {
    if (music == null || state.busy) return;
    final generation = _generation;
    state = state.copy(busy: true);
    try {
      final connection = await music!.connect();
      if (!_current(generation)) return;
      state = state.copy(
        linked: true,
        busy: false,
        profile: connection.profile,
        selected: connection.lastPlaylist,
        playback: const SpotifyPlayback(connected: true),
      );
      await loadPlaylists();
    } catch (error) {
      if (_current(generation)) {
        state = state.copy(busy: false, error: _message(error));
      }
    }
  }

  Future<void> loadPlaylists({bool more = false}) async {
    if (music == null ||
        !state.linked ||
        state.loading ||
        (more && state.nextOffset == null)) {
      return;
    }
    final generation = _generation;
    final offset = more ? state.nextOffset! : 0;
    state = state.copy(loading: true);
    try {
      final page = await music!.playlists(offset);
      if (!_current(generation)) return;
      final items = <String, SpotifyPlaylist>{
        for (final item in more ? state.items : <SpotifyPlaylist>[])
          item.id: item,
      };
      for (final item in page.items) {
        items[item.id] = item;
      }
      state = state.copy(
        loading: false,
        items: items.values.toList(),
        replacePage: true,
        nextOffset: page.nextOffset,
      );
    } catch (error) {
      if (_current(generation)) {
        state = state.copy(loading: false, error: _message(error));
      }
    }
  }

  Future<void> play(SpotifyPlaylist playlist) async {
    if (music == null || !state.linked || state.busy) return;
    final generation = _generation;
    state = state.copy(busy: true);
    try {
      if (!state.playback.connected) await music!.resumeConnection();
      await music!.play(playlist);
      if (_current(generation)) {
        state = state.copy(busy: false, selected: playlist);
      }
    } catch (error) {
      if (_current(generation)) {
        state = state.copy(busy: false, error: _message(error));
      }
    }
  }

  Future<void> playLink(String link) async {
    try {
      await play(SpotifyPlaylist.fromLink(link));
    } catch (error) {
      if (mounted) state = state.copy(error: _message(error));
    }
  }

  Future<void> command(String command) async {
    if (music == null || !state.linked || state.busy) return;
    final generation = _generation;
    state = state.copy(busy: true);
    try {
      if (!state.playback.connected) await music!.resumeConnection();
      await music!.command(command);
      if (_current(generation)) state = state.copy(busy: false);
    } catch (error) {
      if (_current(generation)) {
        state = state.copy(busy: false, error: _message(error));
      }
    }
  }

  Future<void> resumeConnection() async {
    if (music == null || !state.linked || state.busy) return;
    final generation = _generation;
    try {
      await music!.resumeConnection();
    } catch (_) {
      if (_current(generation)) {
        state = state.copy(
          playback: const SpotifyPlayback(),
          error: 'Reconnect Spotify to use playback controls.',
        );
      }
    }
  }

  Future<void> disconnect() async {
    if (music == null) return;
    _generation++;
    state = SpotifyUiState(supported: state.supported, busy: true);
    try {
      await music!.disconnect();
    } catch (_) {
      /* Local credentials are already cleared. */
    }
    if (mounted) state = SpotifyUiState(supported: state.supported);
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
