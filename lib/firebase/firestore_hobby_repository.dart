import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/hobby_data.dart';
import '../models/schedule_draft.dart';
import '../services/hobby_repository.dart';

class FirestoreHobbyRepository implements HobbyRepository {
  FirestoreHobbyRepository(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  static const uuid = Uuid();
  void owner(String uid) {
    if (uid.isEmpty || auth.currentUser?.uid != uid) {
      throw const DataFailure(
        'Phiên đăng nhập đã thay đổi. Hãy đăng nhập lại.',
      );
    }
  }

  CollectionReference<Json> own(String uid, String collection) {
    owner(uid);
    return db.collection('users').doc(uid).collection(collection);
  }

  Json decode(Json data) => data.map(
    (key, value) => MapEntry(key, value is Timestamp ? value.toDate() : value),
  );
  Json encode(Json data) => data.map(
    (key, value) =>
        MapEntry(key, value is DateTime ? Timestamp.fromDate(value) : value),
  );
  DataFailure failure(Object e) => e is DataFailure
      ? e
      : DataFailure(
          e is FirebaseException
              ? switch (e.code) {
                  'permission-denied' =>
                    'Bạn không có quyền thực hiện thao tác này.',
                  'unavailable' || 'deadline-exceeded' =>
                    'Không có mạng hoặc máy chủ chưa phản hồi. Vui lòng thử lại.',
                  _ =>
                    'Không thể đồng bộ dữ liệu (${e.code}). Vui lòng thử lại.',
                }
              : 'Không thể đồng bộ dữ liệu. Vui lòng thử lại.',
        );
  Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      throw failure(e);
    }
  }

  Stream<List<SocialEntry>> entries(Query<Json> query) => query
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => SocialEntry(id: d.id, data: decode(d.data())))
            .toList(),
      )
      .handleError((Object e) {
        throw failure(e);
      });
  Future<String> name(String uid) async {
    owner(uid);
    final p = await db.doc('users/$uid').get();
    return (p.data()?['displayName'] as String?) ?? 'Hobby Tracker user';
  }

  @override
  Stream<List<Hobby>> hobbies(String uid) => own(uid, 'hobbies')
      .snapshots()
      .map(
        (s) =>
            s.docs
                .map((d) => Hobby.fromJson(d.id, d.data()))
                .where((h) => !h.archived)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      )
      .handleError((Object e) {
        throw failure(e);
      });
  @override
  Future<void> saveHobby(String uid, Hobby hobby) => guard(() async {
    owner(uid);
    validateHobby(hobby.name, hobby.description, hobby.priority);
    if (![
          'spark',
          'camera',
          'music',
          'book',
          'palette',
          'fitness',
          'sports',
          'code',
          'garden',
          'cook',
          'chess',
          'travel',
        ].contains(hobby.icon) ||
        ![
          'mint',
          'blue',
          'orange',
          'purple',
          'pink',
          'gold',
        ].contains(hobby.color)) {
      throw const DataFailure('Chọn biểu tượng và màu hợp lệ.');
    }
    final doc = own(uid, 'hobbies').doc(hobby.id),
        claim = own(uid, 'hobbyNames').doc(hobby.nameKey);
    await db.runTransaction<void>((tx) async {
      final existing = await tx.get(doc), reserved = await tx.get(claim);
      if (existing.data()?['archived'] == true) {
        throw const DataFailure('Sở thích đã được xóa.');
      }
      if (reserved.exists && reserved.data()?['hobbyId'] != hobby.id) {
        throw const DataFailure('Tên sở thích đã tồn tại. Hãy chọn tên khác.');
      }
      final oldKey = existing.data()?['nameKey'] as String?;
      tx.set(doc, {
        ...hobby.toJson(),
        'createdAt':
            existing.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      tx.set(claim, {'hobbyId': hobby.id});
      if (oldKey != null && oldKey != hobby.nameKey) {
        tx.delete(own(uid, 'hobbyNames').doc(oldKey));
      }
    });
  });
  @override
  Future<void> removeHobby(String uid, Hobby hobby) => guard(() async {
    owner(uid);
    final plans = await own(
      uid,
      'plans',
    ).where('hobbyId', isEqualTo: hobby.id).get();
    if (plans.docs.length > 400) {
      throw const DataFailure(
        'Có quá nhiều lịch liên quan. Hãy xóa bớt lịch trước khi xóa sở thích.',
      );
    }
    final ref = own(uid, 'hobbies').doc(hobby.id);
    await db.runTransaction<void>((tx) async {
      final current = await tx.get(ref);
      if (!current.exists || current.data()?['archived'] == true) return;
      tx.update(ref, {'archived': true});
      tx.delete(
        own(uid, 'hobbyNames').doc(current.data()!['nameKey'] as String),
      );
      for (final plan in plans.docs) {
        tx.delete(plan.reference);
      }
    });
    // Logical removal protects historical snapshots. New plans are denied by
    // rules once archived; views also exclude any concurrent orphaned plan.
  });
  @override
  Stream<List<PracticePlan>> plans(String uid) => own(uid, 'plans')
      .snapshots()
      .map(
        (s) => s.docs.map((d) {
          final j = decode(d.data());
          return PracticePlan(
            id: d.id,
            hobbyId: j['hobbyId'] as String,
            title: j['title'] as String,
            startsAt: j['startsAt'] as DateTime,
            minutes: j['minutes'] as int,
            done: j['done'] as bool,
            eventId: j['eventId'] as String,
            completionId: j['completionId'] as String? ?? '',
          );
        }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
      )
      .handleError((Object e) {
        throw failure(e);
      });
  @override
  Future<void> savePlan(String uid, PracticePlan plan) => guard(() async {
    owner(uid);
    validatePracticePlan(plan);
    await own(uid, 'plans').doc(plan.id).set(encode(plan.toJson()));
  });
  @override
  Future<void> createPlans(
    String uid,
    List<PracticePlan> plans,
  ) => guard(() async {
    owner(uid);
    if (plans.isEmpty ||
        plans.length > maxScheduleOccurrences ||
        plans.map((p) => p.id).toSet().length != plans.length) {
      throw const DataFailure(
        'Choose a shorter repeat range (maximum 100 sessions).',
      );
    }
    for (final plan in plans) {
      validatePracticePlan(plan);
    }
    final collection = own(uid, 'plans');
    await db.runTransaction<void>((tx) async {
      owner(uid);
      final existing = <DocumentSnapshot<Json>>[];
      for (final plan in plans) {
        existing.add(await tx.get(collection.doc(plan.id)));
      }
      // All reads precede writes. Retrying a lost acknowledgement never resets a completed session.
      for (var i = 0; i < plans.length; i++) {
        final plan = plans[i], old = existing[i];
        if (old.exists) {
          final data = decode(old.data()!);
          final previous = PracticePlan(
            id: old.id,
            hobbyId: data['hobbyId'] as String,
            title: data['title'] as String,
            startsAt: data['startsAt'] as DateTime,
            minutes: data['minutes'] as int,
            eventId: data['eventId'] as String,
          );
          if (!sameScheduleContent(previous, plan)) {
            throw const DataFailure(
              'This schedule changed. Close the form and try again.',
            );
          }
        } else {
          tx.set(collection.doc(plan.id), encode(plan.toJson()));
        }
      }
    });
  });
  @override
  Future<void> deletePlan(String uid, String id) =>
      guard(() => own(uid, 'plans').doc(id).delete());
  @override
  Stream<List<PracticeRecord>> history(String uid) => own(uid, 'history')
      .snapshots()
      .map(
        (s) => s.docs.map((d) {
          final j = decode(d.data());
          return PracticeRecord(
            id: d.id,
            hobbyId: j['hobbyId'] as String,
            name: j['name'] as String,
            icon: j['icon'] as String,
            color: j['color'] as String,
            elapsedMs: j['elapsedMs'] as int,
            notes: j['notes'] as String,
            finishedAt: j['finishedAt'] as DateTime,
            planId: j['planId'] as String,
          );
        }).toList()..sort((a, b) => b.finishedAt.compareTo(a.finishedAt)),
      )
      .handleError((Object e) {
        throw failure(e);
      });
  @override
  Future<void> finish(String uid, PracticeRecord record) => guard(() async {
    owner(uid);
    if (record.elapsedMs < 0 ||
        record.elapsedMs > 86400000 ||
        record.notes.runes.length > 2000) {
      throw const DataFailure(
        'Phiên tối đa 24 giờ, ghi chú tối đa 2000 ký tự.',
      );
    }
    final ref = own(uid, 'history').doc(record.id);
    await db.runTransaction<void>((tx) async {
      if ((await tx.get(ref)).exists) return;
      final h = await tx.get(own(uid, 'hobbies').doc(record.hobbyId));
      if (!h.exists || h.data()?['archived'] == true) {
        throw const DataFailure(
          'Sở thích không còn tồn tại. Ghi chú vẫn được giữ trong bản nháp.',
        );
      }
      final planRef = record.planId.isEmpty
          ? null
          : own(uid, 'plans').doc(record.planId);
      final plan = planRef == null ? null : await tx.get(planRef);
      final linked =
          plan != null &&
          plan.exists &&
          plan.data()?['hobbyId'] == record.hobbyId &&
          plan.data()?['done'] != true;
      tx.set(ref, {
        ...encode(record.toJson()),
        'planId': linked ? record.planId : '',
        'name': h.data()!['name'],
        'icon': h.data()!['icon'],
        'color': h.data()!['color'],
        'finishedAt': FieldValue.serverTimestamp(),
      });
      if (linked) {
        tx.update(planRef!, {'done': true, 'completionId': record.id});
      }
    });
  });
  @override
  Stream<AppPreferences> preferences(String uid) => own(uid, 'settings')
      .doc('preferences')
      .snapshots()
      .map((d) => AppPreferences.fromJson(d.data() ?? {}))
      .handleError((Object e) {
        throw failure(e);
      });
  @override
  Future<void> savePreferences(String uid, AppPreferences value) =>
      guard(() async {
        owner(uid);
        if (value.displayName.trim().runes.length < 2 ||
            value.displayName.runes.length > 80 ||
            value.bio.runes.length > 300 ||
            !RegExp(r'^[A-Za-z0-9_]{0,24}$').hasMatch(value.handle)) {
          throw const DataFailure(
            'Tên 2–80 ký tự; handle chỉ chữ/số/_ (tối đa 24); bio tối đa 300.',
          );
        }
        final batch = db.batch();
        batch.set(own(uid, 'settings').doc('preferences'), value.toJson());
        batch.update(db.doc('users/$uid'), {
          'displayName': value.displayName.trim(),
        });
        batch.set(db.doc('profiles/$uid'), {
          'displayName': value.displayName.trim(),
          'handle': value.handle,
          'bio': value.bio,
          'color': value.color,
          'visible': value.visible,
          'allowMessages': value.allowMessages,
        });
        await batch.commit();
        if (auth.currentUser?.uid == uid &&
            auth.currentUser?.displayName != value.displayName.trim()) {
          await auth.currentUser!.updateDisplayName(value.displayName.trim());
        }
      });
  @override
  Stream<List<SocialEntry>> feed(int limit) => entries(
    db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit.clamp(1, 100)),
  );
  @override
  Future<void> publish(String uid, String text, String topic) =>
      guard(() async {
        owner(uid);
        if (text.trim().runes.length < 3 ||
            text.runes.length > 800 ||
            topic.runes.length > 50) {
          throw const DataFailure(
            'Bài viết cần 3–800 ký tự; chủ đề tối đa 50 ký tự.',
          );
        }
        await db.collection('posts').doc(uuid.v4()).set({
          'authorId': uid,
          'authorName': await name(uid),
          'text': text.trim(),
          'topic': topic.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
  @override
  Stream<List<SocialEntry>> likes(String postId) =>
      entries(db.collection('posts/$postId/likes'));
  @override
  Future<void> like(String uid, String postId, bool value) => guard(() async {
    owner(uid);
    final r = db.doc('posts/$postId/likes/$uid');
    if (value) {
      await r.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await r.delete();
    }
  });
  @override
  Stream<List<SocialEntry>> comments(String postId) =>
      entries(db.collection('posts/$postId/comments').orderBy('createdAt'));
  @override
  Future<void> comment(
    String uid,
    String postId,
    String text,
    String draftId,
  ) => guard(() async {
    owner(uid);
    if (text.trim().isEmpty || text.runes.length > 300) {
      throw const DataFailure('Bình luận cần 1–300 ký tự.');
    }
    final author = await name(uid),
        ref = db.doc('posts/$postId/comments/$draftId');
    await db.runTransaction<void>((tx) async {
      final old = await tx.get(ref);
      if (old.exists) {
        if (old.data()?['authorId'] != uid ||
            old.data()?['text'] != text.trim()) {
          throw const DataFailure('Mã bản nháp đã được sử dụng.');
        }
        return;
      }
      tx.set(ref, {
        'authorId': uid,
        'authorName': author,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  });
  @override
  Stream<List<SocialEntry>> groups() =>
      entries(db.collection('groups').orderBy('createdAt', descending: true));
  @override
  Stream<List<SocialEntry>> joinedGroups(String uid) =>
      entries(own(uid, 'groupLinks'));
  @override
  Future<String> createGroup(
    String uid,
    String name,
    String topic,
    String description,
  ) => guard(() async {
    owner(uid);
    if (name.trim().runes.length < 3 ||
        name.runes.length > 60 ||
        topic.runes.length > 50 ||
        description.runes.length > 300) {
      throw const DataFailure('Tên nhóm cần 3–60 ký tự; mô tả tối đa 300.');
    }
    final id = uuid.v4();
    final b = db.batch();
    b.set(db.doc('groups/$id'), {
      'ownerId': uid,
      'name': name.trim(),
      'topic': topic.trim(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    b.set(db.doc('groups/$id/members/$uid'), {
      'uid': uid,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    b.set(own(uid, 'groupLinks').doc(id), {'name': name.trim()});
    await b.commit();
    return id;
  });
  @override
  Future<void> joinGroup(String uid, String groupId) => guard(() async {
    owner(uid);
    final g = await db.doc('groups/$groupId').get();
    if (!g.exists) throw const DataFailure('Nhóm không còn tồn tại.');
    final b = db.batch();
    b.set(db.doc('groups/$groupId/members/$uid'), {
      'uid': uid,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    b.set(own(uid, 'groupLinks').doc(groupId), {'name': g.data()!['name']});
    await b.commit();
  });
  @override
  Stream<List<SocialEntry>> events() =>
      entries(db.collection('events').orderBy('startsAt'));
  @override
  Future<void> createEvent(
    String uid,
    String title,
    String topic,
    DateTime startsAt,
  ) => guard(() async {
    owner(uid);
    if (title.trim().runes.length < 3 ||
        title.runes.length > 120 ||
        topic.runes.length > 50 ||
        !startsAt.isAfter(DateTime.now())) {
      throw const DataFailure(
        'Nhập tên 3–120 ký tự và thời gian trong tương lai.',
      );
    }
    await db.collection('events').doc(uuid.v4()).set({
      'ownerId': uid,
      'title': title.trim(),
      'topic': topic.trim(),
      'startsAt': Timestamp.fromDate(startsAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  });
  @override
  Stream<List<SocialEntry>> rsvps(String uid) => entries(own(uid, 'rsvps'));
  @override
  Future<void> rsvp(String uid, String eventId, bool going) => guard(() async {
    owner(uid);
    final b = db.batch();
    b.set(own(uid, 'rsvps').doc(eventId), {'going': going});
    if (!going) {
      final plans = await own(
        uid,
        'plans',
      ).where('eventId', isEqualTo: eventId).get();
      if (plans.docs.length > 400) {
        throw const DataFailure('Có quá nhiều lịch liên quan.');
      }
      for (final p in plans.docs) {
        b.delete(p.reference);
      }
    }
    await b.commit();
  });
  @override
  Future<void> addEventToHome(String uid, SocialEntry event, Hobby hobby) =>
      guard(() async {
        owner(uid);
        final id = 'event_${event.id}';
        await db.runTransaction<void>((tx) async {
          final rsvp = await tx.get(own(uid, 'rsvps').doc(event.id));
          final e = await tx.get(db.doc('events/${event.id}'));
          final p = await tx.get(own(uid, 'plans').doc(id));
          if (rsvp.data()?['going'] != true) {
            throw const DataFailure('Hãy RSVP trước khi thêm vào Home.');
          }
          if (!e.exists) {
            throw const DataFailure('Hoạt động không còn tồn tại.');
          }
          if (p.exists) return;
          tx.set(own(uid, 'plans').doc(id), {
            'hobbyId': hobby.id,
            'title': String.fromCharCodes(
              (e.data()!['title'] as String).runes.take(70),
            ),
            'startsAt': e.data()!['startsAt'],
            'minutes': 60,
            'done': false,
            'eventId': event.id,
            'completionId': '',
          });
        });
      });
  @override
  Stream<List<SocialEntry>> people() =>
      entries(db.collection('profiles').where('visible', isEqualTo: true));
  @override
  Future<String> directChat(String uid, String otherUid) => guard(() async {
    owner(uid);
    if (uid == otherUid) {
      throw const DataFailure('Chọn một người khác để nhắn tin.');
    }
    final users = [uid, otherUid]..sort();
    final id = users
        .map((u) => base64Url.encode(utf8.encode(u)).replaceAll('=', ''))
        .join('.');
    final ref = db.doc('directChats/$id');
    await db.runTransaction<void>((tx) async {
      final old = await tx.get(ref);
      if (!old.exists) {
        tx.set(ref, {
          'participants': users,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
    return id;
  });
  @override
  Stream<List<SocialEntry>> chats(String uid) {
    owner(uid);
    return entries(
      db.collection('directChats').where('participants', arrayContains: uid),
    );
  }

  @override
  Stream<List<SocialEntry>> messages(String uid, String id, bool group) {
    owner(uid);
    return entries(
      db
          .collection('${group ? 'groupChats' : 'directChats'}/$id/messages')
          .orderBy('createdAt'),
    );
  }

  @override
  Future<void> send(
    String uid,
    String id,
    bool group,
    String text,
    String draftId,
  ) => guard(() async {
    owner(uid);
    if (text.trim().isEmpty || text.runes.length > 2000) {
      throw const DataFailure('Tin nhắn cần 1–2000 ký tự.');
    }
    final ref = db.doc(
      '${group ? 'groupChats' : 'directChats'}/$id/messages/$draftId',
    );
    await db.runTransaction<void>((tx) async {
      final old = await tx.get(ref);
      if (old.exists) {
        if (old.data()?['senderId'] != uid ||
            old.data()?['text'] != text.trim()) {
          throw const DataFailure('Mã bản nháp đã được sử dụng.');
        }
        return;
      }
      tx.set(ref, {
        'senderId': uid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  });
}
