import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../models/group_moment.dart';
import '../../../../services/moment_providers.dart';
import '../../../../viewmodels/data_providers.dart';
import '../../../../widgets/async_states.dart';
import '../../../../widgets/feature_widgets.dart';
import '../../../../widgets/hobby_button.dart';
import 'moment_widgets.dart';

class MomentViewerScreen extends ConsumerStatefulWidget {
  const MomentViewerScreen({
    super.key,
    required this.groupId,
    required this.momentId,
  });
  final String groupId, momentId;
  @override
  ConsumerState<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends ConsumerState<MomentViewerScreen>
    with WidgetsBindingObserver {
  Timer? _tick;
  MomentKey get _key => (groupId: widget.groupId, id: widget.momentId);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!validMomentId(widget.groupId) || !validMomentId(widget.momentId)) {
      return;
    }
    final vm = ref.read(momentViewerProvider(_key).notifier);
    if (state == AppLifecycleState.resumed) {
      unawaited(vm.load());
    } else {
      vm.suspend();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _retract() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText('Remove this moment?'),
        content: const AppText(
          'Group members will no longer be able to open this photo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText('Remove moment'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(momentViewerProvider(_key).notifier).retract();
      if (mounted) ref.invalidate(momentsListProvider(widget.groupId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!validMomentId(widget.groupId) || !validMomentId(widget.momentId)) {
      return const FeaturePage(
        title: 'Moment',
        screen: 'moment-viewer',
        back: RoutePaths.feed,
        child: MomentExpiredPanel(),
      );
    }
    final state = ref.watch(momentViewerProvider(_key));
    final clock = ref.watch(momentClockProvider);
    final expired =
        state.expired ||
        (state.moment != null && !state.moment!.expiresAt.isAfter(clock.now));
    return FeaturePage(
      title: 'Moment',
      screen: 'moment-viewer',
      back: RoutePaths.momentsForGroup(widget.groupId),
      child: expired
          ? const MomentExpiredPanel()
          : state.loading || state.retracting
          ? const LoadingState()
          : state.error != null
          ? MomentErrorPanel(
              message: state.error!,
              retry: () => ref.read(momentViewerProvider(_key).notifier).load(),
            )
          : state.moment == null || state.image == null
          ? const LoadingState(label: 'Rechecking moments…')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  state.moment!.authorName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(state.moment!.hobbyName),
                const SizedBox(height: 16),
                PrivateMomentPhoto(
                  key: ValueKey(
                    '${ref.watch(ownerIdProvider)}:${widget.momentId}',
                  ),
                  bytes: state.image!.bytes,
                ),
                if (state.moment!.caption.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(state.moment!.caption),
                ],
                const SizedBox(height: 16),
                MomentTimeLeft(
                  expiresAt: state.moment!.expiresAt,
                  now: clock.now,
                ),
                if (state.moment!.authorId == ref.watch(ownerIdProvider)) ...[
                  const SizedBox(height: 20),
                  HobbyButton(
                    label: 'Remove moment',
                    variant: HobbyButtonVariant.danger,
                    onPressed: _retract,
                  ),
                ],
              ],
            ),
    );
  }
}
