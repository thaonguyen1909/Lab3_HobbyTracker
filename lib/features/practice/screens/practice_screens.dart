import 'package:intl/intl.dart';
import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/hobby_data.dart';
import '../../../models/schedule_draft.dart';
import 'schedule_editor.dart';
export 'schedule_editor.dart' show PlanEditor;
import '../../../viewmodels/data_providers.dart';
import '../../../viewmodels/feature_actions.dart';
import '../../../viewmodels/hyper_view_model.dart';
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
import '../../hobbies/screens/hobbies_screens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime day = DateTime.now();
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: 'Home',
    screen: 'home',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText('Home', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        DesignHero(
          eyebrow: 'MAKE TIME FOR YOU',
          title: 'Make time for\nwhat you love.',
          subtitle: 'Plan your day or start practicing now.',
          height: 205,
          action: SizedBox(
            width: 194,
            child: HobbyButton(
              label: '▷ Enter Hyper Mode',
              onPressed: () => context.push(RoutePaths.hyper),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Your week',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _weekButton('Previous week', 'imgIconBack', -7),
              const SizedBox(width: 8),
              _weekButton('Next week', 'imgIconChevron', 7),
            ],
          ),
          child: CalendarWeek(
            day: day,
            onSelected: (d) => setState(() => day = d),
          ),
        ),
        Section(
          title: context
              .tr('Activities on {0}')
              .replaceAll(
                '{0}',
                DateFormat.yMd(AppStrings.of(context).languageCode).format(day),
              ),
          action: HobbyButton(
            key: const ValueKey('add-schedule'),
            label: '+ Schedule',
            onPressed: () => _openSchedule(),
          ),
          child: AsyncPanel(
            value: ref.watch(hobbiesProvider),
            retry: () => ref.invalidate(hobbiesProvider),
            builder: (hobbies) => AsyncPanel(
              value: ref.watch(plansProvider),
              retry: () => ref.invalidate(plansProvider),
              builder: (plans) {
                final today = visiblePlans(plans, hobbies, day);
                return today.isEmpty
                    ? const EmptyState(
                        title: 'No sessions planned',
                        description:
                            'Schedule a little time for a hobby you enjoy.',
                      )
                    : Column(
                        children: [
                          for (final p in today)
                            PlanTile(
                              plan: p,
                              hobby: hobbies.firstWhere(
                                (h) => h.id == p.hobbyId,
                              ),
                            ),
                        ],
                      );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const AppText('30m today'),
                onPressed: () => _openSchedule(today: true),
              ),
              ActionChip(
                avatar: const Icon(Icons.access_time, size: 18),
                label: const AppText('2 hours tonight'),
                onPressed: () =>
                    _openSchedule(today: true, tonight: true, minutes: 120),
              ),
              ActionChip(
                avatar: const Icon(Icons.repeat, size: 18),
                label: const AppText('Repeat weekly'),
                onPressed: () => _openSchedule(repeat: ScheduleRepeat.weekly),
              ),
              ActionChip(
                avatar: const Icon(Icons.tune, size: 18),
                label: const AppText('Custom schedule'),
                onPressed: () => _openSchedule(),
              ),
            ],
          ),
        ),
        Section(
          title: 'Activity history',
          action: AppText(
            '${ref.watch(historyProvider).valueOrNull?.length ?? 0} saved',
            style: TextStyle(fontSize: 12, color: context.hobbyPalette.muted),
          ),
          child: AsyncPanel(
            value: ref.watch(historyProvider),
            retry: () => ref.invalidate(historyProvider),
            builder: (records) => records.isEmpty
                ? const EmptyState(
                    title: 'Start your journey',
                    iconName: 'imgIconArchive',
                    description:
                        'Time spent and notes from finished Hyper Mode sessions appear here.',
                  )
                : Column(
                    children: [
                      for (final r in records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HobbyCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  r.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                AppText(
                                  '${elapsedLabel(r.elapsedMs)} · ${dateLabel(r.finishedAt, context)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.hobbyPalette.muted,
                                  ),
                                ),
                                if (r.notes.isNotEmpty) Text(r.notes),
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
  void _openSchedule({
    bool today = false,
    bool tonight = false,
    int minutes = 30,
    ScheduleRepeat repeat = ScheduleRepeat.none,
  }) {
    final now = DateTime.now();
    if (today) setState(() => day = now);
    showEditor(
      context,
      PlanEditor(
        initialDay: day,
        initialMinutes: minutes,
        initialRepeat: repeat,
        initialTime: tonight
            ? (now.hour >= 20
                  ? TimeOfDay.fromDateTime(now)
                  : const TimeOfDay(hour: 20, minute: 0))
            : null,
      ),
      showClose: false,
      dismissible: false,
    );
  }

  Widget _weekButton(String label, String asset, int delta) => SizedBox(
    width: 47,
    height: 48,
    child: IconButton.filledTonal(
      tooltip: context.tr(label),
      style: IconButton.styleFrom(
        backgroundColor: context.hobbyPalette.soft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.figmaStyle.controlRadius),
        ),
      ),
      onPressed: () =>
          setState(() => day = DateTime(day.year, day.month, day.day + delta)),
      icon: FigmaIcon(
        asset,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class PlanTile extends ConsumerWidget {
  const PlanTile({super.key, required this.plan, required this.hobby});
  final PracticePlan plan;
  final Hobby hobby;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: HobbyCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.hobbyPalette.soft,
              borderRadius: BorderRadius.circular(
                context.figmaStyle.controlRadius,
              ),
            ),
            child: HobbyGlyph(
              hobby.icon,
              size: 23,
              color: hobbyColor(context, hobby.color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                AppText(
                  '${TimeOfDay.fromDateTime(plan.startsAt).format(context)} · ${context.tr('${plan.minutes} min')} · ${plan.done
                      ? context.tr('Completed')
                      : hobby.priority == 'active'
                      ? context.tr('Active')
                      : context.tr('Interested')}',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.7,
                    color: context.hobbyPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!plan.done)
            HobbyButton(
              label: '▷ Start',
              onPressed: () => context.push(
                '${RoutePaths.hyper}?hobby=${Uri.encodeQueryComponent(hobby.id)}&plan=${Uri.encodeQueryComponent(plan.id)}',
              ),
            ),
          SizedBox(
            width: 24,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              tooltip: context.tr('Session actions'),
              iconSize: 16,
              onSelected: (_) async {
                if (await confirmAction(
                      context,
                      'Delete session?',
                      'Practice history will be kept.',
                    ) &&
                    context.mounted) {
                  await ref
                      .read(featureActionsProvider.notifier)
                      .deletePlan(plan.id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: AppText('Delete session'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class HyperScreen extends ConsumerStatefulWidget {
  const HyperScreen({super.key, this.initialHobby, this.initialPlan});
  final String? initialHobby, initialPlan;
  @override
  ConsumerState<HyperScreen> createState() => _HyperScreenState();
}

class _HyperScreenState extends ConsumerState<HyperScreen>
    with WidgetsBindingObserver {
  final notes = TextEditingController();
  bool initialized = false;
  HyperViewModel? activeVm;
  bool pauseOnExit = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      ref
          .read(hyperProvider.notifier)
          .onBackground(
            ref.read(preferencesProvider).valueOrNull?.pauseOnExit ?? true,
          );
    }
  }

  @override
  void dispose() {
    activeVm?.onBackground(pauseOnExit);
    WidgetsBinding.instance.removeObserver(this);
    notes.dispose();
    super.dispose();
  }

  Future<void> choose(Hobby h, {String planId = ''}) async {
    final vm = ref.read(hyperProvider.notifier);
    if (!vm.select(h, planId: planId)) {
      if (await confirmAction(
            context,
            'Đổi phiên luyện tập?',
            'Bỏ thời gian và ghi chú chưa lưu của phiên hiện tại?',
            label: 'Bỏ bản nháp',
          ) &&
          mounted) {
        if (!vm.select(h, planId: planId, discard: true)) return;
      } else {
        return;
      }
    }
    if (ref.read(preferencesProvider).valueOrNull?.autoTimer == true) {
      vm.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(hyperProvider);
    final vm = ref.read(hyperProvider.notifier);
    activeVm = vm;
    pauseOnExit =
        ref.watch(preferencesProvider).valueOrNull?.pauseOnExit ?? true;
    if (notes.text != s.notes) notes.text = s.notes;
    ref.listen(hyperProvider, (old, next) {
      if (notes.text != next.notes) {
        notes.text = next.notes;
      }
    });
    final hobbies = ref.watch(hobbiesProvider);
    if (!initialized && !s.restoring && hobbies.hasValue) {
      initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final match = hobbies.valueOrNull
            ?.where((h) => h.id == widget.initialHobby)
            .firstOrNull;
        if (match != null) choose(match, planId: widget.initialPlan ?? '');
      });
    }
    return FeaturePage(
      title: 'Hyper Mode',
      screen: 'hyper',
      back: RoutePaths.home,
      child: AsyncPanel(
        value: hobbies,
        retry: () => ref.invalidate(hobbiesProvider),
        builder: (items) {
          if (s.restoring) {
            return const LoadingState(label: 'Đang khôi phục bản nháp…');
          }
          if (items.isEmpty) {
            return EmptyState(
              title: 'Sở thích đầu tiên của bạn',
              description: 'Tạo một sở thích để bắt đầu luyện tập.',
              actionLabel: 'Tạo sở thích',
              onAction: () => showEditor(context, const HobbyEditor()),
            );
          }
          final selected = items.where((h) => h.id == s.hobbyId).firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selected == null) ...[
                AppText(
                  'Choose a hobby',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final h in items)
                      ChoiceChip(
                        label: Text(h.name),
                        selected: s.hobbyId == h.id,
                        onSelected: s.saving ? null : (_) => choose(h),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ] else
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    tooltip: context.tr('Change hobby'),
                    onSelected: (id) =>
                        choose(items.firstWhere((h) => h.id == id)),
                    itemBuilder: (_) => [
                      for (final h in items)
                        PopupMenuItem(value: h.id, child: Text(h.name)),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AppText(
                        'Change hobby',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.hobbyPalette.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected != null) ...[
                const Center(child: Eyebrow('HYPER MODE · FOCUS SPACE')),
                const SizedBox(height: 12),
                Text(
                  selected.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                AppText(
                  'A little time for something you enjoy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.hobbyPalette.muted),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.hobbyPalette.cardSurface,
                      border: Border.all(
                        width: 8,
                        color: context.hobbyPalette.heroStart,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: context.tr(
                            'Practice time ${elapsedLabel(s.elapsedMs)}',
                          ),
                          child: AppText(
                            elapsedLabel(s.elapsedMs),
                            key: const ValueKey('hyper-elapsed'),
                            style: const TextStyle(
                              fontSize: 36,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppText(
                          s.finished
                              ? 'SESSION SAVED'
                              : s.running
                              ? 'IN THE MOMENT'
                              : s.elapsedMs == 0
                              ? 'READY TO BEGIN'
                              : 'PAUSED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.hobbyPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!s.finished)
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      HobbyButton(
                        key: const ValueKey('timer-toggle'),
                        label: s.running ? 'Ⅱ Pause' : '▷ Start / Resume',
                        onPressed: s.saving
                            ? null
                            : () {
                                if (s.running) {
                                  vm.pause();
                                } else {
                                  vm.start();
                                }
                              },
                      ),
                      HobbyButton(
                        label: 'Reset',
                        icon: Icons.replay,
                        variant: HobbyButtonVariant.outline,
                        onPressed: s.saving
                            ? null
                            : () async {
                                if (s.elapsedMs <= 3000 ||
                                    await confirmAction(
                                      context,
                                      'Đặt lại thời gian?',
                                      'Thời gian về 0; ghi chú được giữ.',
                                    )) {
                                  vm.reset();
                                }
                              },
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                AppText(
                  'Helpful tools',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: HobbyCard(
                        onTap: () => ref
                            .read(featureActionsProvider.notifier)
                            .openShortcut(
                              ref
                                      .read(preferencesProvider)
                                      .valueOrNull
                                      ?.music ??
                                  'spotify',
                              selected.name,
                            ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            FigmaIcon(
                              'imgIconHeadphones',
                              screen: 'hyper',
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    '${ref.watch(preferencesProvider).valueOrNull?.music == 'youtube' ? 'YouTube' : 'Spotify'} ↗',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppText(
                                    'Open music',
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: HobbyCard(
                        onTap: () => ref
                            .read(featureActionsProvider.notifier)
                            .openShortcut(
                              ref
                                      .read(preferencesProvider)
                                      .valueOrNull
                                      ?.search ??
                                  'google',
                              selected.name,
                            ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            FigmaIcon(
                              'imgIconSearch',
                              screen: 'hyper',
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    '${ref.watch(preferencesProvider).valueOrNull?.search == 'coccoc' ? 'Cốc Cốc' : 'Google'} ↗',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppText(
                                    'Search guides',
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AppText(
                  'Session notes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                HobbyTextField(
                  key: const ValueKey('hyper-notes'),
                  label: 'What did you practice or learn?',
                  hintText: 'Write a few notes while you practice...',
                  controller: notes,
                  maxLines: 5,
                  enabled: !s.saving && !s.finished,
                  onChanged: vm.notes,
                ),
                const SizedBox(height: 16),
                if (s.error != null)
                  Semantics(
                    liveRegion: true,
                    child: AppText(
                      s.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!s.finished)
                  HobbyButton(
                    key: const ValueKey('finish-session'),
                    label: 'Finish & save activity',
                    isLoading: s.saving,
                    onPressed: s.saving
                        ? null
                        : () => vm.finish(
                            selected,
                            sound:
                                ref
                                    .read(preferencesProvider)
                                    .valueOrNull
                                    ?.sound ??
                                false,
                          ),
                  ),
                if (s.finished) ...[
                  HobbyButton(
                    label: 'View activity history',
                    onPressed: () => context.go(RoutePaths.home),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  HobbyButton(
                    label: 'New session',
                    variant: HobbyButtonVariant.outline,
                    onPressed: () => vm.select(selected, discard: true),
                  ),
                ],
              ] else if (s.hobbyId.isNotEmpty)
                const ErrorState(
                  message:
                      'Sở thích của bản nháp đã được xóa. Chọn một sở thích khác để bắt đầu phiên mới.',
                ),
            ],
          );
        },
      ),
    );
  }
}

class CalendarWeek extends StatelessWidget {
  const CalendarWeek({super.key, required this.day, required this.onSelected});
  final DateTime day;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = ((constraints.maxWidth - 48) / 7).clamp(
        48.0,
        double.infinity,
      );
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final d in weekDays(day))
              Padding(
                padding: EdgeInsets.only(right: d.weekday == 7 ? 0 : 8),
                child: Semantics(
                  selected: DateUtils.isSameDay(d, day),
                  label: '${d.day}/${d.month}/${d.year}',
                  button: true,
                  child: Material(
                    color: DateUtils.isSameDay(d, day)
                        ? Theme.of(context).colorScheme.primary
                        : context.hobbyPalette.cardSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.figmaStyle.controlRadius,
                      ),
                      side: BorderSide(color: context.hobbyPalette.border),
                    ),
                    child: InkWell(
                      onTap: () => onSelected(d),
                      borderRadius: BorderRadius.circular(
                        context.figmaStyle.controlRadius,
                      ),
                      child: Container(
                        width: width,
                        constraints: const BoxConstraints(minHeight: 74),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              [
                                'MON',
                                'TUE',
                                'WED',
                                'THU',
                                'FRI',
                                'SAT',
                                'SUN',
                              ][d.weekday - 1],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: DateUtils.isSameDay(d, day)
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : context.hobbyPalette.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppText(
                              '${d.day}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: DateUtils.isSameDay(d, day)
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: DateUtils.isSameDay(d, day)
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.transparent,
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
      );
    },
  );
}
