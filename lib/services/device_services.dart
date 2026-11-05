import 'dart:typed_data';
import '../models/hobby_data.dart';

abstract class ReportExporter {
  Future<Uint8List> export(List<Hobby> hobbies, List<PracticeRecord> history);
}

class UploadReceipt {
  const UploadReceipt(this.path, this.url);
  final String path, url;
}

abstract class ReportUploader {
  Future<UploadReceipt> upload(
    String uid,
    Uint8List bytes,
    void Function(double) progress,
  );
}

abstract class DeviceServices {
  Stream<String> get diagnostics;
  Future<void> setOwner(String? uid);
  Future<void> endSession(String? uid);
  Future<void> event(String name, Map<String, Object> parameters);
  Future<void> screen(String name);
  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String reason = 'handled',
    bool fatal = false,
  });
  Future<RuntimeFlags> flags();
  Future<String> requestNotifications(String uid);
  Stream<List<InboxItem>> inbox(String uid);
  Future<void> markRead(String uid, InboxItem item);
  Stream<String> get notificationOpens;
  Future<Map<String, dynamic>?> readDraft(String uid);
  Future<void> writeDraft(String uid, Map<String, dynamic>? draft);
  Future<void> share(Uint8List bytes);
  Future<void> shortcut(String kind, String term);
  Future<void> syncReminders(
    String uid,
    List<PracticePlan> plans,
    List<PracticeRecord> history,
    AppPreferences preferences,
  );
  Future<void> feedback();
  Future<void> crashTest();
}
