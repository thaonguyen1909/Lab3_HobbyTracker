import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../models/moment_alert.dart';
import '../../../../models/hobby_data.dart';
import '../../../../services/moment_alert_providers.dart';
import '../../../../services/app_services.dart';
import '../../../../viewmodels/data_providers.dart';
import '../../../../viewmodels/hyper_view_model.dart';
import '../../../../widgets/feature_widgets.dart';
import '../../../../widgets/hobby_button.dart';

class MomentAlertsScreen extends ConsumerStatefulWidget {
  const MomentAlertsScreen({super.key});
  @override
  ConsumerState<MomentAlertsScreen> createState() => _MomentAlertsScreenState();
}

class _MomentAlertsScreenState extends ConsumerState<MomentAlertsScreen> {
  bool busy = false;
  String? error;
  Future<void> run(Future<void> Function() work) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await work();
    } on DataFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not save moment notification settings. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(ownerIdProvider),
        repo = ref.watch(momentAlertRepositoryProvider);
    return FeaturePage(
      title: 'Moment notifications',
      screen: 'moment-alerts',
      back: RoutePaths.moments,
      child: uid == null || repo == null
          ? const SizedBox.shrink()
          : AsyncPanel(
              value: ref.watch(momentAlertSettingsProvider),
              retry: () => ref.invalidate(momentAlertSettingsProvider),
              builder: (settings) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppText(
                    'Enable moment alerts to see photos shared by your groups. You can still browse moments when alerts are off.',
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const AppText('Moment alerts'),
                    value: settings.enabled,
                    onChanged: busy
                        ? null
                        : (value) => run(
                            () => repo.saveSettings(
                              uid,
                              MomentAlertSettings(
                                enabled: value,
                                previewOnLockScreen:
                                    settings.previewOnLockScreen,
                              ),
                            ),
                          ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const AppText('Show photos on lock screen'),
                    subtitle: const AppText(
                      'Android lock screen settings also apply.',
                    ),
                    value: settings.previewOnLockScreen,
                    onChanged: busy
                        ? null
                        : (value) => run(
                            () => repo.saveSettings(
                              uid,
                              MomentAlertSettings(
                                enabled: settings.enabled,
                                previewOnLockScreen: value,
                              ),
                            ),
                          ),
                  ),
                  HobbyButton(
                    label: 'Allow Android notifications',
                    variant: HobbyButtonVariant.outline,
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            await ref
                                .read(deviceServicesProvider)
                                .requestNotifications(uid);
                          }),
                  ),
                  if (busy) const LinearProgressIndicator(),
                  if (error != null)
                    AppText(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  const AppText('Muted groups'),
                  AsyncPanel(
                    value: ref.watch(joinedGroupsProvider),
                    retry: () => ref.invalidate(joinedGroupsProvider),
                    builder: (groups) {
                      final muted = ref.watch(momentMutedGroupsProvider);
                      return AsyncPanel(
                        value: muted,
                        retry: () => ref.invalidate(momentMutedGroupsProvider),
                        builder: (ids) => Column(
                          children: [
                            for (final group in groups)
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(group.text('name')),
                                value: ids.contains(group.id),
                                onChanged: busy
                                    ? null
                                    : (value) => run(
                                        () => repo.mute(uid, group.id, value),
                                      ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const AppText('Moment inbox'),
                  if (ref.watch(hyperProvider).running)
                    const AppText(
                      'Finish or pause Hyper Mode before opening a moment.',
                    ),
                  AsyncPanel(
                    value: ref.watch(momentInboxProvider),
                    retry: () => ref.invalidate(momentInboxProvider),
                    builder: (items) => Column(
                      children: [
                        if (items.isEmpty)
                          const AppText('No moment alerts yet.'),
                        for (final alert in items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              alert.read
                                  ? Icons.photo_outlined
                                  : Icons.mark_email_unread_outlined,
                            ),
                            title: const AppText('Group moment'),
                            subtitle: const AppText(
                              'Open to check availability.',
                            ),
                            onTap: ref.watch(hyperProvider).running
                                ? null
                                : () {
                                    unawaited(
                                      repo
                                          .markRead(uid, alert.eventId)
                                          .catchError((Object _) {}),
                                    );
                                    context.go(alert.path);
                                  },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
