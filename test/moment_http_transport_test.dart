import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_tracker/firebase/moment_http_transport.dart';
import 'package:hobby_tracker/models/group_moment.dart';
import 'package:hobby_tracker/services/moment_repository.dart';

void main() {
  test(
    'API URL requires HTTPS outside debug and rejects credentials/query',
    () {
      for (final value in [
        '',
        'http://example.com',
        'https://user:pass@example.com',
        'https://example.com?secret=x',
      ]) {
        expect(
          () => MomentHttpTransport.validateUrl(value, debug: false),
          throwsA(isA<MomentFailure>()),
        );
      }
      expect(
        MomentHttpTransport.validateUrl(
          'https://api.example.com',
          debug: false,
        ).host,
        'api.example.com',
      );
      expect(
        MomentHttpTransport.validateUrl(
          'http://127.0.0.1:8787',
          debug: true,
        ).port,
        8787,
      );
      expect(
        () => MomentHttpTransport.validateUrl(
          'http://127.0.0.1:8787',
          debug: false,
        ),
        throwsA(isA<MomentFailure>()),
      );
    },
  );
  late HttpServer server;
  late MomentHttpTransport transport;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    transport = MomentHttpTransport(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: () async => 'test-token',
      isOwner: () => true,
    );
  });
  tearDown(() async => server.close(force: true));
  test('request sends ID token and receives data envelope', () async {
    server.listen((request) async {
      expect(request.headers.value('authorization'), 'Bearer test-token');
      expect(request.uri.path, '/v1/listGroupMoments');
      expect(jsonDecode(await utf8.decoder.bind(request).join()), {
        'groupId': 'g',
      });
      request.response.write(
        jsonEncode({
          'data': {'items': []},
        }),
      );
      await request.response.close();
    });
    expect(await transport.call('listGroupMoments', {'groupId': 'g'}), {
      'items': [],
    });
  });
  test(
    'binary upload uses API rather than direct Firebase/Cloudinary URL',
    () async {
      server.listen((request) async {
        expect(request.uri.path, '/v1/stage');
        expect(request.uri.queryParameters['momentId'], 'm');
        expect(
          await request.fold<List<int>>(
            [],
            (bytes, chunk) => bytes..addAll(chunk),
          ),
          [1, 2, 3],
        );
        request.response.write(
          jsonEncode({
            'data': {'uploaded': true},
          }),
        );
        await request.response.close();
      });
      var progress = 0.0;
      await transport.upload(
        'm',
        Uint8List.fromList([1, 2, 3]),
        cancellation: MomentUploadCancellation(),
        progress: (value) => progress = value,
      );
      expect(progress, 1);
    },
  );
  test('backend error codes reach caller', () async {
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 403;
      request.response.write(
        jsonEncode({
          'error': {
            'code': 'permission-denied',
            'message': 'Membership required.',
          },
        }),
      );
      await request.response.close();
    });
    await expectLater(
      transport.call('getGroupMoment', {}),
      throwsA(
        isA<MomentFailure>().having((e) => e.code, 'code', 'permission-denied'),
      ),
    );
  });
  test('owner change during ID token refresh prevents any request', () async {
    var owner = true;
    final client = MomentHttpTransport(
      baseUrl: 'http://127.0.0.1:${server.port}',
      token: () async {
        owner = false;
        return 'test-token';
      },
      isOwner: () => owner,
    );
    await expectLater(
      client.call('getGroupMoment', {}),
      throwsA(
        isA<MomentFailure>().having((e) => e.code, 'code', 'unauthenticated'),
      ),
    );
  });
  test('pre-cancelled upload makes no request', () async {
    final cancellation = MomentUploadCancellation();
    await cancellation.cancel();
    await expectLater(
      transport.upload(
        'm',
        Uint8List.fromList([1]),
        cancellation: cancellation,
        progress: (_) {},
      ),
      throwsA(isA<MomentFailure>().having((e) => e.code, 'code', 'cancelled')),
    );
  });
}
