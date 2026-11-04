import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../models/group_moment.dart';
import '../../../../services/moment_providers.dart';
import '../../../../services/moment_alert_providers.dart';
import '../../../../viewmodels/data_providers.dart';
import '../../../../widgets/async_states.dart';
import '../../../../widgets/feature_widgets.dart';
import '../../../../widgets/hobby_button.dart';
import '../../../../widgets/hobby_card.dart';
import 'moment_widgets.dart';

class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key, this.groupId});
  final String? groupId;
  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen>
    with WidgetsBindingObserver {
  String? _selected;
  Timer? _tick;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    _selected = widget.groupId;
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _active) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    final groupId = _selected;
    if (resumed == _active) return;
    _active = resumed;
    if (groupId != null) {
      final vm = ref.read(momentsListProvider(groupId).notifier);
      if (resumed) {
        unawaited(vm.refresh());
      } else {
        vm.suspend();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(ownerIdProvider);
    final groups = ref.watch(joinedGroupsProvider);
    return FeaturePage(
      title: 'Moments',
      screen: 'moments',
      back: RoutePaths.feed,
      child: groups.when(
        loading: () => const LoadingState(),
        error: (_, _) => MomentErrorPanel(
          message: 'Could not load your groups.',
          retry: () => ref.invalidate(joinedGroupsProvider),
        ),
        data: (items) {
          if (uid == null || items.isEmpty) {
            return EmptyState(
              title: 'Join a group to share moments',
              description:
                  'Only members of the selected group can view its moments.',
              actionLabel: 'Find groups',
              onAction: () => context.go(RoutePaths.groups),
            );
          }
          final selected = items.any((group) => group.id == _selected)
              ? _selected!
              : items.first.id;
          _selected = selected;
          final state = ref.watch(momentsListProvider(selected));
          final clock = ref.watch(momentClockProvider);
          final live = state.items
              .where((item) => item.expiresAt.isAfter(clock.now))
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText(
                'Moments last for 3 hours. Share what you are practicing.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              HobbyButton(
                label: 'Moment notifications',
                icon: Icons.notifications_outlined,
                variant: HobbyButtonVariant.outline,
                onPressed: () => context.push(RoutePaths.momentAlerts),
              ),
              if ((ref
                          .watch(momentInboxProvider)
                          .valueOrNull
                          ?.where((item) => !item.read)
                          .length ??
                      0) >
                  0)
                const AppText('New moments in your inbox'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('moment-group-$uid-$selected'),
                initialValue: selected,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('Group')),
                items: [
                  for (final group in items)
                    DropdownMenuItem(
                      value: group.id,
                      child: Text(
                        group.text('name'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
              ),
              const SizedBox(height: 16),
              HobbyButton(
                key: const ValueKey('create-moment'),
                label: 'Share a moment',
                icon: Icons.add_a_photo_outlined,
                expand: true,
                onPressed: () =>
                    context.push(RoutePaths.createMoment(selected)),
              ),
              const SizedBox(height: 12),
              HobbyButton(
                label: 'Refresh moments',
                variant: HobbyButtonVariant.outline,
                onPressed: state.loading
                    ? null
                    : () => ref
                          .read(momentsListProvider(selected).notifier)
                          .refresh(),
              ),
              const SizedBox(height: 20),
              if (!_active)
                const LoadingState(label: 'Rechecking moments…')
              else ...[
                if (state.error != null)
                  MomentErrorPanel(
                    message: state.error!,
                    retry: () => ref
                        .read(momentsListProvider(selected).notifier)
                        .refresh(),
                  ),
                if (state.loading && live.isEmpty) const LoadingState(),
                if (!state.loading && state.error == null && live.isEmpty)
                  const EmptyState(
                    title: 'No live moments yet',
                    description:
                        'Share the first photo with your group. It will disappear after 3 hours.',
                  ),
                for (final moment in live)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MomentCard(
                      key: ValueKey('$uid:${moment.id}'),
                      moment: moment,
                      now: clock.now,
                    ),
                  ),
                if (state.nextCursor != null)
                  HobbyButton(
                    label: 'Load more moments',
                    isLoading: state.loading,
                    onPressed: state.loading
                        ? null
                        : () => ref
                              .read(momentsListProvider(selected).notifier)
                              .more(),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MomentCard extends ConsumerWidget {
  const _MomentCard({super.key, required this.moment, required this.now});
  final GroupMoment moment;
  final DateTime now;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (groupId: moment.groupId, id: moment.id);
    final image = ref.watch(momentThumbnailProvider(key));
    return HobbyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            moment.authorName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(moment.hobbyName),
          const SizedBox(height: 12),
          image.when(
            data: (value) => PrivateMomentPhoto(bytes: value.bytes),
            loading: () => const AspectRatio(
              aspectRatio: 4 / 3,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => HobbyButton(
              label: 'Retry photo',
              variant: HobbyButtonVariant.outline,
              onPressed: () => ref.invalidate(momentThumbnailProvider(key)),
            ),
          ),
          if (moment.caption.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(moment.caption),
          ],
          const SizedBox(height: 12),
          MomentTimeLeft(expiresAt: moment.expiresAt, now: now),
          const SizedBox(height: 12),
          HobbyButton(
            label: 'View moment',
            onPressed: () =>
                context.push(RoutePaths.groupMoment(moment.groupId, moment.id)),
          ),
        ],
      ),
    );
  }
}
