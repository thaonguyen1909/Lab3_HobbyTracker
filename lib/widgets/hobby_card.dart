import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/hobby_theme.dart';
import '../theme/tokens.dart';

/// C03 — one card surface, border, radius and focus/pressed behaviour shared
/// by future Hobby/Schedule/Post/Event feature variants.
class HobbyCard extends StatelessWidget {
  const HobbyCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(AppSpacing.card),
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.figmaStyle.cardRadius);
    return Card(
      child: Semantics(
        label: semanticLabel == null ? null : context.tr(semanticLabel!),
        button: onTap != null,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            focusColor: context.hobbyPalette.soft,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
