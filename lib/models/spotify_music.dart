class SpotifyFailure implements Exception {
  const SpotifyFailure(this.code, this.message);
  final String code, message;
  @override
  String toString() => message;
}

class SpotifyConfig {
  static const clientId = String.fromEnvironment(
    'SPOTIFY_CLIENT_ID',
    defaultValue: '914fd3f140f04cdeb3271698c4d1cb93',
  );
  static const redirectUri = 'vn.prm393.hobbytracker://spotify-callback';
  static const scopes = [
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-read-private',
    'app-remote-control',
  ];
}

String spotifyPlaylistId(String value) {
  final text = value.trim();
  final direct = RegExp(
    r'^spotify:playlist:([A-Za-z0-9]{22})$',
  ).firstMatch(text);
  if (direct != null) return direct.group(1)!;
  final uri = Uri.tryParse(
    text.startsWith('open.spotify.com/') ? 'https://$text' : text,
  );
  if (uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'open.spotify.com' &&
      uri.userInfo.isEmpty &&
      (!uri.hasPort || uri.port == 443)) {
    final parts = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty && parts.first.startsWith('intl-')) parts.removeAt(0);
    if (parts.length == 2 &&
        parts[0] == 'playlist' &&
        RegExp(r'^[A-Za-z0-9]{22}$').hasMatch(parts[1])) {
      return parts[1];
    }
  }
  throw const SpotifyFailure(
    'invalid-playlist',
    'Paste a full Spotify playlist link or playlist URI.',
  );
}

class SpotifyPlaylist {
  const SpotifyPlaylist({required this.id, required this.name, this.imageUrl});
  final String id, name;
  final String? imageUrl;
  String get uri => 'spotify:playlist:$id';
  factory SpotifyPlaylist.fromLink(String value) =>
      SpotifyPlaylist(id: spotifyPlaylistId(value), name: 'Playlist from link');
}

class SpotifyPlaylistPage {
  const SpotifyPlaylistPage(this.items, {required this.nextOffset});
  final List<SpotifyPlaylist> items;
  final int? nextOffset;
}

class SpotifyProfile {
  const SpotifyProfile(this.id, this.name);
  final String id, name;
}

class SpotifyConnection {
  const SpotifyConnection(this.profile, this.lastPlaylist);
  final SpotifyProfile profile;
  final SpotifyPlaylist? lastPlaylist;
}

class SpotifyPlayback {
  const SpotifyPlayback({
    this.connected = false,
    this.paused = true,
    this.track = '',
    this.artist = '',
    this.positionMs = 0,
    this.durationMs = 0,
  });
  final bool connected, paused;
  final String track, artist;
  final int positionMs, durationMs;
}

class SpotifyTokens {
  const SpotifyTokens(this.accessToken, this.refreshToken, this.expiresAt);
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  // Deliberately no toJson/toString: tokens stay only in the owner-scoped session.
}
