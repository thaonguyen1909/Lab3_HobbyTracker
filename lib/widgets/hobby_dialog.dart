import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'hobby_button.dart';

/// C06 — cancel/confirm, including pending/disabled state. The caller owns
/// network state; this widget never fabricates success or dismisses on submit.
class HobbyDialog extends StatelessWidget {
  const HobbyDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.isSubmitting = false,
    this.confirmLabel = 'Xác nhận',
    this.isDangerous = false,
  });
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final bool isSubmitting;
  final String confirmLabel;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: AppText(title, style: Theme.of(context).textTheme.titleLarge),
    content: SingleChildScrollView(child: AppText(message)),
    actionsPadding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.md,
    ),
    actions: [
      HobbyButton(
        label: 'Hủy',
        variant: HobbyButtonVariant.outline,
        onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
      ),
      HobbyButton(
        label: confirmLabel,
        variant: isDangerous
            ? HobbyButtonVariant.danger
            : HobbyButtonVariant.primary,
        isLoading: isSubmitting,
        onPressed: isSubmitting ? null : onConfirm,
      ),
    ],
  );
}
