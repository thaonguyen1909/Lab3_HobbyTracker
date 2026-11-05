import '../models/spotify_music.dart';

abstract class SpotifyOAuth {
  Future<SpotifyTokens> authorize();
  Future<SpotifyTokens> refresh(String refreshToken);
}

abstract class SpotifyWebApi {
  Future<SpotifyProfile> profile(String accessToken);
  Future<SpotifyPlaylistPage> playlists(String accessToken, int offset);
}

abstract class SpotifyRemote {
  bool get supported;
  Future<bool> installed();
  Stream<SpotifyPlayback> states(String owner);
  Future<void> connect(String owner, {bool silent = false});
  Future<void> command(String owner, String command, {String? uri});
  Future<void> disconnect(String owner);
}

abstract class SpotifyPlaylistStore {
  Future<SpotifyPlaylist?> read(String owner, String spotifyUser);
  Future<void> write(
    String owner,
    String spotifyUser,
    SpotifyPlaylist playlist,
  );
}

abstract class SpotifyMusic {
  bool get supported;
  Stream<SpotifyPlayback> get states;
  Future<SpotifyConnection> connect();
  Future<void> resumeConnection();
  Future<SpotifyPlaylistPage> playlists(int offset);
  Future<void> play(SpotifyPlaylist playlist);
  Future<void> command(String command);
  Future<void> disconnect();
  void dispose();
}
