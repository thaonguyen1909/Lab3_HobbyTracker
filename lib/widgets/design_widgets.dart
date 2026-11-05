import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import '../theme/hobby_theme.dart';
import 'figma_assets.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.tracking = 0});
  final String text;
  final double tracking;
  @override
  Widget build(BuildContext context) => AppText(
    text,
    style: TextStyle(
      fontSize: 10,
      height: 1.4,
      fontWeight: FontWeight.w700,
      letterSpacing: tracking,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, this.title, required this.text});
  final String? title;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.hobbyPalette.soft,
      border: Border.all(color: context.hobbyPalette.border),
      borderRadius: BorderRadius.circular(context.figmaStyle.controlRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          AppText(
            title!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
        ],
        AppText(
          text,
          style: TextStyle(
            fontSize: 12,
            height: 17 / 12,
            color: context.hobbyPalette.muted,
          ),
        ),
      ],
    ),
  );
}

class DesignHero extends StatelessWidget {
  const DesignHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.action,
    this.height = 166,
  });
  final String eyebrow, title;
  final String? subtitle;
  final Widget? action;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: height),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.hobbyPalette.heroStart,
      border: context.figmaStyle.variant == AppThemeVariant.cyber
          ? Border.all(color: context.hobbyPalette.border)
          : null,
      borderRadius: BorderRadius.circular(
        context.figmaStyle.variant == AppThemeVariant.cyber ? 0 : 21,
      ),
      boxShadow: context.figmaStyle.variant == AppThemeVariant.energetic
          ? [const BoxShadow(color: Color(0xFFE5C99F), offset: Offset(0, 4))]
          : null,
    ),
    child: Stack(
      children: [
        const Positioned(top: 5, right: -10, child: ThemeMotif()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(eyebrow, tracking: 1.2),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text.rich(
                TextSpan(
                  children: [
                    for (final (i, line)
                        in context.tr(title).split('\n').indexed)
                      TextSpan(
                        text: '${i == 0 ? '' : '\n'}$line',
                        style: TextStyle(
                          color: i > 0 && eyebrow == 'MAKE TIME FOR YOU'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 27,
                  height: 29 / 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              AppText(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  height: 17 / 12,
                  color: context.hobbyPalette.muted,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ],
    ),
  );
}

class DesignChoice extends StatelessWidget {
  const DesignChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected
          ? context.hobbyPalette.soft
          : context.hobbyPalette.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.figmaStyle.controlRadius),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : context.hobbyPalette.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.figmaStyle.controlRadius),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '${selected ? '✓ ' : ''}${context.tr(label)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                AppText(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.hobbyPalette.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
