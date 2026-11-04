import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';
import '../theme/hobby_theme.dart';
import '../viewmodels/runtime_controller.dart';
import '../viewmodels/feature_actions.dart';
import 'hobby_card.dart';
import 'async_states.dart';
import 'hobby_app_bar.dart';
import 'hobby_dialog.dart';
import 'figma_assets.dart';
import '../viewmodels/auth_view_model.dart';
import '../models/hobby_data.dart';

const hobbyIcons = <String, IconData>{
  'spark': Icons.auto_awesome_outlined,
  'camera': Icons.camera_alt_outlined,
  'music': Icons.music_note_outlined,
  'book': Icons.menu_book_outlined,
  'palette': Icons.palette_outlined,
  'fitness': Icons.fitness_center,
  'sports': Icons.sports_tennis,
  'code': Icons.code,
  'garden': Icons.local_florist_outlined,
  'cook': Icons.restaurant_outlined,
  'chess': Icons.extension_outlined,
  'travel': Icons.explore_outlined,
};
const hobbyColorKeys = ['mint', 'orange', 'blue', 'purple', 'pink', 'gold'];

Color hobbyColor(BuildContext context, String key) => switch (key) {
  'blue' => AppColors.hobbyBlue,
  'orange' => AppColors.hobbyOrange,
  'purple' => AppColors.hobbyPurple,
  'pink' => AppColors.hobbyPink,
  'gold' => AppColors.hobbyGold,
  _ => Theme.of(context).colorScheme.primary,
};

class FeaturePage extends ConsumerStatefulWidget {
  const FeaturePage({
    super.key,
    required this.title,
    required this.screen,
    required this.child,
    this.back,
    this.scrollable = true,
    this.actions = const [],
  });
  final String title, screen;
  final Widget child;
  final String? back;
  final bool scrollable;
  final List<Widget> actions;
  @override
  ConsumerState<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends ConsumerState<FeaturePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(runtimeControllerProvider).screen(widget.screen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(featureActionsProvider);
    return Scaffold(
      appBar: HobbyAppBar(
        title: widget.title,
        name: ref.watch(currentUserProvider)?.displayName,
        onBack: widget.back == null
            ? null
            : () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(widget.back!);
                }
              },
        actions: widget.actions,
      ),
      body: SafeArea(
        child: widget.scrollable
            ? SingleChildScrollView(
                key: ValueKey('screen-${widget.screen}'),
                padding: const EdgeInsets.all(AppSpacing.page),
                child: pageContent(context, status),
              )
            : Padding(
                key: ValueKey('screen-${widget.screen}'),
                padding: const EdgeInsets.all(AppSpacing.page),
                child: pageContent(context, status),
              ),
      ),
    );
  }

  Widget pageContent(BuildContext context, FeatureActionState status) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (status.error != null) ...[
        Semantics(
          liveRegion: true,
          child: HobbyCard(
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    status.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Dismiss error'),
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      ref.read(featureActionsProvider.notifier).clearFeedback(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (widget.back != null) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(widget.back!);
              }
            },
            icon: FigmaIcon(
              'imgIconBack',
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: AppText(
              widget.back!.startsWith('/settings')
                  ? 'Settings'
                  : widget.back!.startsWith('/hobbies')
                  ? 'My Hobbies'
                  : widget.back!.startsWith('/community')
                  ? 'All chats'
                  : 'Home',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      if (widget.scrollable) widget.child else Expanded(child: widget.child),
    ],
  );
}

class AsyncPanel<T> extends StatelessWidget {
  const AsyncPanel({
    super.key,
    required this.value,
    required this.builder,
    required this.retry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const LoadingState(),
    error: (e, _) => ErrorState(
      message: e is DataFailure
          ? e.message
          : 'Không tải được dữ liệu. Vui lòng thử lại.',
      onRetry: retry,
    ),
    data: builder,
  );
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    this.action,
    required this.child,
  });
  final String title;
  final Widget? action;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String label = 'Xác nhận',
  bool danger = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => HobbyDialog(
        title: title,
        message: message,
        confirmLabel: label,
        isDangerous: danger,
        onConfirm: () => Navigator.pop(c, true),
      ),
    ) ??
    false;
Future<void> showEditor(
  BuildContext context,
  Widget child, {
  bool showClose = true,
  bool dismissible = true,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  isDismissible: dismissible,
  enableDrag: dismissible,
  useRootNavigator: true,
  useSafeArea: true,
  builder: (c) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Stack(
        children: [
          Padding(padding: const EdgeInsets.only(top: 4), child: child),
          if (showClose)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton.filledTonal(
                tooltip: context.tr('Close'),
                onPressed: () => Navigator.pop(c),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: context.hobbyPalette.soft,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    ),
  ),
);
String dateLabel(DateTime value, BuildContext context) => DateFormat.yMd(
  AppStrings.of(context).languageCode,
).add_Hm().format(value.toLocal());

class HobbyGlyph extends StatelessWidget {
  const HobbyGlyph(this.icon, {super.key, this.size = 24, this.color});
  final String icon;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => FigmaIcon(
    switch (icon) {
      'camera' => 'imgIconCamera',
      'music' => 'imgIconMusic',
      'book' => 'imgIconBook',
      'palette' => 'imgIconPalette',
      'fitness' => 'imgIconFitness',
      'sports' => 'imgIconBall',
      'code' => 'imgIconLaptop',
      'garden' => 'imgIconFlower',
      'cook' => 'imgIconChef',
      'chess' => 'imgIconChess',
      'travel' => 'imgIconSend',
      _ => 'imgIconLeaf3',
    },
    screen: 'create',
    size: size,
    color: color ?? Theme.of(context).colorScheme.primary,
  );
}
