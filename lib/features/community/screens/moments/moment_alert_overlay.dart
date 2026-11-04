import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../services/moment_alert_providers.dart';
import '../../../../viewmodels/data_providers.dart';
import '../../../../viewmodels/hyper_view_model.dart';
import '../../../../app/router/app_router.dart';
import 'moment_widgets.dart';

class MomentAlertOverlay extends ConsumerStatefulWidget {
  const MomentAlertOverlay({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<MomentAlertOverlay> createState() => _MomentAlertOverlayState();
}

class _MomentAlertOverlayState extends ConsumerState<MomentAlertOverlay>
    with WidgetsBindingObserver {
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (ref.read(ownerIdProvider) != null &&
        ref.read(momentAlertRepositoryProvider) != null) {
      ref
          .read(momentAlertControllerProvider.notifier)
          .contextChanged(
            active: _active,
            hyperRunning: ref.read(hyperProvider).running,
          );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(ownerIdProvider);
    if (uid == null || ref.watch(momentAlertRepositoryProvider) == null) {
      return widget.child;
    }
    final state = ref.watch(momentAlertControllerProvider);
    final hyper = ref.watch(hyperProvider).running;
    ref.listen(
      hyperProvider,
      (_, value) => ref
          .read(momentAlertControllerProvider.notifier)
          .contextChanged(active: _active, hyperRunning: value.running),
    );
    final popup = state.popup;
    return Stack(
      children: [
        widget.child,
        if (_active && !hyper && popup != null)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                key: const ValueKey('moment-popup'),
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(child: AppText('New group moment')),
                          IconButton(
                            onPressed: () => ref
                                .read(momentAlertControllerProvider.notifier)
                                .dismiss(),
                            icon: Icon(
                              Icons.close,
                              semanticLabel: context.tr('Dismiss'),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (popup.thumbnail != null)
                            SizedBox(
                              width: 72,
                              height: 60,
                              child: PrivateMomentPhoto(
                                bytes: popup.thumbnail!.bytes,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${popup.moment.authorName} · ${popup.moment.hobbyName}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (uid != ref.read(ownerIdProvider) ||
                                ref.read(hyperProvider).running) {
                              return;
                            }
                            unawaited(
                              ref
                                  .read(momentAlertRepositoryProvider)!
                                  .markRead(uid, popup.alert.eventId)
                                  .catchError((Object _) {}),
                            );
                            ref
                                .read(momentAlertControllerProvider.notifier)
                                .dismiss();
                            ref.read(appRouterProvider).go(popup.alert.path);
                          },
                          child: const AppText('View moment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_active && hyper && state.pending > 0)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: AppText('Moments are waiting in your inbox.'),
                      ),
                      Text('${state.pending}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
