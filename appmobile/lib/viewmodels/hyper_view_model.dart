import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/hobby_data.dart';
import '../services/hobby_repository.dart';
import '../services/device_services.dart';
import '../services/app_services.dart';
import 'data_providers.dart';

abstract class ActiveClock {
  int get milliseconds;
  void start();
  void stop();
  void reset();
}

class StopwatchClock implements ActiveClock {
  final _watch = Stopwatch();
  @override
  int get milliseconds => _watch.elapsedMilliseconds;
  @override
  void start() => _watch.start();
  @override
  void stop() => _watch.stop();
  @override
  void reset() => _watch.reset();
}

class HyperState {
  const HyperState({
    this.sessionId = '',
    this.hobbyId = '',
    this.planId = '',
    this.elapsedMs = 0,
    this.notes = '',
    this.running = false,
    this.saving = false,
    this.finished = false,
    this.restoring = false,
    this.error,
  });
  final String sessionId, hobbyId, planId, notes;
  final int elapsedMs;
  final bool running, saving, finished, restoring;
  final String? error;
  HyperState copy({
    String? sessionId,
    String? hobbyId,
    String? planId,
    int? elapsedMs,
    String? notes,
    bool? running,
    bool? saving,
    bool? finished,
    bool? restoring,
    String? error,
  }) => HyperState(
    sessionId: sessionId ?? this.sessionId,
    hobbyId: hobbyId ?? this.hobbyId,
    planId: planId ?? this.planId,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    notes: notes ?? this.notes,
    running: running ?? this.running,
    saving: saving ?? this.saving,
    finished: finished ?? this.finished,
    restoring: restoring ?? this.restoring,
    error: error,
  );
  Json toJson() => {
    'sessionId': sessionId,
    'hobbyId': hobbyId,
    'planId': planId,
    'elapsedMs': elapsedMs,
    'notes': notes,
  };
}

class HyperViewModel extends StateNotifier<HyperState> {
  HyperViewModel(
    this.uid,
    this.repository,
    this.device, {
    ActiveClock? clock,
    this.tick = true,
  }) : clock = clock ?? StopwatchClock(),
       super(const HyperState());
  final bool tick;
  void _startTicker() {
    if (!tick || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (state.running) {
        state = state.copy(elapsedMs: _banked + clock.milliseconds);
        if (state.elapsedMs - _lastSaved >= 5000) {
          _lastSaved = state.elapsedMs;
          unawaited(persist());
        }
      }
    });
  }

  final String uid;
  final HobbyRepository repository;
  final DeviceServices device;
  final ActiveClock clock;
  Timer? _timer;
  int _banked = 0, _lastSaved = 0;
  Future<void> _persistence = Future.value();
  Future<void> restore() async {
    state = state.copy(restoring: true);
    try {
      final j = await device.readDraft(uid);
      if (!mounted) return;
      if (state.hobbyId.isNotEmpty || j == null) {
        state = state.copy(restoring: false);
        return;
      }
      _banked = (j['elapsedMs'] as int? ?? 0).clamp(0, 86400000);
      state = HyperState(
        sessionId: j['sessionId'] as String? ?? const Uuid().v4(),
        hobbyId: j['hobbyId'] as String? ?? '',
        planId: j['planId'] as String? ?? '',
        elapsedMs: _banked,
        notes: j['notes'] as String? ?? '',
      );
    } catch (_) {
      if (mounted) {
        state = state.copy(
          restoring: false,
          error: 'Không đọc được bản nháp cục bộ.',
        );
      }
    }
  }

  bool select(Hobby hobby, {String planId = '', bool discard = false}) {
    if (state.saving || state.restoring) return false;
    if (state.hobbyId == hobby.id &&
        state.planId == planId &&
        !state.finished) {
      return true;
    }
    if (state.hobbyId.isNotEmpty &&
        !state.finished &&
        (state.running || state.elapsedMs > 0 || state.notes.isNotEmpty) &&
        !discard) {
      state = state.copy(
        error:
            'Hãy hoàn tất hoặc xác nhận bỏ phiên hiện tại trước khi đổi sở thích hoặc lịch.',
      );
      return false;
    }
    clock.stop();
    clock.reset();
    _banked = 0;
    _lastSaved = 0;
    state = HyperState(
      sessionId: const Uuid().v4(),
      hobbyId: hobby.id,
      planId: planId,
    );
    unawaited(persist());
    return true;
  }

  void start() {
    if (state.hobbyId.isEmpty ||
        state.saving ||
        state.finished ||
        state.restoring) {
      return;
    }
    clock.start();
    _startTicker();
    state = state.copy(running: true);
  }

  void pause() {
    if (!state.running) return;
    _timer?.cancel();
    _timer = null;
    clock.stop();
    _banked += clock.milliseconds;
    clock.reset();
    state = state.copy(running: false, elapsedMs: _banked);
    unawaited(persist());
  }

  void notes(String value) {
    if (!state.saving && !state.finished) {
      state = state.copy(notes: value);
      unawaited(persist());
    }
  }

  void reset() {
    if (state.saving) return;
    _timer?.cancel();
    _timer = null;
    clock.stop();
    clock.reset();
    _banked = 0;
    state = state.copy(elapsedMs: 0, running: false);
    unawaited(persist());
  }

  void onBackground(bool pauseOnExit) {
    if (pauseOnExit) {
      pause();
    } else {
      unawaited(persist());
    }
  }

  Future<void> persist() {
    if (state.hobbyId.isEmpty || state.finished) return Future.value();
    final snapshot = state
        .copy(elapsedMs: _banked + clock.milliseconds)
        .toJson();
    _persistence = _persistence
        .then((_) => device.writeDraft(uid, snapshot))
        .catchError((Object error) {
          if (mounted) {
            state = state.copy(error: 'Chưa lưu được bản nháp trên thiết bị.');
          }
        });
    return _persistence;
  }

  Future<bool> finish(Hobby hobby, {bool sound = false}) async {
    if (state.saving || state.finished || state.hobbyId != hobby.id) {
      return false;
    }
    pause();
    if (state.notes.runes.length > 2000 || state.elapsedMs > 86400000) {
      state = state.copy(
        error: 'Phiên tối đa 24 giờ; ghi chú tối đa 2000 ký tự.',
      );
      return false;
    }
    state = state.copy(saving: true);
    try {
      await repository.finish(
        uid,
        PracticeRecord(
          id: state.sessionId,
          hobbyId: hobby.id,
          name: hobby.name,
          icon: hobby.icon,
          color: hobby.color,
          elapsedMs: state.elapsedMs,
          notes: state.notes,
          finishedAt: DateTime.now(),
          planId: state.planId,
        ),
      );
      if (sound) await device.feedback();
      await device.event('finish_session', {
        'hobby_id': hobby.id,
        'elapsed_seconds': state.elapsedMs ~/ 1000,
      });
      await _persistence;
      await device.writeDraft(uid, null);
      if (!mounted) return true;
      state = state.copy(saving: false, finished: true);
      return true;
    } catch (e, s) {
      await device.recordError(e, s, reason: 'finish_session');
      if (mounted) {
        state = state.copy(
          saving: false,
          error: e is DataFailure
              ? e.message
              : 'Chưa lưu được phiên. Hãy thử lại; bản nháp vẫn được giữ.',
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    clock.stop();
    super.dispose();
  }
}

final hyperProvider = StateNotifierProvider<HyperViewModel, HyperState>((ref) {
  final uid = ref.watch(ownerIdProvider) ?? '';
  final vm = HyperViewModel(
    uid,
    ref.watch(repositoryProvider),
    ref.watch(deviceServicesProvider),
  );
  unawaited(vm.restore());
  return vm;
});
