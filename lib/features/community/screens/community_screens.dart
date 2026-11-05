import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../models/hobby_data.dart';
import '../../../viewmodels/data_providers.dart';
import '../../../viewmodels/feature_actions.dart';
import '../../../widgets/feature_widgets.dart';
import '../../../widgets/async_states.dart';
import '../../../widgets/hobby_button.dart';
import '../../../widgets/hobby_card.dart';
import '../../../widgets/hobby_text_field.dart';
import '../../../theme/tokens.dart';
import '../../../theme/hobby_theme.dart';
import '../../../widgets/design_widgets.dart';
import '../../../widgets/figma_assets.dart';
import '../../../app/router/route_paths.dart';

class CommunityFrame extends ConsumerWidget {
  const CommunityFrame({
    super.key,
    required this.title,
    required this.screen,
    required this.child,
    this.back,
  });
  final String title, screen;
  final String? back;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(flagsProvider).valueOrNull ?? const RuntimeFlags();
    final routes = {
      'Feed': RoutePaths.feed,
      'Groups': RoutePaths.groups,
      'Activities': RoutePaths.activities,
      'People': RoutePaths.people,
      'Chats': RoutePaths.chats,
    };
    final selected = {
      'feed': 'Feed',
      'groups': 'Groups',
      'activities': 'Activities',
      'people': 'People',
      'chats': 'Chats',
    }[screen];
    return FeaturePage(
      title: title,
      screen: screen,
      back: screen == 'conversation' ? RoutePaths.chats : null,
      scrollable: screen != 'conversation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (screen != 'conversation') ...[
            AppText(
              'Community',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const InfoPanel(
              title: 'Find your kind of people',
              text:
                  'Share progress, join hobby groups, discover activities, and chat.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.hobbyPalette.soft,
                borderRadius: BorderRadius.circular(
                  context.figmaStyle.controlRadius,
                ),
              ),
              child: Row(
                children: [
                  for (final entry in routes.entries)
                    Expanded(
                      child: Semantics(
                        selected: entry.key == selected,
                        button: true,
                        child: Material(
                          color: entry.key == selected
                              ? context.hobbyPalette.cardSurface
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            context.figmaStyle.controlRadius,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              context.figmaStyle.controlRadius,
                            ),
                            onTap: () => context.go(entry.value),
                            child: SizedBox(
                              height: 48,
                              child: Center(
                                child: AppText(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: entry.key == selected
                                        ? Theme.of(context).colorScheme.primary
                                        : context.hobbyPalette.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (flags.community)
            if (screen == 'conversation') Expanded(child: child) else child
          else
            EmptyState(
              title: 'Cộng đồng đang tạm nghỉ',
              description:
                  'Tính năng này hiện chưa được bật. Các sở thích và lịch của bạn vẫn hoạt động.',
              actionLabel: 'Thử lại',
              onAction: () => ref.invalidate(flagsProvider),
            ),
        ],
      ),
    );
  }
}

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool forYou = true;
  @override
  Widget build(BuildContext context) => CommunityFrame(
    title: 'Community',
    screen: 'feed',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HobbyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'Moments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const AppText(
                'Share a photo with your group. Moments last for 3 hours.',
              ),
              const SizedBox(height: 12),
              HobbyButton(
                label: 'Open group moments',
                icon: Icons.photo_camera_outlined,
                variant: HobbyButtonVariant.outline,
                onPressed: () => context.push(RoutePaths.moments),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        HobbyButton(
          label: '+ Write a post',
          variant: HobbyButtonVariant.secondary,
          onPressed: () => showEditor(
            context,
            TextEntryEditor(
              title: 'Share a hobby moment',
              fields: const {'topic': 'Hobby or topic', 'text': 'Your post'},
              onSubmit: (v) => ref
                  .read(featureActionsProvider.notifier)
                  .publish(v['text']!, v['topic']!),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HobbyButton(
                label: 'For You',
                variant: forYou
                    ? HobbyButtonVariant.primary
                    : HobbyButtonVariant.secondary,
                onPressed: () => setState(() => forYou = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HobbyButton(
                label: 'Explore All',
                variant: forYou
                    ? HobbyButtonVariant.secondary
                    : HobbyButtonVariant.primary,
                onPressed: () => setState(() => forYou = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AsyncPanel(
          value: ref
              .watch(feedProvider)
              .whenData(
                (items) => rankFeed(
                  items,
                  ref.watch(hobbiesProvider).valueOrNull ?? [],
                  forYou,
                ),
              ),
          retry: () => ref.invalidate(feedProvider),
          builder: (items) => items.isEmpty
              ? const EmptyState(
                  title: 'No posts yet',
                  description: 'Share something you learned or tried today.',
                )
              : Column(
                  children: [
                    for (final p in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: HobbyCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  _avatar(context, p.text('authorName')),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.text('authorName'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (p.text('topic').isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            p.text('topic'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: context.hobbyPalette.muted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(p.text('text')),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  Consumer(
                                    builder: (c, r, _) {
                                      final likes = r.watch(
                                        likesProvider(p.id),
                                      );
                                      return likes.when(
                                        loading: () => const SizedBox(
                                          width: AppSizes.minTap,
                                          height: AppSizes.minTap,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        error: (e, s) => IconButton(
                                          tooltip: context.tr(
                                            'Thử tải lượt thích',
                                          ),
                                          onPressed: () =>
                                              r.invalidate(likesProvider(p.id)),
                                          icon: const Icon(Icons.refresh),
                                        ),
                                        data: (values) {
                                          final liked = values.any(
                                            (v) =>
                                                v.id ==
                                                r.watch(ownerIdProvider),
                                          );
                                          return TextButton.icon(
                                            onPressed:
                                                r
                                                    .watch(
                                                      featureActionsProvider,
                                                    )
                                                    .busy
                                                ? null
                                                : () => r
                                                      .read(
                                                        featureActionsProvider
                                                            .notifier,
                                                      )
                                                      .like(p.id, !liked),
                                            icon: Icon(
                                              liked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                            ),
                                            label: AppText(
                                              '${values.length} Likes',
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  TextButton(
                                    onPressed: () => showEditor(
                                      context,
                                      CommentsSheet(postId: p.id),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FigmaIcon(
                                          'imgIconChat',
                                          screen: 'feed',
                                          size: 18,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        const AppText('Comments'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class TextEntryEditor extends ConsumerStatefulWidget {
  const TextEntryEditor({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
  });
  final String title;
  final Map<String, String> fields;
  final Future<bool> Function(Map<String, String>) onSubmit;
  @override
  ConsumerState<TextEntryEditor> createState() => _TextEntryEditorState();
}

class _TextEntryEditorState extends ConsumerState<TextEntryEditor> {
  late final fields = {
    for (final key in widget.fields.keys) key: TextEditingController(),
  };
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(featureActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 48),
          child: AppText(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final entry in widget.fields.entries) ...[
          HobbyTextField(
            key: ValueKey('editor-${entry.key}'),
            label: entry.value,
            controller: fields[entry.key],
            maxLines: entry.key == 'text' || entry.key == 'description' ? 4 : 1,
            enabled: !status.busy,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (status.error != null)
          Semantics(
            liveRegion: true,
            child: AppText(
              status.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: HobbyButton(
                label: 'Cancel',
                variant: HobbyButtonVariant.secondary,
                onPressed: status.busy ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HobbyButton(
                label: 'Publish',
                isLoading: status.busy,
                onPressed: status.busy
                    ? null
                    : () async {
                        final ok = await widget.onSubmit({
                          for (final e in fields.entries) e.key: e.value.text,
                        });
                        if (ok && context.mounted) Navigator.pop(context);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.postId});
  final String postId;
  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final text = TextEditingController();
  String draftId = const Uuid().v4();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(featureActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText('Bình luận', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        AsyncPanel(
          value: ref.watch(commentsProvider(widget.postId)),
          retry: () => ref.invalidate(commentsProvider(widget.postId)),
          builder: (items) => items.isEmpty
              ? const AppText('Chưa có bình luận.')
              : Column(
                  children: [
                    for (final c in items)
                      ListTile(
                        title: Text(c.text('authorName')),
                        subtitle: Text(c.text('text')),
                      ),
                  ],
                ),
        ),
        HobbyTextField(
          label: 'Bình luận của bạn',
          controller: text,
          maxLines: 3,
          enabled: !status.busy,
        ),
        if (status.error != null)
          AppText(
            status.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        HobbyButton(
          label: 'Gửi bình luận',
          isLoading: status.busy,
          onPressed: status.busy
              ? null
              : () async {
                  final ok = await ref
                      .read(featureActionsProvider.notifier)
                      .comment(widget.postId, text.text, draftId);
                  if (ok && mounted) {
                    text.clear();
                    draftId = const Uuid().v4();
                  }
                },
        ),
      ],
    );
  }
}

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CommunityFrame(
    title: 'Groups',
    screen: 'groups',
    back: RoutePaths.feed,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                'Hobby groups',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            HobbyButton(
              label: '+ Create group',
              onPressed: () => showEditor(
                context,
                TextEntryEditor(
                  title: 'Nhóm mới',
                  fields: const {
                    'name': 'Tên nhóm',
                    'topic': 'Chủ đề sở thích',
                    'description': 'Mô tả',
                  },
                  onSubmit: (v) => ref
                      .read(featureActionsProvider.notifier)
                      .group(v['name']!, v['topic']!, v['description']!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncPanel(
          value: ref.watch(joinedGroupsProvider),
          retry: () => ref.invalidate(joinedGroupsProvider),
          builder: (joined) => AsyncPanel(
            value: ref.watch(groupsProvider),
            retry: () => ref.invalidate(groupsProvider),
            builder: (groups) => groups.isEmpty
                ? const EmptyState(
                    title: 'Chưa có nhóm',
                    description:
                        'Tạo một nhóm cho những người có cùng sở thích.',
                  )
                : Column(
                    children: [
                      for (final g in groups)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: HobbyCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    FigmaIcon(
                                      'imgIconUsers',
                                      screen: 'groups',
                                      size: 28,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            g.text('name'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            g.text('topic'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: context.hobbyPalette.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(g.text('description')),
                                const SizedBox(height: AppSpacing.sm),
                                if (joined.any((j) => j.id == g.id)) ...[
                                  HobbyButton(
                                    label: 'Open group moments',
                                    variant: HobbyButtonVariant.outline,
                                    onPressed: () => context.push(
                                      RoutePaths.momentsForGroup(g.id),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                ],
                                HobbyButton(
                                  label: joined.any((j) => j.id == g.id)
                                      ? 'Open group chat'
                                      : 'Join group',
                                  onPressed:
                                      ref.watch(featureActionsProvider).busy
                                      ? null
                                      : () async {
                                          final isJoined = joined.any(
                                            (j) => j.id == g.id,
                                          );
                                          if (isJoined ||
                                              await ref
                                                  .read(
                                                    featureActionsProvider
                                                        .notifier,
                                                  )
                                                  .join(g.id)) {
                                            if (context.mounted) {
                                              context.go(
                                                RoutePaths.conversation(
                                                  'g_${g.id}',
                                                ),
                                              );
                                            }
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CommunityFrame(
    title: 'Activities',
    screen: 'activities',
    back: RoutePaths.feed,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const InfoPanel(
          text:
              'RSVP and adding to Home are separate actions. Joining does not automatically schedule an activity.',
        ),
        const SizedBox(height: 16),
        HobbyButton(
          label: '+ Create activity',
          icon: Icons.event_outlined,
          onPressed: () => showEditor(context, const EventEditor()),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncPanel(
          value: ref.watch(rsvpsProvider),
          retry: () => ref.invalidate(rsvpsProvider),
          builder: (rsvps) => AsyncPanel(
            value: ref.watch(eventsProvider),
            retry: () => ref.invalidate(eventsProvider),
            builder: (events) => events.isEmpty
                ? const EmptyState(
                    title: 'Chưa có hoạt động',
                    description:
                        'Khởi tạo một buổi thực hành để cùng tham gia.',
                  )
                : Column(
                    children: [
                      for (final e in events)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: HobbyCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  e.text('title'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(e.text('topic')),
                                if (e.date('startsAt') != null)
                                  AppText(
                                    dateLabel(e.date('startsAt')!, context),
                                  ),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  children: [
                                    HobbyButton(
                                      label:
                                          rsvps.any(
                                            (r) =>
                                                r.id == e.id && r.flag('going'),
                                          )
                                          ? 'Hủy RSVP'
                                          : 'RSVP',
                                      onPressed:
                                          ref.watch(featureActionsProvider).busy
                                          ? null
                                          : () => ref
                                                .read(
                                                  featureActionsProvider
                                                      .notifier,
                                                )
                                                .rsvp(
                                                  e.id,
                                                  !rsvps.any(
                                                    (r) =>
                                                        r.id == e.id &&
                                                        r.flag('going'),
                                                  ),
                                                ),
                                    ),
                                    if (rsvps.any(
                                      (r) => r.id == e.id && r.flag('going'),
                                    ))
                                      HobbyButton(
                                        label: 'Add to Home',
                                        variant: HobbyButtonVariant.outline,
                                        onPressed: () => showEditor(
                                          context,
                                          EventHomePicker(event: e),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                const AppText(
                                  'RSVP chỉ ghi nhận tham gia. Bấm Add to Home nếu bạn muốn thêm vào lịch.',
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
}

class EventEditor extends ConsumerStatefulWidget {
  const EventEditor({super.key});
  @override
  ConsumerState<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends ConsumerState<EventEditor> {
  final title = TextEditingController(), topic = TextEditingController();
  DateTime? day;
  TimeOfDay? time;
  @override
  void dispose() {
    title.dispose();
    topic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(featureActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText('Hoạt động mới', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        HobbyTextField(label: 'Tên hoạt động', controller: title),
        const SizedBox(height: AppSpacing.sm),
        HobbyTextField(label: 'Chủ đề', controller: topic),
        const SizedBox(height: AppSpacing.sm),
        HobbyButton(
          label: day == null
              ? 'Chọn ngày'
              : '${day!.day}/${day!.month}/${day!.year}',
          variant: HobbyButtonVariant.outline,
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (d != null && mounted) setState(() => day = d);
          },
        ),
        HobbyButton(
          label: time == null ? 'Chọn giờ' : time!.format(context),
          variant: HobbyButtonVariant.outline,
          onPressed: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (t != null && mounted) setState(() => time = t);
          },
        ),
        if (status.error != null)
          AppText(
            status.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        HobbyButton(
          label: '+ Create activity',
          isLoading: status.busy,
          onPressed: status.busy
              ? null
              : () async {
                  final ok = await ref
                      .read(featureActionsProvider.notifier)
                      .event(
                        title.text,
                        topic.text,
                        day == null || time == null
                            ? DateTime(2000)
                            : DateTime(
                                day!.year,
                                day!.month,
                                day!.day,
                                time!.hour,
                                time!.minute,
                              ),
                      );
                  if (ok && context.mounted) Navigator.pop(context);
                },
        ),
      ],
    );
  }
}

class EventHomePicker extends ConsumerWidget {
  const EventHomePicker({super.key, required this.event});
  final SocialEntry event;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AsyncPanel(
    value: ref.watch(hobbiesProvider),
    retry: () => ref.invalidate(hobbiesProvider),
    builder: (items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Chọn sở thích cho lịch',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (items.isEmpty)
          const AppText('Hãy tạo sở thích ở My Hobbies trước.'),
        for (final h in items)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: HobbyButton(
              label: h.name,
              translateLabel: false,
              onPressed: ref.watch(featureActionsProvider).busy
                  ? null
                  : () async {
                      final ok = await ref
                          .read(featureActionsProvider.notifier)
                          .addEvent(event, h);
                      if (ok && context.mounted) Navigator.pop(context);
                    },
            ),
          ),
        if (ref.watch(featureActionsProvider).error != null)
          AppText(ref.watch(featureActionsProvider).error!),
      ],
    ),
  );
}

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CommunityFrame(
    title: 'People',
    screen: 'people',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'People to connect with',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        AsyncPanel(
          value: ref.watch(peopleProvider),
          retry: () => ref.invalidate(peopleProvider),
          builder: (items) =>
              items.where((p) => p.id != ref.watch(ownerIdProvider)).isEmpty
              ? EmptyState(
                  title: 'No public profiles yet',
                  description:
                      'Only people who choose to share their profile appear here.',
                  actionLabel: 'Privacy settings',
                  onAction: () =>
                      context.push(RoutePaths.settingsDetail('privacy')),
                )
              : Column(
                  children: [
                    for (final p in items)
                      if (p.id != ref.watch(ownerIdProvider))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: HobbyCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _avatar(context, p.text('displayName')),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.text('displayName'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.text('bio'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.hobbyPalette.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                HobbyButton(
                                  label: !p.flag('allowMessages')
                                      ? 'Private'
                                      : ref
                                                .watch(preferencesProvider)
                                                .valueOrNull
                                                ?.allowMessages ==
                                            true
                                      ? 'Chat'
                                      : 'Enable chat',
                                  variant: HobbyButtonVariant.secondary,
                                  onPressed:
                                      !p.flag('allowMessages') ||
                                          ref.watch(featureActionsProvider).busy
                                      ? null
                                      : () async {
                                          if (ref
                                                  .read(preferencesProvider)
                                                  .valueOrNull
                                                  ?.allowMessages !=
                                              true) {
                                            context.push(
                                              RoutePaths.settingsDetail(
                                                'privacy',
                                              ),
                                            );
                                            return;
                                          }
                                          final id = await ref
                                              .read(
                                                featureActionsProvider.notifier,
                                              )
                                              .chat(p.id);
                                          if (id != null && context.mounted) {
                                            context.go(
                                              RoutePaths.conversation(id),
                                            );
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => CommunityFrame(
    title: 'Chats',
    screen: 'chats',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Conversations',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        const InfoPanel(
          text:
              'Messages are saved securely and shared with the participants of each conversation.',
        ),
        const SizedBox(height: 16),
        AsyncPanel(
          value: ref.watch(joinedGroupsProvider),
          retry: () => ref.invalidate(joinedGroupsProvider),
          builder: (items) => Column(
            children: [
              for (final g in items)
                _conversationCard(
                  context,
                  g.text('name'),
                  'Group conversation',
                  () => context.go(RoutePaths.conversation('g_${g.id}')),
                ),
            ],
          ),
        ),
        AsyncPanel(
          value: ref.watch(chatsProvider),
          retry: () => ref.invalidate(chatsProvider),
          builder: (items) => items.isEmpty
              ? const EmptyState(
                  title: 'No direct conversations yet',
                  description:
                      'Find someone in People to start a conversation.',
                )
              : Column(
                  children: [
                    for (final chat in items)
                      _conversationCard(
                        context,
                        _chatName(
                          chat,
                          ref.watch(ownerIdProvider),
                          ref.watch(peopleProvider).valueOrNull ?? [],
                          context,
                        ),
                        'Open conversation',
                        () => context.go(RoutePaths.conversation(chat.id)),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

String _chatName(
  SocialEntry chat,
  String? uid,
  List<SocialEntry> people,
  BuildContext context,
) {
  final ids = chat.strings('participants').where((p) => p != uid);
  for (final id in ids) {
    for (final p in people) {
      if (p.id == id && p.text('displayName').isNotEmpty) {
        return p.text('displayName');
      }
    }
  }
  return context.tr('Direct conversation');
}

Widget _conversationCard(
  BuildContext context,
  String name,
  String subtitle,
  VoidCallback onTap,
) => Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: HobbyCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        _avatar(context, name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              AppText(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: context.hobbyPalette.muted,
                ),
              ),
            ],
          ),
        ),
        FigmaIcon(
          'imgIconChevron',
          screen: 'inbox',
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    ),
  ),
);

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final text = TextEditingController();
  String draftId = const Uuid().v4();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.id.startsWith('g_'),
        id = widget.id.startsWith('g_') ? widget.id.substring(2) : widget.id;
    final status = ref.watch(featureActionsProvider);
    return CommunityFrame(
      title: group ? 'Chat nhóm' : 'Conversation',
      screen: 'conversation',
      back: RoutePaths.chats,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _avatar(context, group ? 'G' : 'D'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      group ? 'Group conversation' : 'Direct conversation',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'Messages sync with participants',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.hobbyPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              key: const ValueKey('conversation-messages'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.hobbyPalette.soft,
                border: Border.all(color: context.hobbyPalette.border),
                borderRadius: BorderRadius.circular(
                  context.figmaStyle.cardRadius,
                ),
              ),
              child: AsyncPanel(
                value: ref.watch(messagesProvider((id: id, group: group))),
                retry: () =>
                    ref.invalidate(messagesProvider((id: id, group: group))),
                builder: (items) => items.isEmpty
                    ? const EmptyState(
                        title: 'Bắt đầu cuộc trò chuyện',
                        description:
                            'Tin nhắn sẽ được lưu và đồng bộ với người tham gia.',
                      )
                    : ListView.builder(
                        key: const ValueKey('message-list'),
                        reverse: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final m = items[items.length - 1 - index];
                          return Align(
                            alignment:
                                m.text('senderId') == ref.watch(ownerIdProvider)
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: HobbyCard(
                                semanticLabel: 'Tin nhắn ${m.text('text')}',
                                child: Text(m.text('text')),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HobbyTextField(
                  key: const ValueKey('message-composer'),
                  label: '',
                  hintText: 'Write a message',
                  controller: text,
                  enabled: !status.busy,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: IconButton.filled(
                  key: const ValueKey('send-message'),
                  tooltip: context.tr('Send message'),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.figmaStyle.controlRadius,
                      ),
                    ),
                  ),
                  icon: status.busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FigmaIcon(
                          'imgIconSend',
                          screen: 'conversation',
                          size: 24,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                  onPressed: status.busy
                      ? null
                      : () async {
                          final ok = await ref
                              .read(featureActionsProvider.notifier)
                              .send(id, group, text.text, draftId);
                          if (ok && mounted) {
                            text.clear();
                            draftId = const Uuid().v4();
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _avatar(BuildContext context, String name) => CircleAvatar(
  radius: 18,
  backgroundColor: context.hobbyPalette.soft,
  child: AppText(
    name.trim().isEmpty ? 'H' : name.trim().characters.first.toUpperCase(),
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
);
