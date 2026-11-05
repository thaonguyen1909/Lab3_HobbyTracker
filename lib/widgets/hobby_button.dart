import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/hobby_theme.dart';
import '../theme/tokens.dart';

enum HobbyButtonVariant { primary, secondary, outline, danger }

/// C01 — visible idle/pressed/disabled/loading states. The pressed/focus states
/// are handled by Material Ink. A pending action cannot be fired twice.
class HobbyButton extends StatelessWidget {
  const HobbyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = HobbyButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expand = false,
    this.translateLabel = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final HobbyButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool expand;
  final bool translateLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = context.hobbyPalette;
    final enabled = isLoading ? null : onPressed;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: translateLabel
              ? AppText(label, textAlign: TextAlign.center)
              : Text(label, textAlign: TextAlign.center),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.figmaStyle.controlRadius),
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, AppSizes.minTap)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      shape: WidgetStatePropertyAll(shape),
    );
    final Widget button = switch (variant) {
      HobbyButtonVariant.primary => FilledButton(
        onPressed: enabled,
        style: style,
        child: content,
      ),
      HobbyButtonVariant.secondary => FilledButton(
        onPressed: enabled,
        style: style.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? palette.soft.withValues(alpha: 0.5)
                : palette.soft,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? palette.muted
                : palette.primaryDark,
          ),
        ),
        child: content,
      ),
      HobbyButtonVariant.outline => OutlinedButton(
        onPressed: enabled,
        style: style.copyWith(
          backgroundColor: WidgetStatePropertyAll(palette.cardSurface),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? palette.muted
                : palette.primaryDark,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
        ),
        child: content,
      ),
      HobbyButtonVariant.danger => OutlinedButton(
        onPressed: enabled,
        style: style.copyWith(
          backgroundColor: WidgetStatePropertyAll(palette.cardSurface),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? palette.muted
                : scheme.error,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.error.withValues(alpha: 0.25)),
          ),
        ),
        child: content,
      ),
    };
    return Semantics(
      button: true,
      enabled: enabled != null,
      label: translateLabel
          ? (isLoading
                ? '${context.tr(label)} — ${context.tr('working')}'
                : context.tr(label))
          : label,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
