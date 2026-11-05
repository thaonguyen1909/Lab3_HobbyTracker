import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../l10n/app_strings.dart';
import '../../../../models/group_moment.dart';
import '../../../../models/hobby_data.dart';
import '../../../../services/moment_providers.dart';
import '../../../../viewmodels/data_providers.dart';
import '../../../../widgets/async_states.dart';
import '../../../../widgets/feature_widgets.dart';
import '../../../../widgets/hobby_button.dart';
import '../../../../widgets/hobby_text_field.dart';
import 'moment_widgets.dart';

class MomentComposerScreen extends ConsumerWidget {
  const MomentComposerScreen({super.key, required this.groupId});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!validMomentId(groupId)) {
      return const FeaturePage(
        title: 'Share a moment',
        screen: 'moment-create',
        child: MomentExpiredPanel(),
      );
    }
    final state = ref.watch(momentComposerProvider(groupId));
    ref.listen(momentComposerProvider(groupId), (previous, next) {
      if (previous?.posted == null && next.posted != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref.invalidate(momentsListProvider(groupId));
          context.go(RoutePaths.momentsForGroup(groupId));
        });
      }
    });
    return PopScope(
      canPop: !state.busy,
      child: FeaturePage(
        title: 'Share a moment',
        screen: 'moment-create',
        back: RoutePaths.momentsForGroup(groupId),
        child: state.restoring
            ? const LoadingState()
            : _MomentForm(
                key: ValueKey('${ref.watch(ownerIdProvider)}:$groupId'),
                groupId: groupId,
              ),
      ),
    );
  }
}

class _MomentForm extends ConsumerStatefulWidget {
  const _MomentForm({super.key, required this.groupId});
  final String groupId;
  @override
  ConsumerState<_MomentForm> createState() => _MomentFormState();
}

class _MomentFormState extends ConsumerState<_MomentForm> {
  late final TextEditingController _caption;
  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(
      text: ref.read(momentComposerProvider(widget.groupId)).draft.caption,
    );
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(momentComposerProvider(widget.groupId));
    final vm = ref.read(momentComposerProvider(widget.groupId).notifier);
    final enabled = !state.busy && !state.uncertain;
    return AsyncPanel(
      value: ref.watch(joinedGroupsProvider),
      retry: () => ref.invalidate(joinedGroupsProvider),
      builder: (groups) {
        final group = groups
            .where((item) => item.id == widget.groupId)
            .firstOrNull;
        if (group == null) return const MomentExpiredPanel();
        return AsyncPanel(
          value: ref.watch(hobbiesProvider),
          retry: () => ref.invalidate(hobbiesProvider),
          builder: (hobbies) {
            if (hobbies.isEmpty) {
              return EmptyState(
                title: 'Create a hobby before sharing',
                description:
                    'Your moment must be linked to a hobby from your collection.',
                actionLabel: 'My Hobbies',
                onAction: () => context.go(RoutePaths.hobbies),
              );
            }
            final selected =
                hobbies.any((hobby) => hobby.id == state.draft.hobbyId)
                ? state.draft.hobbyId
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppText('Sharing with this group'),
                Text(
                  group.text('name'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const AppText(
                  'Only group members can view this photo for 3 hours.',
                ),
                const SizedBox(height: 20),
                if (state.photo != null)
                  PrivateMomentPhoto(bytes: state.photo!.bytes)
                else
                  const AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Center(
                      child: Icon(Icons.add_photo_alternate_outlined, size: 64),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HobbyButton(
                      key: const ValueKey('moment-camera'),
                      label: 'Take photo',
                      icon: Icons.camera_alt_outlined,
                      variant: HobbyButtonVariant.secondary,
                      onPressed: enabled
                          ? () => vm.choosePhoto(MomentPhotoSource.camera)
                          : null,
                    ),
                    HobbyButton(
                      key: const ValueKey('moment-gallery'),
                      label: 'Choose photo',
                      icon: Icons.photo_library_outlined,
                      variant: HobbyButtonVariant.outline,
                      onPressed: enabled
                          ? () => vm.choosePhoto(MomentPhotoSource.gallery)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  key: ValueKey('moment-hobby-${selected ?? 'none'}'),
                  initialValue: selected,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: context.tr('Hobby')),
                  items: [
                    for (final Hobby hobby in hobbies)
                      DropdownMenuItem(
                        value: hobby.id,
                        child: Text(
                          hobby.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: enabled
                      ? (value) => vm.edit(hobbyId: value)
                      : null,
                ),
                const SizedBox(height: 20),
                HobbyTextField(
                  key: const ValueKey('moment-caption'),
                  label: 'Caption (optional)',
                  controller: _caption,
                  maxLines: 3,
                  maxLength: 160,
                  enabled: enabled,
                  onChanged: (value) => vm.edit(caption: value),
                ),
                const SizedBox(height: 6),
                Text(
                  '${state.draft.caption.trim().runes.length}/160',
                  textAlign: TextAlign.end,
                ),
                if (state.uncertain) ...[
                  const SizedBox(height: 12),
                  const AppText(
                    'Posting may have finished. Retry to check before changing this draft.',
                  ),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: AppText(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                if (state.busy) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.publishing || state.picking
                        ? null
                        : state.progress,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    state.picking
                        ? 'Opening photos…'
                        : state.publishing
                        ? 'Processing and posting…'
                        : 'Uploading: ${(state.progress * 100).round()}%',
                  ),
                  if (!state.publishing && !state.picking)
                    HobbyButton(
                      label: 'Cancel upload',
                      variant: HobbyButtonVariant.outline,
                      onPressed: () => unawaited(vm.cancelUpload()),
                    ),
                ],
                const SizedBox(height: 20),
                HobbyButton(
                  key: const ValueKey('post-moment'),
                  label: state.error == null ? 'Post moment' : 'Retry posting',
                  expand: true,
                  isLoading: state.busy,
                  onPressed: state.busy ? null : () => vm.submit(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
