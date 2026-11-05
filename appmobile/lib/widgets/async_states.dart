import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/hobby_theme.dart';
import '../theme/tokens.dart';
import 'hobby_button.dart';
import 'hobby_card.dart';
import 'figma_assets.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label = 'Đang tải dữ liệu'});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: context.tr(label),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppText(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.iconName = 'imgIconLeaf',
    this.onAction,
  });
  final String iconName;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.hobbyPalette;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: HobbyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FigmaIcon(
                iconName,
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              HobbyButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: HobbyButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 30),
          const SizedBox(height: AppSpacing.xs),
          AppText('Đã xảy ra lỗi', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          AppText(message, style: theme.textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            HobbyButton(
              label: 'Thử lại',
              onPressed: onRetry,
              icon: Icons.refresh,
              variant: HobbyButtonVariant.outline,
            ),
          ],
        ],
      ),
    );
  }
}
