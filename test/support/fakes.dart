import 'package:hobby_tracker/l10n/language_controller.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:hobby_tracker/models/hobby_data.dart';
import 'package:hobby_tracker/services/hobby_repository.dart';
import 'package:hobby_tracker/services/device_services.dart';

class TestRepository implements HobbyRepository {
  final change = StreamController<int>.broadcast();
  final hobbyData = <String, Map<String, Hobby>>{},
      planData = <String, Map<String, PracticePlan>>{},
      recordData = <String, Map<String, PracticeRecord>>{};
  final preferenceData = <String, AppPreferences>{};
  final posts = <SocialEntry>[],
      groupData = <SocialEntry>[],
      eventData = <SocialEntry>[],
      peopleData = <SocialEntry>[];
  final joined = <String, List<SocialEntry>>{},
      chatData = <String, List<SocialEntry>>{},
      messageData = <String, List<SocialEntry>>{},
      rsvpData = <String, List<SocialEntry>>{};
  bool failWrites = false, failReads = false;
  int writes = 0;
  int serial = 0;
  void emit() {
    change.add(++serial);
  }

  void beforeWrite() {
    if (failWrites) {
      throw const DataFailure(
        'Không có mạng hoặc máy chủ chưa phản hồi. Vui lòng thử lại.',
      );
    }
    writes++;
  }

  Stream<T> watch<T>(T Function() read) async* {
    if (failReads) {
      throw const DataFailure('Mất kết nối');
    }
    yield read();
    yield* change.stream.map((_) => read());
  }

  Future<void> dispose() => change.close();
  @override
  Stream<List<Hobby>> hobbies(String uid) => watch(
    () => hobbyData[uid]?.values.where((h) => !h.archived).toList() ?? [],
  );
  @override
  Future<void> saveHobby(String uid, Hobby hobby) async {
    beforeWrite();
    validateHobby(hobby.name, hobby.description, hobby.priority);
    final data = hobbyData.putIfAbsent(uid, () => {});
    if (data.values.any(
      (h) => !h.archived && h.id != hobby.id && h.nameKey == hobby.nameKey,
    )) {
      throw const DataFailure('Tên sở thích đã tồn tại. Hãy chọn tên khác.');
    }
    data[hobby.id] = hobby;
    emit();
  }

  @override
  Future<void> removeHobby(String uid, Hobby hobby) async {
    beforeWrite();
    hobbyData[uid]?.remove(hobby.id);
    planData[uid]?.removeWhere((_, p) => p.hobbyId == hobby.id);
    emit();
  }

  @override
  Stream<List<PracticePlan>> plans(String uid) =>
      watch(() => planData[uid]?.values.toList() ?? []);
  @override
  Future<void> savePlan(String uid, PracticePlan plan) async {
    beforeWrite();
    if (plan.title.isEmpty) throw const DataFailure('Nhập tên buổi tập.');
    planData.putIfAbsent(uid, () => {})[plan.id] = plan;
    emit();
  }

  @override
  Future<void> deletePlan(String uid, String id) async {
    beforeWrite();
    planData[uid]?.remove(id);
    emit();
  }

  @override
  Stream<List<PracticeRecord>> history(String uid) =>
      watch(() => recordData[uid]?.values.toList() ?? []);
  @override
  Future<void> finish(String uid, PracticeRecord record) async {
    beforeWrite();
    recordData.putIfAbsent(uid, () => {}).putIfAbsent(record.id, () => record);
    final p = planData[uid]?[record.planId];
    if (p != null) {
      planData[uid]![p.id] = PracticePlan(
        id: p.id,
        hobbyId: p.hobbyId,
        title: p.title,
        startsAt: p.startsAt,
        minutes: p.minutes,
        done: true,
        completionId: record.id,
      );
    }
    emit();
  }

  @override
  Stream<AppPreferences> preferences(String uid) =>
      watch(() => preferenceData[uid] ?? const AppPreferences());
  @override
  Future<void> savePreferences(String uid, AppPreferences value) async {
    beforeWrite();
    preferenceData[uid] = value;
    emit();
  }

  @override
  Stream<List<SocialEntry>> feed(int limit) =>
      watch(() => posts.take(limit).toList());
  @override
  Future<void> publish(String uid, String text, String topic) async {
    beforeWrite();
    posts.add(
      SocialEntry(
        id: 'post-${serial + 1}',
        data: {
          'authorId': uid,
          'authorName': 'Test only',
          'text': text,
          'topic': topic,
          'createdAt': DateTime.now(),
        },
      ),
    );
    emit();
  }

  @override
  Stream<List<SocialEntry>> likes(String postId) => Stream.value([]);
  @override
  Future<void> like(String uid, String postId, bool value) async {
    beforeWrite();
  }

  @override
  Stream<List<SocialEntry>> comments(String postId) =>
      watch(() => messageData['comments-$postId'] ?? []);
  @override
  Future<void> comment(
    String uid,
    String postId,
    String text,
    String draftId,
  ) async {
    beforeWrite();
    messageData
        .putIfAbsent('comments-$postId', () => [])
        .add(SocialEntry(id: draftId, data: {'authorId': uid, 'text': text}));
    emit();
  }

  @override
  Stream<List<SocialEntry>> groups() => watch(() => groupData);
  @override
  Stream<List<SocialEntry>> joinedGroups(String uid) =>
      watch(() => joined[uid] ?? []);
  @override
  Future<String> createGroup(
    String uid,
    String name,
    String topic,
    String description,
  ) async {
    beforeWrite();
    final id = 'group-${serial + 1}';
    groupData.add(
      SocialEntry(
        id: id,
        data: {'name': name, 'topic': topic, 'description': description},
      ),
    );
    emit();
    return id;
  }

  @override
  Future<void> joinGroup(String uid, String groupId) async {
    beforeWrite();
    joined
        .putIfAbsent(uid, () => [])
        .add(SocialEntry(id: groupId, data: {'name': groupId}));
    emit();
  }

  @override
  Stream<List<SocialEntry>> events() => watch(() => eventData);
  @override
  Future<void> createEvent(
    String uid,
    String title,
    String topic,
    DateTime startsAt,
  ) async {
    beforeWrite();
    eventData.add(
      SocialEntry(
        id: 'event-${serial + 1}',
        data: {'title': title, 'topic': topic, 'startsAt': startsAt},
      ),
    );
    emit();
  }

  @override
  Stream<List<SocialEntry>> rsvps(String uid) =>
      watch(() => rsvpData[uid] ?? []);
  @override
  Future<void> rsvp(String uid, String eventId, bool going) async {
    beforeWrite();
    final data = rsvpData.putIfAbsent(uid, () => []);
    data.removeWhere((e) => e.id == eventId);
    data.add(SocialEntry(id: eventId, data: {'going': going}));
    if (!going) planData[uid]?.removeWhere((_, p) => p.eventId == eventId);
    emit();
  }

  @override
  Future<void> addEventToHome(
    String uid,
    SocialEntry event,
    Hobby hobby,
  ) async {
    beforeWrite();
    if (!(rsvpData[uid] ?? []).any(
      (r) => r.id == event.id && r.flag('going'),
    )) {
      throw const DataFailure('RSVP trước.');
    }
    planData
        .putIfAbsent(uid, () => {})
        .putIfAbsent(
          'event_${event.id}',
          () => PracticePlan(
            id: 'event_${event.id}',
            hobbyId: hobby.id,
            title: event.text('title'),
            startsAt: event.date('startsAt')!,
            minutes: 60,
            eventId: event.id,
          ),
        );
    emit();
  }

  @override
  Stream<List<SocialEntry>> people() => watch(() => peopleData);
  @override
  Future<String> directChat(String uid, String otherUid) async {
    beforeWrite();
    final id = '$uid.$otherUid';
    chatData
        .putIfAbsent(uid, () => [])
        .add(
          SocialEntry(
            id: id,
            data: {
              'participants': [uid, otherUid],
            },
          ),
        );
    emit();
    return id;
  }

  @override
  Stream<List<SocialEntry>> chats(String uid) =>
      watch(() => chatData[uid] ?? []);
  @override
  Stream<List<SocialEntry>> messages(String uid, String id, bool group) =>
      watch(() => messageData[id] ?? []);
  @override
  Future<void> send(
    String uid,
    String id,
    bool group,
    String text,
    String draftId,
  ) async {
    beforeWrite();
    if (text.trim().isEmpty) throw const DataFailure('Nhập tin nhắn.');
    final data = messageData.putIfAbsent(id, () => []);
    if (!data.any((m) => m.id == draftId)) {
      data.add(SocialEntry(id: draftId, data: {'senderId': uid, 'text': text}));
    }
    emit();
  }
}

class TestDeviceServices implements DeviceServices {
  final drafts = <String, Json>{};
  final logged = <String>[];
  final parameters = <Map<String, Object>>[];
  RuntimeFlags config = const RuntimeFlags();
  @override
  Stream<String> get diagnostics => const Stream.empty();
  @override
  Stream<String> get notificationOpens => const Stream.empty();
  @override
  Future<void> setOwner(String? uid) async {}
  @override
  Future<void> endSession(String? uid) async {
    drafts.remove(uid);
  }

  @override
  Future<void> event(String name, Map<String, Object> parameters) async {
    logged.add(name);
    this.parameters.add(Map.of(parameters));
  }

  @override
  Future<void> screen(String name) async {
    logged.add('screen:$name');
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String reason = 'handled',
    bool fatal = false,
  }) async {
    logged.add('error:$reason');
  }

  @override
  Future<RuntimeFlags> flags() async => config;
  @override
  Future<String> requestNotifications(String uid) async => 'Test permission';
  @override
  Stream<List<InboxItem>> inbox(String uid) => Stream.value([]);
  @override
  Future<void> markRead(String uid, InboxItem item) async {}
  @override
  Future<Json?> readDraft(String uid) async => drafts[uid];
  @override
  Future<void> writeDraft(String uid, Json? draft) async {
    if (draft == null) {
      drafts.remove(uid);
    } else {
      drafts[uid] = draft;
    }
  }

  @override
  Future<void> share(Uint8List bytes) async {}
  @override
  Future<void> shortcut(String kind, String term) async {}
  @override
  Future<void> syncReminders(
    String uid,
    List<PracticePlan> plans,
    List<PracticeRecord> history,
    AppPreferences preferences,
  ) async {}
  @override
  Future<void> feedback() async {
    logged.add('feedback');
  }

  @override
  Future<void> crashTest() async {
    throw const DataFailure('Disabled in tests');
  }
}

class TestReportUploader implements ReportUploader {
  @override
  Future<UploadReceipt> upload(
    String uid,
    Uint8List bytes,
    void Function(double) progress,
  ) async {
    progress(1);
    return UploadReceipt(
      'reports/$uid/test.pdf',
      'https://test.invalid/report.pdf',
    );
  }
}

class TestLanguageStore implements LanguageStore {
  TestLanguageStore({this.code = 'en'});
  String? code;
  bool failWrites = false;
  @override
  Future<String?> read() async => code;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('Storage unavailable');
    code = value;
  }
}
