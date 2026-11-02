import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import '../theme/hobby_theme.dart';
import '../theme/tokens.dart';
import 'figma_assets.dart';

class HobbyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HobbyAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.name,
    this.auth = false,
  });
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final String? name;
  final bool auth;
  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBar);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = name?.trim().isNotEmpty == true
        ? name!
        : context.tr('Hobby Explorer');
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(
                context.figmaStyle.variant == AppThemeVariant.cyber ? 0 : 8,
              ),
            ),
            child: FigmaIcon(
              'imgIconLeaf1',
              size: 22,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          AppText(
            'hobby',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 6),
          AppText(
            '·',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          if (auth)
            Flexible(
              child: AppText(
                'GROW AT YOUR OWN PACE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: context.hobbyPalette.muted,
                ),
              ),
            )
          else ...[
            Flexible(
              fit: FlexFit.tight,
              child: Text(
                display,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: context.hobbyPalette.muted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 17,
              backgroundColor: context.hobbyPalette.soft,
              child: Text(
                display.characters.first.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
