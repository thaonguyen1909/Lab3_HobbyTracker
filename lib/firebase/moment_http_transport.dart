import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/group_moment.dart';
import '../services/moment_repository.dart';

class MomentHttpTransport {
  MomentHttpTransport({
    required this.baseUrl,
    required this.token,
    required this.isOwner,
  });
  final String baseUrl;
  final Future<String?> Function() token;
  final bool Function() isOwner;
  static const configuredUrl = String.fromEnvironment('MOMENTS_API_URL');

  static Uri validateUrl(String value, {required bool debug}) {
    final uri = Uri.tryParse(value);
    final local =
        uri != null &&
        ['127.0.0.1', 'localhost', '10.0.2.2'].contains(uri.host);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !(uri.scheme == 'https' || (debug && local && uri.scheme == 'http'))) {
      throw const MomentFailure(
        'api-not-configured',
        'Moments service is not configured. Please contact the app team.',
      );
    }
    return uri;
  }

  Future<Map<String, dynamic>> call(
    String method,
    Map<String, Object?> data, {
    bool Function()? owner,
  }) => _request(method, json: data, owner: owner);

  Future<void> upload(
    String momentId,
    Uint8List bytes, {
    required MomentUploadCancellation cancellation,
    required void Function(double) progress,
    bool Function()? owner,
  }) async {
    await _request(
      'stage',
      momentId: momentId,
      bytes: bytes,
      cancellation: cancellation,
      progress: progress,
      owner: owner,
    );
  }

  Future<Map<String, dynamic>> _request(
    String method, {
    Map<String, Object?>? json,
    String? momentId,
    Uint8List? bytes,
    MomentUploadCancellation? cancellation,
    void Function(double)? progress,
    bool Function()? owner,
  }) async {
    final base = validateUrl(baseUrl, debug: kDebugMode);
    bool owned() => isOwner() && (owner?.call() ?? true);
    if (!owned()) {
      throw const MomentFailure(
        'unauthenticated',
        'Your account changed. Please sign in again.',
      );
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    cancellation?.bind(() async => client.close(force: true));
    try {
      if (cancellation?.cancelled == true) {
        throw const MomentFailure(
          'cancelled',
          'Upload cancelled. Your draft is kept.',
        );
      }
      final idToken = await token().timeout(const Duration(seconds: 20));
      if (idToken == null || !owned()) {
        throw const MomentFailure(
          'unauthenticated',
          'Your account changed. Please sign in again.',
        );
      }
      final uri = base.replace(
        path: '/v1/$method',
        queryParameters: momentId == null ? null : {'momentId': momentId},
      );
      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        bytes == null ? 'application/json' : 'application/octet-stream',
      );
      final payload =
          bytes ?? Uint8List.fromList(utf8.encode(jsonEncode(json)));
      request.contentLength = payload.length;
      for (var offset = 0; offset < payload.length; offset += 65536) {
        final end = (offset + 65536).clamp(0, payload.length);
        request.add(payload.sublist(offset, end));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 125),
      );
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        if (builder.length + chunk.length > 4 * 1024 * 1024) {
          throw const FormatException('Response too large');
        }
        builder.add(chunk);
      }
      if (!owned()) {
        throw const MomentFailure(
          'unauthenticated',
          'Your account changed. Please sign in again.',
        );
      }
      final result = momentMap(jsonDecode(utf8.decode(builder.takeBytes())));
      if (response.statusCode != 200) {
        final error = momentMap(result['error']);
        throw MomentFailure(
          momentString(error, 'code'),
          momentString(error, 'message'),
        );
      }
      if (cancellation?.cancelled == true) {
        throw const MomentFailure(
          'cancelled',
          'Upload cancelled. Your draft is kept.',
        );
      }
      progress?.call(1);
      return momentMap(result['data']);
    } on MomentFailure {
      rethrow;
    } on TimeoutException {
      throw const MomentFailure(
        'deadline-exceeded',
        'The request timed out. Your draft is kept. Try again.',
      );
    } on FormatException {
      throw const MomentFailure(
        'invalid-response',
        'The moment service returned an invalid response.',
      );
    } on IOException {
      if (cancellation?.cancelled == true) {
        throw const MomentFailure(
          'cancelled',
          'Upload cancelled. Your draft is kept.',
        );
      }
      throw const MomentFailure(
        'unavailable',
        'Could not connect to moments. Please try again.',
      );
    } finally {
      cancellation?.unbind();
      client.close(force: true);
    }
  }
}
