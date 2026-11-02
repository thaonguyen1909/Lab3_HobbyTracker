import '../l10n/language_controller.dart';
import 'dart:async';
import '../models/hobby_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_services.dart';
import '../services/app_services.dart';
import '../app/router/app_router.dart';
import 'data_providers.dart';
import 'auth_view_model.dart';

class RuntimeController {
  RuntimeController(this.device, this.navigate) {
    _opens = device.notificationOpens.listen(navigate);
  }
  final DeviceServices device;
  final void Function(String) navigate;
  StreamSubscription<String>? _opens;
  String? _owner;
  void Function()? onOwnerReady;
  bool disposed = false;
  Future<void> _pending = Future.value();
  void owner(String? uid) {
    _pending = _pending
        .then((_) async {
          if (disposed) return;
          if (_owner != null && uid != _owner) {
            await device.event('logout', const {});
          }
          await device.setOwner(uid);
          if (uid != null && uid != _owner) {
            await device.event('login', {'method': 'firebase'});
          }
          _owner = uid;
          onOwnerReady?.call();
        })
        .catchError((Object _) {});
  }

  void screen(String name) {
    unawaited(device.screen(name));
    if (['detail', 'conversation', 'settings-detail', 'hyper'].contains(name)) {
      unawaited(device.event('open_detail', {'screen': name}));
    }
  }

  void reminders(
    String uid,
    List<PracticePlan> plans,
    List<PracticeRecord> history,
    AppPreferences p,
  ) {
    unawaited(device.syncReminders(uid, plans, history, p));
  }

  void dispose() {
    disposed = true;
    unawaited(_opens?.cancel());
  }
}

final runtimeControllerProvider = Provider<RuntimeController>((ref) {
  String? pendingOpen;
  void openWhenReady(String path) {
    final session = ref.read(authSessionProvider);
    if (!session.isLoading &&
        !session.hasError &&
        session.valueOrNull != null) {
      ref.read(appRouterProvider).go(path);
    } else {
      pendingOpen = path;
    }
  }

  final c = RuntimeController(ref.watch(deviceServicesProvider), openWhenReady);
  // Initial auth loading is not signed out. Do not erase the persisted owner
  // and timer draft before Firebase emits its initial restored identity.
  ref.listen(authIdentityProvider, (_, value) {
    if (!value.isLoading && !value.hasError) c.owner(value.valueOrNull?.uid);
  }, fireImmediately: true);
  ref.listen(authSessionProvider, (_, value) {
    if (!value.isLoading && !value.hasError) {
      if (value.valueOrNull == null) {
        pendingOpen = null;
      } else if (pendingOpen != null) {
        final path = pendingOpen!;
        pendingOpen = null;
        ref.read(appRouterProvider).go(path);
      }
    }
  });
  void sync() {
    final uid = ref.read(ownerIdProvider);
    final plans = ref.read(plansProvider),
        history = ref.read(historyProvider),
        prefs = ref.read(preferencesProvider),
        hobbies = ref.read(hobbiesProvider);
    if (uid != null &&
        plans.hasValue &&
        history.hasValue &&
        prefs.hasValue &&
        hobbies.hasValue) {
      final ids = hobbies.value!.map((h) => h.id).toSet();
      c.reminders(
        uid,
        plans.value!.where((p) => ids.contains(p.hobbyId)).toList(),
        history.value!,
        prefs.value!,
      );
    }
  }

  ref.listen(languageProvider, (previous, next) {
    if (previous?.code != next.code) sync();
  });
  c.onOwnerReady = sync;
  ref.listen(plansProvider, (_, next) => sync());
  ref.listen(historyProvider, (_, next) => sync());
  ref.listen(preferencesProvider, (_, next) => sync());
  ref.listen(hobbiesProvider, (_, next) => sync());
  ref.onDispose(c.dispose);
  return c;
});
