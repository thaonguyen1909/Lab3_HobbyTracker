import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_moment.dart';
import '../models/moment_alert.dart';
import '../services/moment_repository.dart';
import '../services/moment_alert_repository.dart';

class MomentAlertState {
  const MomentAlertState({this.popup, this.pending = 0});
  final MomentPopup? popup;
  final int pending;
}

/// Serial verification, bounded queue, one banner and no timers/navigation in domain actions.
class MomentAlertController extends StateNotifier<MomentAlertState> {
  MomentAlertController(
    this.uid,
    this.repository,
    this.alerts,
    this.clock, {
    required this.isOwner,
    required this.wasSeen,
    required this.remember,
  }) : super(const MomentAlertState());
  final String uid;
  final MomentRepository repository;
  final MomentAlertRepository alerts;
  final MomentClock clock;
  final bool Function() isOwner;
  final Future<bool> Function(String) wasSeen;
  final Future<void> Function(String) remember;
  final _queue = <MomentAlert>[];
  final _seen = <String>{};
  bool active = true,
      hyperRunning = false,
      enabled = false,
      groupsEnabled = true;
  Set<String> muted = {};
  Future<void> _work = Future.value();
  Timer? _hide;
  int _revision = 0;

  void configure({
    required bool enabled,
    required bool groupsEnabled,
    required Set<String> muted,
  }) {
    this.enabled = enabled;
    this.groupsEnabled = groupsEnabled;
    this.muted = muted;
    if (!enabled || !groupsEnabled) _queue.clear();
    if (!enabled ||
        !groupsEnabled ||
        (state.popup != null && muted.contains(state.popup!.alert.groupId))) {
      dismiss();
    }
    _queue.removeWhere((item) => muted.contains(item.groupId));
    if (mounted) {
      state = MomentAlertState(popup: state.popup, pending: _queue.length);
    }
    if (enabled && groupsEnabled) _drain();
  }

  void contextChanged({required bool active, required bool hyperRunning}) {
    this.active = active;
    this.hyperRunning = hyperRunning;
    if (!active || hyperRunning) {
      final popup = state.popup;
      if (popup != null &&
          _queue.every((a) => a.eventId != popup.alert.eventId)) {
        _queue.insert(0, popup.alert);
      }
      _revision++;
      _hide?.cancel();
      state = MomentAlertState(pending: _queue.length);
    } else {
      _drain();
    }
  }

  void receive(MomentAlert alert) {
    if (!mounted ||
        !isOwner() ||
        !enabled ||
        !groupsEnabled ||
        muted.contains(alert.groupId) ||
        alert.read ||
        _seen.contains(alert.eventId) ||
        _queue.any((a) => a.eventId == alert.eventId)) {
      return;
    }
    if (_queue.length >= 20) _queue.removeLast();
    _queue.add(alert);
    state = MomentAlertState(popup: state.popup, pending: _queue.length);
    _drain();
  }

  void _drain() {
    _work = _work
        .then((_) async {
          if (!mounted ||
              !active ||
              hyperRunning ||
              !enabled ||
              !groupsEnabled ||
              state.popup != null ||
              !isOwner()) {
            return;
          }
          while (_queue.isNotEmpty && mounted && active && !hyperRunning) {
            final alert = _queue.removeAt(0), revision = _revision;
            if (muted.contains(alert.groupId) || await wasSeen(alert.eventId)) {
              continue;
            }
            try {
              if (!await alerts.allowed(uid, alert.groupId)) continue;
              final detail = await repository.get(
                uid,
                alert.groupId,
                alert.momentId,
              );
              clock.sync(detail.serverNow, detail.roundTrip);
              if (detail.moment.authorId == uid ||
                  !detail.moment.expiresAt.isAfter(clock.now)) {
                continue;
              }
              MomentImage? image;
              try {
                image = await repository.image(
                  uid,
                  alert.groupId,
                  alert.momentId,
                  thumbnail: true,
                );
                clock.sync(image.serverNow, image.roundTrip);
              } on MomentFailure catch (e) {
                if (![
                  'unavailable',
                  'deadline-exceeded',
                  'resource-exhausted',
                ].contains(e.code)) {
                  rethrow;
                }
                if (image == null) {
                  final fresh = await repository.get(
                    uid,
                    alert.groupId,
                    alert.momentId,
                  );
                  clock.sync(fresh.serverNow, fresh.roundTrip);
                }
                if (!await alerts.allowed(uid, alert.groupId)) continue;
              }
              if (!mounted ||
                  !isOwner() ||
                  !enabled ||
                  !groupsEnabled ||
                  muted.contains(alert.groupId)) {
                return;
              }
              if (!active || hyperRunning || revision != _revision) {
                _queue.insert(0, alert);
                return;
              }
              if (!detail.moment.expiresAt.isAfter(clock.now) ||
                  (image != null && !image.expiresAt.isAfter(clock.now))) {
                continue;
              }
              await remember(alert.eventId);
              if (!mounted ||
                  !isOwner() ||
                  !active ||
                  hyperRunning ||
                  revision != _revision ||
                  !detail.moment.expiresAt.isAfter(clock.now) ||
                  (image != null && !image.expiresAt.isAfter(clock.now))) {
                return;
              }
              _seen.add(alert.eventId);
              state = MomentAlertState(
                popup: MomentPopup(alert, detail.moment, image),
                pending: _queue.length,
              );
              final remaining = detail.moment.expiresAt.difference(clock.now);
              _hide?.cancel();
              _hide = Timer(
                remaining < const Duration(seconds: 6)
                    ? remaining
                    : const Duration(seconds: 6),
                dismiss,
              );
              return;
            } catch (_) {
              /* The durable inbox remains available to open/retry. */
            }
          }
          if (mounted) state = MomentAlertState(pending: _queue.length);
        })
        .catchError((Object _) {});
  }

  void dismiss() {
    if (!mounted) return;
    _revision++;
    _hide?.cancel();
    state = MomentAlertState(pending: _queue.length);
    if (enabled && groupsEnabled) _drain();
  }

  @override
  void dispose() {
    _revision++;
    _hide?.cancel();
    _queue.clear();
    super.dispose();
  }
}
