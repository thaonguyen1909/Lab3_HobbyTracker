import '../../../l10n/language_controller.dart';
import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/hobby_data.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../viewmodels/data_providers.dart';
import '../../../viewmodels/feature_actions.dart';
import '../../../widgets/feature_widgets.dart';
import '../../../widgets/async_states.dart';
import '../../../widgets/hobby_button.dart';
import '../../../widgets/hobby_card.dart';
import '../../../widgets/design_widgets.dart';
import '../../../widgets/figma_assets.dart';
import '../../../widgets/hobby_checkbox.dart';
import '../../../widgets/hobby_text_field.dart';
import '../../../theme/tokens.dart';
import '../../../theme/hobby_theme.dart';
import '../../../app/router/route_paths.dart';
import '../../auth/screens/auth_settings_panel.dart';

AppPreferences effectivePreferences(AppPreferences value, String? name) =>
    value.displayName.trim().isEmpty
    ? value.update({
        'displayName': name?.trim().isNotEmpty == true
            ? name!
            : 'Hobby Tracker user',
      })
    : value;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final p = effectivePreferences(
      ref.watch(preferencesProvider).valueOrNull ?? const AppPreferences(),
      user?.displayName,
    );
    final sections = <String, (String, String, String)>{
      'profile': ('Profile & Account', 'Name, bio, avatar', 'imgIconUser'),
      'language': ('Language', 'English / Vietnamese', 'imgIconUser'),
      'apps': (
        'Connected Apps',
        'Music and search shortcuts',
        'imgIconHeadphones',
      ),
      'notifications': (
        'Notifications & Reminders',
        'Gentle activity and chat alerts',
        'imgIconBell',
      ),
      'hyper': ('Hyper Mode', 'Timer and focus preferences', 'imgIconClock'),
      'appearance': (
        'Appearance',
        'Switch between seven design themes',
        'imgIconPalette',
      ),
      'privacy': (
        'Privacy & Safety',
        'Messaging permissions and visibility',
        'imgIconLock',
      ),
    };
    return FeaturePage(
      title: 'Settings',
      screen: 'settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('ACCOUNT & PREFERENCES'),
          const SizedBox(height: 8),
          AppText('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          HobbyCard(
            onTap: () => context.push(RoutePaths.settingsDetail('profile')),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: hobbyColor(context, p.color),
                  child: Text(
                    p.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.displayName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        p.handle.isEmpty
                            ? 'Complete your profile'
                            : '@${p.handle}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.hobbyPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                FigmaIcon(
                  'imgIconEdit',
                  screen: 'settings',
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppText(
            'Personalize your space',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          HobbyCard(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
            child: Column(
              children: [
                for (final e in sections.entries)
                  InkWell(
                    onTap: () => context.push(RoutePaths.settingsDetail(e.key)),
                    borderRadius: BorderRadius.circular(
                      context.figmaStyle.controlRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.hobbyPalette.soft,
                              border: Border.all(
                                color: context.hobbyPalette.border,
                              ),
                              borderRadius: BorderRadius.circular(
                                context.figmaStyle.controlRadius,
                              ),
                            ),
                            child: FigmaIcon(
                              e.value.$3,
                              screen: 'settings',
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  e.value.$1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  e.value.$2,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.4,
                                    color: context.hobbyPalette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FigmaIcon(
                            'imgIconChevron',
                            screen: 'settings',
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const AuthSettingsPanel(),
        ],
      ),
    );
  }
}

class SettingsDetailScreen extends ConsumerWidget {
  const SettingsDetailScreen({super.key, required this.section});
  final String section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = RoutePaths.settingsSections[section];
    return FeaturePage(
      title: title ?? 'Settings',
      screen: 'settings-detail',
      back: RoutePaths.settings,
      child: section == 'language'
          ? const LanguagePanel()
          : title == null
          ? const ErrorState(message: 'Không có mục cài đặt này.')
          : AsyncPanel(
              value: ref.watch(preferencesProvider),
              retry: () => ref.invalidate(preferencesProvider),
              builder: (value) => PreferencesEditor(
                key: ValueKey(section),
                section: section,
                initial: effectivePreferences(
                  value,
                  ref.watch(currentUserProvider)?.displayName,
                ),
              ),
            ),
    );
  }
}

class PreferencesEditor extends ConsumerStatefulWidget {
  const PreferencesEditor({
    super.key,
    required this.section,
    required this.initial,
  });
  final String section;
  final AppPreferences initial;
  @override
  ConsumerState<PreferencesEditor> createState() => _PreferencesEditorState();
}

class _PreferencesEditorState extends ConsumerState<PreferencesEditor> {
  late AppPreferences value = widget.initial;
  Json? failedFields;
  late final name = TextEditingController(text: value.displayName),
      handle = TextEditingController(text: value.handle),
      bio = TextEditingController(text: value.bio);
  @override
  void dispose() {
    name.dispose();
    handle.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> update(Json fields) async {
    final previous = value;
    final candidate = value.update(fields);
    setState(() {
      value = candidate;
      failedFields = null;
    });
    if (widget.section != 'profile') {
      final ok = await ref
          .read(featureActionsProvider.notifier)
          .preferences(candidate);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          value = previous;
          failedFields = fields;
        });
      }
    }
  }

  Widget toggle(String label, bool selected, String key) => HobbyCheckbox(
    label: label,
    value: selected,
    enabled: !ref.watch(featureActionsProvider).busy,
    onChanged: (v) => update({key: v ?? false}),
  );
  Widget _themeCard(BuildContext context, AppThemeVariant theme, bool busy) {
    final data = HobbyTheme.forVariant(theme),
        selected = value.theme == theme.label;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: context.hobbyPalette.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            width: selected ? 2 : 1,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : context.hobbyPalette.border,
          ),
        ),
        child: InkWell(
          onTap: busy
              ? null
              : () async {
                  await update({'theme': theme.label});
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 54,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 112,
                    height: 20,
                    decoration: BoxDecoration(
                      color: data.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppText(
                  theme.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AppText(
                  selected ? '✓ Current' : 'Apply theme',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(featureActionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          {
            'profile': 'Profile & Account',
            'apps': 'Connected Apps',
            'notifications': 'Notifications',
            'hyper': 'Hyper Mode',
            'privacy': 'Privacy & Safety',
            'appearance': 'Appearance',
          }[widget.section]!,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        AppText(
          {
            'profile': 'Edit how your profile appears.',
            'apps':
                'Choose external shortcuts for Hyper Mode. This does not connect real accounts.',
            'notifications':
                'Choose which reminders and community updates you receive.',
            'hyper': 'Choose how the practice timer behaves.',
            'privacy':
                'Control your public profile and who can start a direct conversation.',
            'appearance':
                'Choose your own experience. Each theme has its own shapes, atmosphere, and navigation style. Your hobbies and progress stay unchanged.',
          }[widget.section]!,
          style: TextStyle(color: context.hobbyPalette.muted),
        ),
        const SizedBox(height: 24),
        if (widget.section == 'profile') ...[
          HobbyTextField(
            label: 'Display name',
            controller: name,
            enabled: !action.busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          HobbyTextField(
            label: 'Username',
            controller: handle,
            enabled: !action.busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          HobbyTextField(
            label: 'Bio',
            controller: bio,
            maxLines: 4,
            enabled: !action.busy,
          ),
          const SizedBox(height: AppSpacing.sm),
          const AppText(
            'Avatar color',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final key in hobbyColorKeys)
                IconButton(
                  tooltip: context.tr('Avatar ${context.tr(key)}'),
                  onPressed: action.busy ? null : () => update({'color': key}),
                  icon: Icon(
                    value.color == key ? Icons.check_circle : Icons.circle,
                    color: hobbyColor(context, key),
                    size: 30,
                  ),
                ),
            ],
          ),
        ],
        if (widget.section == 'apps') ...[
          AppText(
            'Music service',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          for (final e in {
            'spotify': 'Spotify',
            'youtube': 'YouTube',
          }.entries) ...[
            DesignChoice(
              label: e.value,
              selected: value.music == e.key,
              onTap: action.busy ? null : () => update({'music': e.key}),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 16),
          AppText(
            'Search service',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          for (final e in {
            'google': 'Google Search',
            'coccoc': 'Cốc Cốc',
          }.entries) ...[
            DesignChoice(
              label: e.value,
              selected: value.search == e.key,
              onTap: action.busy ? null : () => update({'search': e.key}),
            ),
            const SizedBox(height: 16),
          ],
          const InfoPanel(
            title: 'External shortcuts',
            text:
                'Services open outside Hobby Tracker. These preferences do not grant access to your music or search accounts.',
          ),
        ],
        if (widget.section == 'notifications') ...[
          toggle('Activity reminders', value.reminders, 'reminders'),
          DropdownButtonFormField<int>(
            initialValue: value.leadMinutes,
            decoration: InputDecoration(
              labelText: context.tr('Minutes before activity'),
            ),
            items: [
              for (final m in [0, 5, 15, 30, 60])
                DropdownMenuItem(value: m, child: AppText('$m minutes')),
            ],
            onChanged: action.busy ? null : (v) => update({'leadMinutes': v}),
          ),
          toggle('Chat notifications', value.messages, 'messages'),
          toggle('Group activity', value.groups, 'groups'),
          toggle('Weekly summary', value.weekly, 'weekly'),
          HobbyButton(
            label: 'Enable device notifications',
            onPressed: action.busy
                ? null
                : () =>
                      ref.read(featureActionsProvider.notifier).notifications(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const InboxPanel(),
        ],
        if (widget.section == 'hyper') ...[
          toggle('Auto-start timer', value.autoTimer, 'autoTimer'),
          toggle('Pause when leaving', value.pauseOnExit, 'pauseOnExit'),
          toggle('Completion sound', value.sound, 'sound'),
          const SizedBox(height: 16),
          const InfoPanel(
            title: 'Saved activity',
            text:
                'Finishing a Hyper Mode session stores its duration and notes in Home history.',
          ),
        ],
        if (widget.section == 'privacy') ...[
          toggle('Show my profile in People', value.visible, 'visible'),
          const SizedBox(height: 16),
          AppText(
            'Who can message you?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          DesignChoice(
            label: 'Everyone with an account',
            selected: value.allowMessages,
            onTap: action.busy ? null : () => update({'allowMessages': true}),
          ),
          const SizedBox(height: 16),
          DesignChoice(
            label: 'Nobody — pause direct messaging',
            selected: !value.allowMessages,
            onTap: action.busy ? null : () => update({'allowMessages': false}),
          ),
          const SizedBox(height: 32),
          const InfoPanel(
            text:
                'Both people must allow messaging to send direct messages. Existing conversations remain readable by their participants.',
          ),
        ],
        if (widget.section == 'appearance') ...[
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 8,
              runSpacing: 16,
              children: [
                for (final theme in AppThemeVariant.values)
                  SizedBox(
                    width: (c.maxWidth - 8) / 2,
                    child: _themeCard(context, theme, action.busy),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (failedFields != null)
          HobbyButton(
            key: const ValueKey('retry-preferences'),
            label: 'Retry saving preferences',
            onPressed: action.busy ? null : () => update(failedFields!),
          ),
        if (widget.section == 'profile')
          HobbyButton(
            key: const ValueKey('save-settings'),
            label: widget.section == 'profile'
                ? 'Save profile'
                : 'Save preferences',
            isLoading: action.busy,
            onPressed: action.busy
                ? null
                : () async {
                    final data = value.update({
                      'displayName': name.text.trim(),
                      'handle': handle.text.trim(),
                      'bio': bio.text.trim(),
                    });
                    final ok = await ref
                        .read(featureActionsProvider.notifier)
                        .preferences(data);
                    if (ok && mounted) setState(() => value = data);
                  },
          ),
        if (widget.section == 'profile') ...[
          const SizedBox(height: AppSpacing.xxl),
          const AuthSettingsPanel(compact: false),
          const SizedBox(height: 24),
          const ExpansionTile(
            title: AppText('Lab 3 — Báo cáo và kiểm thử'),
            subtitle: AppText('PDF, cấu hình Firebase và công cụ chẩn đoán'),
            children: [FirebaseDemoPanel()],
          ),
        ],
      ],
    );
  }
}

class InboxPanel extends ConsumerWidget {
  const InboxPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Section(
    title: 'Thông báo đã nhận',
    child: AsyncPanel(
      value: ref.watch(inboxProvider),
      retry: () => ref.invalidate(inboxProvider),
      builder: (items) => items.isEmpty
          ? const EmptyState(
              title: 'Chưa có thông báo',
              description:
                  'Thông báo gửi đến tài khoản này sẽ xuất hiện tại đây.',
            )
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    leading: Icon(
                      item.read
                          ? Icons.notifications_none
                          : Icons.notifications_active_outlined,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                    onTap: () async {
                      final uid = ref.read(ownerIdProvider);
                      if (uid != null) {
                        await ref
                            .read(featureActionsProvider.notifier)
                            .readNotification(item);
                      }
                      if (context.mounted) context.go(item.path);
                    },
                  ),
              ],
            ),
    ),
  );
}

class FirebaseDemoPanel extends ConsumerStatefulWidget {
  const FirebaseDemoPanel({super.key});
  @override
  ConsumerState<FirebaseDemoPanel> createState() => _FirebaseDemoPanelState();
}

class _FirebaseDemoPanelState extends ConsumerState<FirebaseDemoPanel> {
  final crash = TextEditingController();
  @override
  void dispose() {
    crash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(featureActionsProvider),
        flags = ref.watch(flagsProvider),
        diagnostic = ref.watch(diagnosticsProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'Báo cáo & dịch vụ',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AsyncPanel(
          value: ref.watch(hobbiesProvider),
          retry: () => ref.invalidate(hobbiesProvider),
          builder: (hobbies) => AsyncPanel(
            value: ref.watch(historyProvider),
            retry: () => ref.invalidate(historyProvider),
            builder: (records) => HobbyButton(
              label: 'Tạo báo cáo PDF',
              icon: Icons.picture_as_pdf_outlined,
              isLoading: action.busy,
              onPressed: action.busy
                  ? null
                  : () => ref
                        .read(featureActionsProvider.notifier)
                        .exportReport(hobbies, records),
            ),
          ),
        ),
        if (action.pdf != null) ...[
          const SizedBox(height: AppSpacing.sm),
          HobbyButton(
            label: 'Chia sẻ PDF',
            variant: HobbyButtonVariant.outline,
            onPressed: action.busy
                ? null
                : () => ref.read(featureActionsProvider.notifier).shareReport(),
          ),
          const SizedBox(height: AppSpacing.sm),
          HobbyButton(
            label: 'Tải PDF lên Cloud Storage',
            onPressed: action.busy
                ? null
                : () =>
                      ref.read(featureActionsProvider.notifier).uploadReport(),
          ),
        ],
        if (action.busy && action.pdf != null)
          LinearProgressIndicator(value: action.progress),
        if (action.receipt != null) ...[
          const SizedBox(height: AppSpacing.sm),
          const AppText('Đường dẫn tải xuống'),
          SelectableText(action.receipt!.url),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppText(
          'Cấu hình đang dùng',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        flags.when(
          loading: () => const LoadingState(),
          error: (e, s) => const AppText('Không tải được cấu hình.'),
          data: (f) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Community enabled: ${context.tr(f.community.toString())}',
              ),
              AppText('Feed limit: ${f.feedLimit}'),
              if (f.error != null) AppText(f.error!),
            ],
          ),
        ),
        HobbyButton(
          label: 'Tải lại cấu hình',
          variant: HobbyButtonVariant.outline,
          onPressed: () => ref.invalidate(flagsProvider),
        ),
        if (diagnostic != null)
          Semantics(
            liveRegion: true,
            child: AppText(
              diagnostic,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        AppText(
          'Crashlytics — kiểm thử có chủ đích',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const AppText(
          'Chỉ dành cho bản debug được bật quyền thử crash. Nhập CRASH rồi xác nhận; ứng dụng sẽ đóng.',
        ),
        HobbyTextField(label: 'Nhập CRASH', controller: crash),
        HobbyButton(
          label: 'Gửi test crash',
          variant: HobbyButtonVariant.danger,
          onPressed: action.busy
              ? null
              : () async {
                  if (crash.text != 'CRASH') return;
                  if (await confirmAction(
                        context,
                        'Đóng ứng dụng để test crash?',
                        'Chỉ tiếp tục nếu bạn đang kiểm thử Crashlytics.',
                        danger: true,
                      ) &&
                      context.mounted) {
                    await ref.read(featureActionsProvider.notifier).crashTest();
                  }
                },
        ),
      ],
    );
  }
}

class LanguagePanel extends ConsumerWidget {
  const LanguagePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'App language',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const AppText(
          'Choose the language used throughout the app. Your own content stays unchanged.',
        ),
        const SizedBox(height: 24),
        for (final entry in {'en': 'English', 'vi': 'Vietnamese'}.entries) ...[
          KeyedSubtree(
            key: ValueKey('language-${entry.key}'),
            child: DesignChoice(
              label: entry.value,
              selected: language.code == entry.key,
              onTap: language.loading || language.saving
                  ? null
                  : () async {
                      await ref
                          .read(languageProvider.notifier)
                          .select(entry.key);
                    },
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (language.saving) const LoadingState(),
        if (language.error != null)
          AppText(
            language.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const AppText(
          'Language is saved on this device, including the sign-in screen.',
        ),
      ],
    );
  }
}
