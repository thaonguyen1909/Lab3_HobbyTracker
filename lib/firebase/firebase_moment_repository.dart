import 'dart:async';
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/group_moment.dart';
import '../services/moment_repository.dart';
import 'moment_http_transport.dart';

class FirebaseMomentRepository implements MomentRepository {
  FirebaseMomentRepository(
    this.functions,
    this.storage,
    this.auth, {
    this.http,
  });
  final MomentHttpTransport? http;
  final FirebaseFunctions functions;
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  void _owner(String uid) {
    if (uid.isEmpty || auth.currentUser?.uid != uid) {
      throw const MomentFailure(
        'unauthenticated',
        'Your account changed. Please sign in again.',
      );
    }
  }

  Future<({Map<String, dynamic> data, Duration elapsed})> _call(
    String uid,
    String method,
    Map<String, Object?> data,
  ) async {
    _owner(uid);
    final timer = Stopwatch()..start();
    try {
      if (http != null) {
        try {
          final response = await http!.call(
            method,
            data,
            owner: () => auth.currentUser?.uid == uid,
          );
          _owner(uid);
          return (data: response, elapsed: timer.elapsed);
        } on MomentFailure catch (error) {
          if (error.code == 'api-not-configured') rethrow;
          throw momentBackendFailure(
            error.code,
            serverMessage: error.message,
            listing:
                method == 'listGroupMoments' ||
                method == 'beginGroupMomentUpload',
          );
        }
      }
      final result = await functions
          .httpsCallable(
            method,
            options: HttpsCallableOptions(
              timeout: const Duration(seconds: 125),
            ),
          )
          .call<Object?>(data);
      _owner(uid);
      return (data: momentMap(result.data), elapsed: timer.elapsed);
    } on FirebaseFunctionsException catch (error) {
      throw momentBackendFailure(
        error.code,
        serverMessage: error.message,
        listing:
            method == 'listGroupMoments' || method == 'beginGroupMomentUpload',
      );
    } on FormatException {
      throw const MomentFailure(
        'invalid-response',
        'The moment service returned an invalid response.',
      );
    }
  }

  @override
  Future<MomentUploadTicket> begin(String uid, MomentDraft draft) async {
    final result = (await _call(uid, 'beginGroupMomentUpload', {
      'requestId': draft.requestId,
      'groupId': draft.groupId,
      'hobbyId': draft.hobbyId,
      'caption': draft.caption,
    })).data;
    return MomentUploadTicket(
      id: momentString(result, 'momentId'),
      groupId: momentString(result, 'groupId'),
      bucket: momentString(result, 'bucket'),
      path: momentString(result, 'stagingPath'),
      deadline: momentDate(result, 'uploadDeadline'),
      status: momentString(result, 'status'),
    );
  }

  @override
  Future<void> upload(
    String uid,
    MomentUploadTicket ticket,
    MomentPhoto photo, {
    required void Function(double) progress,
    required MomentUploadCancellation cancellation,
  }) async {
    _owner(uid);
    if (http != null) {
      if (!validMomentId(ticket.id) ||
          ticket.bucket != 'cloudinary' ||
          ticket.path != 'momentStaging/$uid/${ticket.id}/source' ||
          photo.bytes.length > MomentPhoto.maxBytes) {
        throw const MomentFailure(
          'invalid-upload',
          'The upload session is invalid. Please try again.',
        );
      }
      try {
        await http!.upload(
          ticket.id,
          photo.bytes,
          cancellation: cancellation,
          progress: progress,
          owner: () => auth.currentUser?.uid == uid,
        );
      } on MomentFailure catch (error) {
        if (error.code == 'api-not-configured' || error.code == 'cancelled') {
          rethrow;
        }
        throw momentBackendFailure(error.code, serverMessage: error.message);
      }
      _owner(uid);
      return;
    }
    if (!validMomentId(ticket.id) ||
        ticket.path != 'momentStaging/$uid/${ticket.id}/source' ||
        ticket.bucket != storage.ref().bucket ||
        photo.bytes.length > MomentPhoto.maxBytes) {
      throw const MomentFailure(
        'invalid-upload',
        'The upload session is invalid. Please try again.',
      );
    }
    if (cancellation.cancelled) {
      throw const MomentFailure(
        'cancelled',
        'Upload cancelled. Your draft is kept.',
      );
    }
    final task = storage
        .ref(ticket.path)
        .putData(photo.bytes, SettableMetadata(contentType: photo.contentType));
    cancellation.bind(() async {
      await task.cancel();
    });
    final subscription = task.snapshotEvents.listen((event) {
      if (!cancellation.cancelled && auth.currentUser?.uid == uid) {
        progress(
          event.totalBytes == 0 ? 0 : event.bytesTransferred / event.totalBytes,
        );
      }
    }, onError: (Object _) {});
    try {
      await task;
      _owner(uid);
      if (cancellation.cancelled) {
        throw const MomentFailure(
          'cancelled',
          'Upload cancelled. Your draft is kept.',
        );
      }
    } on FirebaseException catch (error) {
      throw MomentFailure(
        error.code,
        error.code == 'canceled'
            ? 'Upload cancelled. Your draft is kept.'
            : error.code == 'unauthorized'
            ? 'The upload session is unavailable. Choose Post moment again to start a new upload.'
            : 'Could not upload the photo. Your draft is kept.',
      );
    } finally {
      cancellation.unbind();
      await subscription.cancel();
    }
  }

  @override
  Future<GroupMoment> publish(String uid, String momentId) async =>
      GroupMoment.fromJson(
        (await _call(uid, 'publishGroupMoment', {'momentId': momentId})).data,
      );

  @override
  Future<MomentPage> list(
    String uid,
    String groupId, {
    MomentCursor? cursor,
  }) async {
    final result = await _call(uid, 'listGroupMoments', {
      'groupId': groupId,
      'limit': 6,
      if (cursor != null) 'cursor': cursor.toJson(),
    });
    final items = result.data['items'];
    if (items is! List) {
      throw const MomentFailure(
        'invalid-response',
        'The moment service returned an invalid response.',
      );
    }
    final rawCursor = result.data['nextCursor'];
    final next = rawCursor == null ? null : momentMap(rawCursor);
    return MomentPage(
      items.map((item) => GroupMoment.fromJson(momentMap(item))).toList(),
      momentDate(result.data, 'serverNow'),
      roundTrip: result.elapsed,
      nextCursor: next == null
          ? null
          : MomentCursor(
              (next['expiresAtMs'] as num).toInt(),
              momentString(next, 'momentId'),
            ),
    );
  }

  @override
  Future<MomentDetail> get(String uid, String groupId, String momentId) async {
    final result = await _call(uid, 'getGroupMoment', {
      'groupId': groupId,
      'momentId': momentId,
    });
    return MomentDetail(
      GroupMoment.fromJson(result.data),
      momentDate(result.data, 'serverNow'),
      roundTrip: result.elapsed,
    );
  }

  @override
  Future<MomentImage> image(
    String uid,
    String groupId,
    String momentId, {
    required bool thumbnail,
  }) async {
    final result = await _call(uid, 'getGroupMomentImage', {
      'groupId': groupId,
      'momentId': momentId,
      'variant': thumbnail ? 'thumbnail' : 'photo',
    });
    final bytes = base64Decode(momentString(result.data, 'base64'));
    if (result.data['contentType'] != 'image/jpeg' ||
        bytes.isEmpty ||
        bytes.length > 2 * 1024 * 1024) {
      throw const MomentFailure(
        'invalid-response',
        'The moment service returned an invalid response.',
      );
    }
    return MomentImage(
      bytes,
      momentDate(result.data, 'expiresAt'),
      momentDate(result.data, 'serverNow'),
      roundTrip: result.elapsed,
    );
  }

  @override
  Future<void> retract(String uid, String groupId, String momentId) async {
    await _call(uid, 'retractGroupMoment', {
      'groupId': groupId,
      'momentId': momentId,
    });
  }
}

MomentFailure momentBackendFailure(
  String code, {
  bool listing = false,
  String? serverMessage,
}) {
  // These exact responses mean the server rejected an expired upload session,
  // unlike a transport timeout where publication may already have committed.
  if (code == 'deadline-exceeded' &&
      (serverMessage == 'Upload session expired.' ||
          serverMessage == 'Upload session expired. Start a new upload.')) {
    return const MomentFailure(
      'upload-expired',
      'The upload session is unavailable. Choose Post moment again to start a new upload.',
    );
  }
  return MomentFailure(code, switch (code) {
    'unauthenticated' => 'Your account changed. Please sign in again.',
    'permission-denied' => 'You no longer have access to this group.',
    'not-found' =>
      listing
          ? 'Moments are not available yet. Please try again later.'
          : 'This moment has expired or is no longer available.',
    'resource-exhausted' =>
      'Too many requests. Please wait before trying again.',
    'deadline-exceeded' =>
      'The request timed out. Your draft is kept. Try again.',
    'aborted' => 'This photo is being processed. Please try again shortly.',
    'failed-precondition' =>
      'This upload cannot be completed. Check your group and hobby, then try again.',
    'invalid-argument' =>
      'The photo or caption is invalid. Please check and try again.',
    _ => 'Could not connect to moments. Please try again.',
  });
}
