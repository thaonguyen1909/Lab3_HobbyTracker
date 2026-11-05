import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hobby_tracker/services/spotify_adapters.dart';
import 'package:hobby_tracker/models/spotify_music.dart';

class TestHttpClient extends Mock implements HttpClient {}

class TestHttpRequest extends Mock implements HttpClientRequest {}

class TestHttpHeaders extends Mock implements HttpHeaders {}

class TestHttpResponse extends Mock implements HttpClientResponse {
  TestHttpResponse(this.statusCode, this.body);
  @override
  final int statusCode;
  final Object body;
  @override
  Stream<List<int>> timeout(
    Duration timeLimit, {
    void Function(EventSink<List<int>>)? onTimeout,
  }) => Stream<List<int>>.value(
    utf8.encode(jsonEncode(body)),
  ).timeout(timeLimit, onTimeout: onTimeout);
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(utf8.encode(jsonEncode(body))).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

void main() {
  setUpAll(() => registerFallbackValue(Uri.https('api.spotify.com')));
  test(
    'playlist pagination keeps credentials on the fixed Spotify origin',
    () async {
      final client = TestHttpClient(),
          request = TestHttpRequest(),
          headers = TestHttpHeaders();
      final urls = <Uri>[];
      when(() => client.getUrl(any())).thenAnswer((call) async {
        urls.add(call.positionalArguments[0] as Uri);
        return request;
      });
      when(() => request.headers).thenReturn(headers);
      when(() => request.close()).thenAnswer(
        (_) async => TestHttpResponse(200, {
          'items': [
            {'id': '0123456789ABCDEFGHIJKL', 'name': 'Personal fixture'},
            null,
            {'id': 'bad', 'name': 'Invalid'},
          ],
          'next': 'https://untrusted.example/steal',
        }),
      );
      final api = HttpSpotifyWebApi(clientFactory: () => client);
      final first = await api.playlists('test-token', 0);
      final second = await api.playlists('test-token', first.nextOffset!);
      expect(first.items.length, 1);
      expect(second.items.length, 1);
      expect(urls.map((url) => url.host), everyElement('api.spotify.com'));
      expect(urls.last.queryParameters['offset'], '20');
      verify(() => request.followRedirects = false).called(2);
      verify(
        () => headers.set(HttpHeaders.authorizationHeader, 'Bearer test-token'),
      ).called(2);
    },
  );
  for (final status in [401, 403, 429, 500]) {
    test('HTTP $status maps to a safe error without response body', () async {
      final client = TestHttpClient(),
          request = TestHttpRequest(),
          headers = TestHttpHeaders();
      when(() => client.getUrl(any())).thenAnswer((_) async => request);
      when(() => request.headers).thenReturn(headers);
      when(() => request.close()).thenAnswer(
        (_) async => TestHttpResponse(status, {'error': 'SENSITIVE TEST BODY'}),
      );
      await expectLater(
        HttpSpotifyWebApi(
          clientFactory: () => client,
        ).playlists('test-token', 0),
        throwsA(
          isA<SpotifyFailure>().having(
            (error) => error.message,
            'safe message',
            isNot(contains('SENSITIVE')),
          ),
        ),
      );
    });
  }
}
