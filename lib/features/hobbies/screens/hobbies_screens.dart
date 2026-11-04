import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../practice/screens/practice_screens.dart';

class HobbiesScreen extends ConsumerWidget {
  const HobbiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
    title: 'My Hobbies',
    screen: 'hobbies',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Eyebrow('MADE BY YOU'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AppText(
                'My Hobbies',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            HobbyButton(
              key: const ValueKey('create-hobby'),
              label: '+ Create',
              onPressed: () => showEditor(context, const HobbyEditor()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const InfoPanel(
          title: 'Your collection, your choice',
          text:
              'Create any hobby you want. Active and Interested are priority levels—not restrictions.',
        ),
        const SizedBox(height: 16),
        AsyncPanel(
          value: ref.watch(hobbiesProvider),
          retry: () => ref.invalidate(hobbiesProvider),
          builder: (items) => items.isEmpty
              ? EmptyState(
                  title: 'Your canvas is empty',
                  description:
                      'Give your first hobby a name, an icon, color and priority.',
                  actionLabel: 'Create first hobby',
                  onAction: () => showEditor(context, const HobbyEditor()),
                )
              : Column(
                  children: [
                    for (final h in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: HobbyTile(hobby: h),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class HobbyTile extends ConsumerWidget {
  const HobbyTile({super.key, required this.hobby, this.openDetail = true});
  final Hobby hobby;
  final bool openDetail;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(featureActionsProvider).busy;
    return HobbyCard(
      semanticLabel: 'Sở thích ${hobby.name}',
      onTap: openDetail
          ? () => context.push(RoutePaths.hobbyDetail(hobby.id))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HobbyGlyph(
                hobby.icon,
                color: hobbyColor(context, hobby.color),
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hobby.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (hobby.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hobby.description),
          ],
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final value in ['active', 'interested'])
                ChoiceChip(
                  label: AppText(value == 'active' ? 'Active' : 'Interested'),
                  selected: hobby.priority == value,
                  onSelected: busy
                      ? null
                      : (_) => ref
                            .read(featureActionsProvider.notifier)
                            .priority(hobby, value),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              HobbyButton(
                label: 'Hyper Mode',
                onPressed: () => context.push(
                  '${RoutePaths.hyper}?hobby=${Uri.encodeQueryComponent(hobby.id)}',
                ),
              ),
              HobbyButton(
                label: '✎ Edit',
                variant: HobbyButtonVariant.outline,
                onPressed: () => showEditor(context, HobbyEditor(hobby: hobby)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HobbyEditor extends ConsumerStatefulWidget {
  const HobbyEditor({super.key, this.hobby});
  final Hobby? hobby;
  @override
  ConsumerState<HobbyEditor> createState() => _HobbyEditorState();
}

class _HobbyEditorState extends ConsumerState<HobbyEditor> {
  late final name = TextEditingController(text: widget.hobby?.name ?? '');
  late final description = TextEditingController(
    text: widget.hobby?.description ?? '',
  );
  late String icon = widget.hobby?.icon ?? 'spark',
      color = widget.hobby?.color ?? 'mint';
  late String? priority = widget.hobby?.priority;
  @override
  void dispose() {
    name.dispose();
    description.dispose();
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
            widget.hobby == null ? 'Create your hobby' : 'Edit your hobby',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        AppText(
          'Give your hobby its own name, icon, and color.',
          style: TextStyle(fontSize: 12, color: context.hobbyPalette.muted),
        ),
        const SizedBox(height: 12),
        const Eyebrow('LIVE CARD PREVIEW'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.hobbyPalette.soft,
            border: Border.all(color: context.hobbyPalette.border),
            borderRadius: BorderRadius.circular(
              context.figmaStyle.controlRadius,
            ),
          ),
          child: Row(
            children: [
              HobbyGlyph(icon, color: hobbyColor(context, color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.text.trim().isEmpty
                          ? context.tr('Your hobby')
                          : name.text.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description.text.trim().isEmpty
                          ? context.tr('Something wonderful starts here')
                          : description.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.hobbyPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppText(
                priority == 'active'
                    ? 'Active'
                    : priority == 'interested'
                    ? 'Interested'
                    : 'Choose priority',
                style: TextStyle(
                  fontSize: 12,
                  color: context.hobbyPalette.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HobbyTextField(
          key: const ValueKey('hobby-name'),
          label: 'Hobby name *',
          hintText: 'e.g. Photography, chess, baking',
          controller: name,
          enabled: !status.busy,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        HobbyTextField(
          key: const ValueKey('hobby-description'),
          label: 'Description (optional)',
          hintText: 'What do you enjoy?',
          controller: description,
          maxLines: 2,
          enabled: !status.busy,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        const AppText(
          'Choose an icon',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in [
                for (final k in [
                  'spark',
                  'camera',
                  'music',
                  'palette',
                  'sports',
                  'book',
                  'garden',
                  'cook',
                  'fitness',
                  'code',
                  'chess',
                  'travel',
                ])
                  MapEntry(k, hobbyIcons[k]!),
              ])
                SizedBox(
                  width: (c.maxWidth - 24) / 4,
                  child: Semantics(
                    selected: icon == entry.key,
                    button: true,
                    label: context.tr('Icon ${context.tr(entry.key)}'),
                    child: Material(
                      color: icon == entry.key
                          ? context.hobbyPalette.soft
                          : context.hobbyPalette.cardSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.figmaStyle.controlRadius,
                        ),
                        side: BorderSide(
                          color: icon == entry.key
                              ? Theme.of(context).colorScheme.primary
                              : context.hobbyPalette.border,
                        ),
                      ),
                      child: InkWell(
                        onTap: status.busy
                            ? null
                            : () => setState(() => icon = entry.key),
                        child: SizedBox(
                          height: 48,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HobbyGlyph(entry.key, size: 18),
                              const SizedBox(height: 4),
                              AppText(
                                const {
                                  'spark': 'Nature',
                                  'camera': 'Camera',
                                  'music': 'Music',
                                  'palette': 'Art',
                                  'sports': 'Sport',
                                  'book': 'Books',
                                  'garden': 'Plants',
                                  'cook': 'Cooking',
                                  'fitness': 'Fitness',
                                  'code': 'Tech',
                                  'chess': 'Chess',
                                  'travel': 'Travel',
                                }[entry.key]!,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: context.hobbyPalette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const AppText(
          'Choose a color',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (i, key) in hobbyColorKeys.indexed)
              Semantics(
                selected: color == key,
                label: context.tr('Color ${context.tr(key)}'),
                button: true,
                child: SizedBox.square(
                  dimension: 48,
                  child: IconButton(
                    tooltip: context.tr(key),
                    onPressed: status.busy
                        ? null
                        : () => setState(() => color = key),
                    icon: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: color == key
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FigmaIcon(
                            'imgColor${i == 0 ? 1 : i}',
                            screen: 'create',
                            size: 28,
                            color: hobbyColor(context, key),
                          ),
                          if (color == key)
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const AppText(
          'Choose priority',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final p in ['active', 'interested']) ...[
              if (p == 'interested') const SizedBox(width: 8),
              Expanded(
                child: DesignChoice(
                  label: p == 'active' ? 'Active' : 'Interested',
                  subtitle: p == 'active'
                      ? 'Practice regularly'
                      : 'Explore at your pace',
                  selected: priority == p,
                  onTap: status.busy
                      ? null
                      : () => setState(() => priority = p),
                ),
              ),
            ],
          ],
        ),
        if (status.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Semantics(
              liveRegion: true,
              child: AppText(
                status.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
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
                key: const ValueKey('save-hobby'),
                label: widget.hobby == null ? 'Create Hobby' : 'Save changes',
                isLoading: status.busy,
                onPressed: status.busy
                    ? null
                    : () async {
                        final ok = await ref
                            .read(featureActionsProvider.notifier)
                            .saveHobby(
                              id: widget.hobby?.id,
                              name: name.text,
                              description: description.text,
                              icon: icon,
                              color: color,
                              priority: priority,
                            );
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

class HobbyDetailScreen extends ConsumerWidget {
  const HobbyDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FeaturePage(
    title: 'Hobby Detail',
    screen: 'detail',
    back: RoutePaths.hobbies,
    child: AsyncPanel(
      value: ref.watch(hobbiesProvider),
      retry: () => ref.invalidate(hobbiesProvider),
      builder: (items) {
        Hobby? h;
        for (final item in items) {
          if (item.id == id) h = item;
        }
        if (h == null) {
          return const EmptyState(
            title: 'Không tìm thấy sở thích',
            description: 'Sở thích đã được xóa hoặc không thuộc tài khoản này.',
          );
        }
        final hobby = h;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HobbyCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      HobbyGlyph(
                        hobby.icon,
                        size: 27,
                        color: hobbyColor(context, hobby.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hobby.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            AppText(
                              '${context.tr(hobby.priority == 'active' ? 'Active' : 'Interested')} priority',
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
                  Text(
                    hobby.description.isEmpty
                        ? context.tr('A hobby you created.')
                        : hobby.description,
                    key: const ValueKey('hobby-description-content'),
                    style: TextStyle(color: context.hobbyPalette.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: HobbyButton(
                          label: '✎ Edit',
                          variant: HobbyButtonVariant.secondary,
                          onPressed: () =>
                              showEditor(context, HobbyEditor(hobby: hobby)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HobbyButton(
                          label: '▷ Hyper Mode',
                          onPressed: () => context.push(
                            '${RoutePaths.hyper}?hobby=${Uri.encodeQueryComponent(hobby.id)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Section(
              title: 'Upcoming sessions',
              action: HobbyButton(
                label: '+ Schedule',
                onPressed: () => showEditor(
                  context,
                  PlanEditor(initialHobby: hobby.id),
                  showClose: false,
                  dismissible: false,
                ),
              ),
              child: AsyncPanel(
                value: ref.watch(plansProvider),
                retry: () => ref.invalidate(plansProvider),
                builder: (plans) {
                  final selected = plans
                      .where(
                        (p) =>
                            p.hobbyId == id &&
                            !p.done &&
                            p.startsAt.isAfter(DateTime.now()),
                      )
                      .toList();
                  return selected.isEmpty
                      ? const EmptyState(
                          title: 'No sessions planned',
                          description: 'Schedule a little time for this hobby.',
                        )
                      : Column(
                          children: [
                            for (final p in selected)
                              PlanTile(plan: p, hobby: hobby),
                          ],
                        );
                },
              ),
            ),
            HobbyButton(
              label: 'Delete hobby',
              variant: HobbyButtonVariant.danger,
              onPressed: () async {
                if (!await confirmAction(
                      context,
                      'Xóa sở thích?',
                      'Các lịch liên quan sẽ được gỡ. Lịch sử luyện tập được giữ.',
                      label: 'Xóa',
                      danger: true,
                    ) ||
                    !context.mounted) {
                  return;
                }
                final ok = await ref
                    .read(featureActionsProvider.notifier)
                    .remove(hobby);
                if (ok && context.mounted) context.go(RoutePaths.hobbies);
              },
            ),
          ],
        );
      },
    ),
  );
}
