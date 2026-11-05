import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_strings.dart';
import '../../../models/hobby_data.dart';
import '../../../models/schedule_draft.dart';
import '../../../theme/hobby_theme.dart';
import '../../../viewmodels/data_providers.dart';
import '../../../viewmodels/feature_actions.dart';
import '../../../widgets/async_states.dart';
import '../../../widgets/feature_widgets.dart';
import '../../../widgets/hobby_button.dart';
import '../../hobbies/screens/hobbies_screens.dart';

class PlanEditor extends ConsumerStatefulWidget {
  const PlanEditor({
    super.key,
    this.initialHobby,
    this.initialDay,
    this.initialMinutes = 30,
    this.initialTime,
    this.initialRepeat = ScheduleRepeat.none,
  });
  final String? initialHobby;
  final DateTime? initialDay;
  final int initialMinutes;
  final TimeOfDay? initialTime;
  final ScheduleRepeat initialRepeat;
  @override
  ConsumerState<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<PlanEditor> {
  final title = TextEditingController();
  final requestId = FeatureActions.uuid.v4();
  String? hobbyId;
  bool titleEdited = false, repeatExpanded = false;
  late DateTime date, until;
  late TimeOfDay time;
  late int minutes;
  late ScheduleRepeat repeat;
  @override
  void initState() {
    super.initState();
    hobbyId = widget.initialHobby;
    date = widget.initialDay ?? DateTime.now();
    time = widget.initialTime ?? TimeOfDay.now();
    minutes = widget.initialMinutes;
    repeat = widget.initialRepeat;
    repeatExpanded = repeat != ScheduleRepeat.none;
    until = DateTime(date.year, date.month, date.day + 28);
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  DateTime get start =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
  String defaultTitle(Hobby hobby) =>
      context.tr('Practice {0}').replaceAll('{0}', hobby.name);
  void selectHobby(Hobby hobby) {
    setState(() {
      hobbyId = hobby.id;
      if (!titleEdited || title.text.trim().isEmpty) {
        title.text = defaultTitle(hobby);
        titleEdited = false;
      }
    });
  }

  Future<void> chooseHobby(List<Hobby> hobbies) async {
    final result = await showDialog<Object>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: const AppText('Choose a hobby'),
        children: [
          SizedBox(
            width: double.maxFinite,
            height: (hobbies.length * 60.0).clamp(60, 320),
            child: ListView(
              children: [
                for (final hobby in hobbies)
                  ListTile(
                    leading: HobbyGlyph(hobby.icon),
                    title: Text(hobby.name),
                    selected: hobby.id == hobbyId,
                    onTap: () => Navigator.pop(dialog, hobby),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(dialog, true),
            icon: const Icon(Icons.add),
            label: const AppText('Create hobby'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result is Hobby) {
      selectHobby(result);
    } else if (result == true) {
      await showEditor(context, const HobbyEditor());
    }
  }

  Future<void> chooseDate({bool end = false}) async {
    final value = await showDatePicker(
      context: context,
      initialDate: end ? until : date,
      firstDate: end
          ? DateTime(date.year, date.month, date.day)
          : DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (end) {
        until = value;
      } else {
        date = value;
        if (until.isBefore(DateTime(date.year, date.month, date.day))) {
          until = DateTime(date.year, date.month, date.day + 28);
        }
      }
    });
  }

  Future<void> customDuration() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => _CustomDurationDialog(initialMinutes: minutes),
    );
    if (selected != null && mounted) setState(() => minutes = selected);
  }

  String dateText(DateTime value) => DateFormat(
    'EEE, d/M/y',
    AppStrings.of(context).languageCode,
  ).format(value);
  String repeatText() => context.tr(switch (repeat) {
    ScheduleRepeat.none => 'Repeat (optional)',
    ScheduleRepeat.daily => 'Every day',
    ScheduleRepeat.weekly => 'Every week',
  });

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(featureActionsProvider);
    final palette = context.hobbyPalette;
    return PopScope(
      canPop: !action.busy,
      child: AsyncPanel(
        value: ref.watch(hobbiesProvider),
        retry: () => ref.invalidate(hobbiesProvider),
        builder: (allHobbies) {
          final hobbies = allHobbies.where((h) => !h.archived).toList();
          if (hobbies.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: context.tr('Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                EmptyState(
                  title: 'Tạo sở thích trước',
                  description: 'Active và Interested đều có thể lên lịch.',
                  actionLabel: 'Tạo sở thích',
                  onAction: () => showEditor(context, const HobbyEditor()),
                ),
              ],
            );
          }
          final selected = hobbies.firstWhere(
            (h) => h.id == hobbyId,
            orElse: () => hobbies.first,
          );
          hobbyId = selected.id;
          if (!titleEdited && title.text != defaultTitle(selected)) {
            title.text = defaultTitle(selected);
          }
          final visible = hobbies.take(3).toList();
          if (!visible.any((h) => h.id == selected.id)) {
            visible[visible.length - 1] = selected;
          }
          String? repeatError;
          var count = 1;
          try {
            count = scheduleOccurrences(start, repeat, until).length;
          } on DataFailure catch (error) {
            repeatError = error.message;
          }
          final labelStyle = Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
          Widget panel(Widget child) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: child,
          );
          final dateButton = _PickerButton(
            key: const ValueKey('schedule-date'),
            icon: Icons.calendar_month_outlined,
            label: dateText(date),
            onPressed: action.busy ? null : () => chooseDate(),
          );
          final timeButton = _PickerButton(
            key: const ValueKey('schedule-time'),
            icon: Icons.access_time,
            label: time.format(context),
            onPressed: action.busy
                ? null
                : () async {
                    final value = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (value != null && mounted) setState(() => time = value);
                  },
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      'Schedule focus time',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Close'),
                    onPressed: action.busy
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, box) {
                  final width = (box.maxWidth - 24) / 4;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final hobby in visible)
                        SizedBox(
                          width: width,
                          child: _HobbyTile(
                            label: hobby.name,
                            glyph: HobbyGlyph(
                              hobby.icon,
                              color: hobby.id == selected.id
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            selected: hobby.id == selected.id,
                            onTap: action.busy
                                ? null
                                : () => selectHobby(hobby),
                          ),
                        ),
                      SizedBox(
                        width: width,
                        child: _HobbyTile(
                          label: context.tr('Other'),
                          glyph: const Icon(Icons.add),
                          selected: false,
                          onTap: action.busy
                              ? null
                              : () => chooseHobby(hobbies),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('plan-title'),
                controller: title,
                enabled: !action.busy,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 70,
                onChanged: (_) => titleEdited = true,
                decoration: InputDecoration(
                  labelText: context.tr('Tên buổi luyện tập'),
                  counterText: '',
                  prefixIcon: const Icon(Icons.subject),
                  suffixIcon: IconButton(
                    tooltip: context.tr('Clear session name'),
                    onPressed: action.busy
                        ? null
                        : () {
                            title.clear();
                            titleEdited = true;
                          },
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (MediaQuery.textScalerOf(context).scale(14) > 20) ...[
                dateButton,
                const SizedBox(height: 8),
                timeButton,
              ] else
                Row(
                  children: [
                    Expanded(flex: 3, child: dateButton),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: timeButton),
                  ],
                ),
              const SizedBox(height: 16),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 8),
                        AppText('Duration', style: labelStyle),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (value, label) in [
                          (15, '15m'),
                          (30, '30m'),
                          (60, '1 hour'),
                          (120, '2 hours'),
                        ])
                          ChoiceChip(
                            key: ValueKey('duration-$value'),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            label: AppText(label),
                            selected: minutes == value,
                            showCheckmark: false,
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: minutes == value
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            onSelected: action.busy
                                ? null
                                : (_) => setState(() => minutes = value),
                          ),
                        ActionChip(
                          key: const ValueKey('custom-duration'),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          avatar: const Icon(Icons.add, size: 16),
                          label: Text(
                            [15, 30, 60, 120].contains(minutes)
                                ? context.tr('Custom')
                                : context
                                      .tr('{0} min')
                                      .replaceAll('{0}', '$minutes'),
                          ),
                          onPressed: action.busy ? null : customDuration,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppText(
                      'Choose a preset or customize the duration',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      key: const ValueKey('schedule-repeat'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: action.busy
                          ? null
                          : () => setState(
                              () => repeatExpanded = !repeatExpanded,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.repeat, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(repeatText())),
                            Icon(
                              repeatExpanded
                                  ? Icons.expand_less
                                  : Icons.chevron_right,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (repeatExpanded) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final value in ScheduleRepeat.values)
                            ChoiceChip(
                              key: ValueKey('repeat-${value.name}'),
                              label: AppText(switch (value) {
                                ScheduleRepeat.none => 'Does not repeat',
                                ScheduleRepeat.daily => 'Every day',
                                ScheduleRepeat.weekly => 'Every week',
                              }),
                              selected: repeat == value,
                              onSelected: action.busy
                                  ? null
                                  : (_) => setState(() => repeat = value),
                            ),
                        ],
                      ),
                      if (repeat != ScheduleRepeat.none) ...[
                        const SizedBox(height: 8),
                        _PickerButton(
                          key: const ValueKey('repeat-until'),
                          icon: Icons.event_outlined,
                          label: '${context.tr('Until')}: ${dateText(until)}',
                          onPressed: action.busy
                              ? null
                              : () => chooseDate(end: true),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          repeatError == null
                              ? context
                                    .tr(
                                      '{0} sessions · each can be managed separately',
                                    )
                                    .replaceAll('{0}', '$count')
                              : context.tr(repeatError),
                          style: TextStyle(
                            fontSize: 12,
                            color: repeatError == null
                                ? palette.muted
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              if (action.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AppText(
                    action.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Theme(
                data: Theme.of(context).copyWith(
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                child: HobbyButton(
                  key: const ValueKey('save-schedule'),
                  label: '✓ Create schedule',
                  isLoading: action.busy,
                  onPressed: action.busy
                      ? null
                      : () async {
                          final ok = await ref
                              .read(featureActionsProvider.notifier)
                              .plan(
                                hobbyId: selected.id,
                                title: title.text.trim().isEmpty
                                    ? defaultTitle(selected)
                                    : title.text,
                                startsAt: start,
                                minutes: minutes,
                                repeat: repeat,
                                until: until,
                                requestId: requestId,
                              );
                          if (ok && context.mounted) Navigator.pop(context);
                        },
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _CustomDurationDialog extends StatefulWidget {
  const _CustomDurationDialog({required this.initialMinutes});
  final int initialMinutes;
  @override
  State<_CustomDurationDialog> createState() => _CustomDurationDialogState();
}

class _CustomDurationDialogState extends State<_CustomDurationDialog> {
  final form = GlobalKey<FormState>();
  late final input = TextEditingController(
    text: widget.initialMinutes.toString(),
  );
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const AppText('Custom duration'),
    content: Form(
      key: form,
      child: TextFormField(
        key: const ValueKey('custom-minutes'),
        controller: input,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: context.tr('Minutes'),
          helperText: context.tr('1–1440 minutes (up to 24 hours)'),
        ),
        validator: (value) {
          final number = int.tryParse(value?.trim() ?? '');
          return number == null || number < 1 || number > maxScheduleMinutes
              ? context.tr('Enter a whole number from 1 to 1440.')
              : null;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const AppText('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, int.parse(input.text.trim()));
          }
        },
        child: const AppText('Apply'),
      ),
    ],
  );
}

class _HobbyTile extends StatelessWidget {
  const _HobbyTile({
    required this.label,
    required this.glyph,
    required this.selected,
    this.onTap,
  });
  final String label;
  final Widget glyph;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Tooltip(
      message: label,
      child: Material(
        color: selected
            ? context.hobbyPalette.soft
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : context.hobbyPalette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                glyph,
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      minimumSize: const Size(0, 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      side: BorderSide(color: context.hobbyPalette.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
