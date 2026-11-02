import '../models/hobby_data.dart';

/// Domain data boundary. Only the Firebase adapter knows paths, queries and SDK types.
abstract class HobbyRepository {
  Stream<List<Hobby>> hobbies(String uid);
  Future<void> saveHobby(String uid, Hobby hobby);
  Future<void> removeHobby(String uid, Hobby hobby);
  Stream<List<PracticePlan>> plans(String uid);
  Future<void> savePlan(String uid, PracticePlan plan);
  Future<void> deletePlan(String uid, String id);
  Stream<List<PracticeRecord>> history(String uid);
  Future<void> finish(String uid, PracticeRecord record);
  Stream<AppPreferences> preferences(String uid);
  Future<void> savePreferences(String uid, AppPreferences value);
  Stream<List<SocialEntry>> feed(int limit);
  Future<void> publish(String uid, String text, String topic);
  Stream<List<SocialEntry>> likes(String postId);
  Future<void> like(String uid, String postId, bool value);
  Stream<List<SocialEntry>> comments(String postId);
  Future<void> comment(String uid, String postId, String text, String draftId);
  Stream<List<SocialEntry>> groups();
  Stream<List<SocialEntry>> joinedGroups(String uid);
  Future<String> createGroup(
    String uid,
    String name,
    String topic,
    String description,
  );
  Future<void> joinGroup(String uid, String groupId);
  Stream<List<SocialEntry>> events();
  Future<void> createEvent(
    String uid,
    String title,
    String topic,
    DateTime startsAt,
  );
  Stream<List<SocialEntry>> rsvps(String uid);
  Future<void> rsvp(String uid, String eventId, bool going);
  Future<void> addEventToHome(String uid, SocialEntry event, Hobby hobby);
  Stream<List<SocialEntry>> people();
  Future<String> directChat(String uid, String otherUid);
  Stream<List<SocialEntry>> chats(String uid);
  Stream<List<SocialEntry>> messages(String uid, String id, bool group);
  Future<void> send(
    String uid,
    String id,
    bool group,
    String text,
    String draftId,
  );
}
