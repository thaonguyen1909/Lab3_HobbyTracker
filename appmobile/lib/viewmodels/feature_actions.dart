import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/hobby_data.dart';
import '../models/schedule_draft.dart';
import '../services/app_services.dart';
import '../services/device_services.dart';
import '../services/hobby_repository.dart';
import 'data_providers.dart';

class FeatureActionState {
  const FeatureActionState({
    this.busy = false,
    this.error,
    this.message,
    this.progress = 0,
    this.receipt,
    this.pdf,
  });
  final bool busy;
  final String? error, message;
  final double progress;
  final UploadReceipt? receipt;
  final Uint8List? pdf;
}

class FeatureActions extends StateNotifier<FeatureActionState> {
  FeatureActions(
    this.uid,
    this.repository,
    this.device,
    this.exporter,
    this.uploader,
  ) : super(const FeatureActionState());
  final String? uid;
  final HobbyRepository repository;
  final DeviceServices device;
  final ReportExporter Function() exporter;
  final ReportUploader Function() uploader;
  static const uuid = Uuid();
  String get owner =>
      uid ?? (throw const DataFailure('Bạn cần đăng nhập lại.'));
  void clearFeedback() {
    if (!mounted || state.busy) return;
    state = FeatureActionState(
      pdf: state.pdf,
      receipt: state.receipt,
      progress: state.progress,
    );
  }

  Future<bool> run(
    Future<void> Function() action, {
    String? event,
    Map<String, Object> parameters = const {},
    String? success,
  }) async {
    if (!mounted || state.busy) return false;
    state = FeatureActionState(
      busy: true,
      pdf: state.pdf,
      receipt: state.receipt,
    );
    try {
      await action();
      if (!mounted) return false;
      if (event != null) await device.event(event, parameters);
      if (!mounted) return false;
      state = FeatureActionState(
        message: success,
        pdf: state.pdf,
        receipt: state.receipt,
        progress: state.progress,
      );
      return true;
    } catch (e, s) {
      await device.recordError(e, s, reason: event ?? 'feature_action');
      if (mounted) {
        state = FeatureActionState(
          error: e is DataFailure
              ? e.message
              : 'Không hoàn tất được thao tác. Bản nháp vẫn được giữ; hãy thử lại.',
          pdf: state.pdf,
          receipt: state.receipt,
        );
      }
      return false;
    }
  }

  Future<bool> saveHobby({
    String? id,
    required String name,
    required String description,
    required String icon,
    required String color,
    required String? priority,
  }) => run(
    () async {
      validateHobby(name, description, priority);
      await repository.saveHobby(
        owner,
        Hobby(
          id: id ?? uuid.v4(),
          name: name.trim(),
          description: description,
          icon: icon,
          color: color,
          priority: priority!,
        ),
      );
    },
    event: id == null ? 'create_hobby' : 'edit_hobby',
    parameters: {'priority': priority ?? 'missing'},
    success: 'Đã lưu sở thích.',
  );
  Future<bool> priority(Hobby hobby, String value) => run(
    () => repository.saveHobby(owner, hobby.withPriority(value)),
    event: 'change_priority',
    parameters: {'hobby_id': hobby.id, 'priority': value},
  );
  Future<bool> remove(Hobby hobby) => run(
    () => repository.removeHobby(owner, hobby),
    event: 'remove_hobby',
    parameters: {'hobby_id': hobby.id},
    success: 'Đã xóa sở thích; lịch sử luyện tập được giữ.',
  );
  Future<bool> plan({
    String? id,
    required String? hobbyId,
    required String title,
    required DateTime? startsAt,
    required int minutes,
    String? requestId,
    ScheduleRepeat repeat = ScheduleRepeat.none,
    DateTime? until,
  }) => run(
    () async {
      if (hobbyId == null || startsAt == null) {
        throw const DataFailure('Hãy chọn sở thích, ngày và giờ.');
      }
      final seed = requestId ?? id ?? uuid.v4();
      final dates = scheduleOccurrences(startsAt, repeat, until);
      final plans = [
        for (var i = 0; i < dates.length; i++)
          PracticePlan(
            id: id != null && repeat == ScheduleRepeat.none ? id : '${seed}_$i',
            hobbyId: hobbyId,
            title: title.trim(),
            startsAt: dates[i],
            minutes: minutes,
          ),
      ];
      for (final plan in plans) {
        validatePracticePlan(plan);
      }
      if (id != null && repeat == ScheduleRepeat.none) {
        await repository.savePlan(owner, plans.single);
      } else {
        await repository.createPlans(owner, plans);
      }
    },
    event: 'create_schedule',
    success: 'Đã lưu lịch.',
  );
  Future<bool> deletePlan(String id) =>
      run(() => repository.deletePlan(owner, id), event: 'delete_schedule');
  Future<bool> preferences(AppPreferences value) => run(
    () => repository.savePreferences(owner, value),
    event: 'save_settings',
    success: 'Đã lưu cài đặt.',
  );
  Future<bool> publish(String text, String topic) =>
      run(() => repository.publish(owner, text, topic), event: 'create_post');
  Future<bool> like(String post, bool value) => run(
    () => repository.like(owner, post, value),
    event: 'like_post',
    parameters: {'post_id': post},
  );
  Future<bool> comment(String post, String text, String draft) => run(
    () => repository.comment(owner, post, text, draft),
    event: 'send_comment',
  );
  Future<bool> group(String name, String topic, String description) =>
      run(() async {
        await repository.createGroup(owner, name, topic, description);
      }, event: 'create_group');
  Future<bool> join(String id) => run(
    () => repository.joinGroup(owner, id),
    event: 'join_group',
    parameters: {'group_id': id},
  );
  Future<bool> event(String title, String topic, DateTime startsAt) => run(
    () => repository.createEvent(owner, title, topic, startsAt),
    event: 'create_event',
  );
  Future<bool> rsvp(String id, bool value) => run(
    () => repository.rsvp(owner, id, value),
    event: 'rsvp',
    parameters: {'event_id': id, 'going': value ? 1 : 0},
  );
  Future<bool> addEvent(SocialEntry event, Hobby hobby) => run(
    () => repository.addEventToHome(owner, event, hobby),
    event: 'add_event_to_home',
    parameters: {'event_id': event.id},
  );
  Future<String?> chat(String other) async {
    String? id;
    final ok = await run(() async {
      id = await repository.directChat(owner, other);
    }, event: 'open_conversation');
    return ok ? id : null;
  }

  Future<bool> send(String id, bool group, String text, String draft) => run(
    () => repository.send(owner, id, group, text, draft),
    event: 'send_message',
  );
  Future<bool> openShortcut(String kind, String term) => run(
    () => device.shortcut(kind, term),
    event: 'open_shortcut',
    parameters: {'service': kind},
  );
  Future<bool> readNotification(InboxItem item) =>
      run(() => device.markRead(owner, item));
  Future<bool> notifications() => run(
    () async {
      final result = await device.requestNotifications(owner);
      if (mounted) {
        state = FeatureActionState(busy: true, message: result, pdf: state.pdf);
      }
    },
    event: 'notification_permission',
    success: 'Đã đăng ký thông báo trên thiết bị.',
  );
  Future<bool> exportReport(
    List<Hobby> hobbies,
    List<PracticeRecord> records,
  ) => run(
    () async {
      final bytes = await exporter().export(hobbies, records);
      if (mounted) state = FeatureActionState(busy: true, pdf: bytes);
    },
    event: 'export_report',
    parameters: {'record_count': records.length},
    success: 'Đã tạo PDF. Bạn có thể chia sẻ hoặc tải lên.',
  );
  Future<bool> shareReport() => run(() async {
    final bytes = state.pdf;
    if (bytes == null) throw const DataFailure('Hãy tạo PDF trước.');
    await device.share(bytes);
  }, event: 'share_report');
  Future<bool> uploadReport() => run(
    () async {
      final bytes = state.pdf;
      if (bytes == null) throw const DataFailure('Hãy tạo PDF trước.');
      final receipt = await uploader().upload(owner, bytes, (value) {
        if (mounted) {
          state = FeatureActionState(busy: true, pdf: bytes, progress: value);
        }
      });
      if (mounted) {
        state = FeatureActionState(
          busy: true,
          pdf: bytes,
          receipt: receipt,
          progress: 1,
        );
      }
    },
    event: 'upload_report',
    success: 'Đã tải PDF lên Cloud Storage.',
  );
  Future<bool> crashTest() => run(() => device.crashTest());
}

final featureActionsProvider =
    StateNotifierProvider.autoDispose<FeatureActions, FeatureActionState>(
      (ref) => FeatureActions(
        ref.watch(ownerIdProvider),
        ref.watch(repositoryProvider),
        ref.watch(deviceServicesProvider),
        () => ref.read(reportExporterProvider),
        () => ref.read(reportUploaderProvider),
      ),
    );
