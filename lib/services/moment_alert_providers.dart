import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moment_alert.dart';
import '../viewmodels/moment_alert_controller.dart';
import '../viewmodels/data_providers.dart';
import 'moment_alert_repository.dart';
import 'moment_providers.dart';
import 'local_owner_store.dart';
import 'moment_local_retention.dart';

// Bootstrap supplies the live adapter. Test harnesses may omit this optional integration.
final momentAlertRepositoryProvider = Provider<MomentAlertRepository?>(
  (ref) => null,
);
final momentPushProvider = Provider<Stream<Map<String, dynamic>>>(
  (ref) => const Stream.empty(),
);
final momentAlertLocalStoreProvider = Provider<LocalOwnerStore>(
  (ref) => LocalOwnerStore(),
);
final momentAlertSettingsProvider =
    StreamProvider.autoDispose<MomentAlertSettings>((ref) {
      final uid = ref.watch(ownerIdProvider),
          repo = ref.watch(momentAlertRepositoryProvider);
      return uid == null || repo == null
          ? Stream.value(const MomentAlertSettings())
          : repo.settings(uid);
    });
final momentMutedGroupsProvider = StreamProvider.autoDispose<Set<String>>((
  ref,
) {
  final uid = ref.watch(ownerIdProvider),
      repo = ref.watch(momentAlertRepositoryProvider);
  return uid == null || repo == null ? Stream.value({}) : repo.mutedGroups(uid);
});
final momentInboxProvider = StreamProvider.autoDispose<List<MomentAlert>>((
  ref,
) {
  final uid = ref.watch(ownerIdProvider),
      repo = ref.watch(momentAlertRepositoryProvider);
  return uid == null || repo == null ? Stream.value([]) : repo.inbox(uid);
});
final momentAlertControllerProvider =
    StateNotifierProvider.autoDispose<MomentAlertController, MomentAlertState>((
      ref,
    ) {
      final uid = ref.watch(ownerIdProvider) ?? '';
      final repo = ref.watch(momentAlertRepositoryProvider)!;
      final local = ref.watch(momentAlertLocalStoreProvider);
      final vm = MomentAlertController(
        uid,
        ref.watch(momentRepositoryProvider),
        repo,
        ref.watch(momentClockProvider),
        isOwner: () => ref.read(ownerIdProvider) == uid,
        wasSeen: (event) async =>
            await local.prefs.getBool(
              '${local.prefix(uid)}moment_seen_$event',
            ) ==
            true,
        remember: (event) async {
          final retention = MomentLocalRetention(local);
          await retention.prune(uid);
          await retention.remember(uid, event);
        },
      );
      void configure() {
        vm.configure(
          enabled:
              ref.read(momentAlertSettingsProvider).valueOrNull?.enabled ??
              false,
          groupsEnabled:
              ref.read(preferencesProvider).valueOrNull?.groups ?? false,
          muted: ref.read(momentMutedGroupsProvider).valueOrNull ?? {},
        );
        Future.microtask(() {
          if (vm.mounted) {
            for (final alert
                in ref.read(momentInboxProvider).valueOrNull ??
                    <MomentAlert>[]) {
              vm.receive(alert);
            }
          }
        });
      }

      ref.listen(
        momentAlertSettingsProvider,
        (_, _) => configure(),
        fireImmediately: true,
      );
      ref.listen(
        momentMutedGroupsProvider,
        (_, _) => configure(),
        fireImmediately: true,
      );
      ref.listen(
        preferencesProvider,
        (_, _) => configure(),
        fireImmediately: true,
      );
      ref.listen(momentInboxProvider, (_, next) {
        Future.microtask(() {
          if (vm.mounted) {
            for (final item in next.valueOrNull ?? <MomentAlert>[]) {
              vm.receive(item);
            }
          }
        });
      }, fireImmediately: true);
      final subscription = ref.watch(momentPushProvider).listen((data) {
        if (data['kind'] != 'moment' || data['ownerId'] != uid) return;
        final alert = MomentAlert.parse(data);
        if (alert != null) vm.receive(alert);
      });
      ref.onDispose(() => unawaited(subscription.cancel()));
      return vm;
    });
