import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/hobby_theme.dart';
import '../theme/tokens.dart';
import 'figma_assets.dart';

/// C04 Navigation: the Light design uses a flat white bar with a small mint
/// icon indicator, not Material 3's oversized navigation pill.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _tabs =
      <({String key, String label, IconData icon, IconData selectedIcon})>[
        (
          key: 'tab-home',
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_outlined,
        ),
        (
          key: 'tab-community',
          label: 'Community',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups_outlined,
        ),
        (
          key: 'tab-hobbies',
          label: 'My Hobbies',
          icon: Icons.favorite_border,
          selectedIcon: Icons.favorite_border,
        ),
        (
          key: 'tab-settings',
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.hobbyPalette;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(color: palette.cardSurface),
        child: SizedBox(
          key: const ValueKey('bottom-navigation'),
          height:
              AppSizes.navigation +
              (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                0,
                double.infinity,
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                for (var index = 0; index < _tabs.length; index++)
                  Expanded(
                    child: _NavigationTab(
                      key: ValueKey(_tabs[index].key),
                      label: _tabs[index].label,
                      icon: _tabs[index].icon,
                      selectedIcon: _tabs[index].selectedIcon,
                      selected: index == selectedIndex,
                      textColor: index == selectedIndex
                          ? palette.primaryDark
                          : palette.muted,
                      selectionColor: palette.soft,
                      onTap: () => onSelected(index),
                      theme: theme,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationTab extends StatelessWidget {
  const _NavigationTab({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.textColor,
    required this.selectionColor,
    required this.onTap,
    required this.theme,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final Color textColor;
  final Color selectionColor;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${context.tr(label)}, ${context.tr('tab')}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.figmaStyle.controlRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTap),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: AppSizes.navigationIconWidth,
                  height: AppSizes.navigationIconHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? selectionColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      context.figmaStyle.controlRadius,
                    ),
                  ),
                  child: FigmaIcon(
                    switch (label) {
                      'Home' => 'imgIconHome',
                      'Community' => 'imgIconLeaf',
                      'My Hobbies' => 'imgIconHeart',
                      _ => 'imgIconSettings',
                    },
                    color: textColor,
                    size: 19,
                  ),
                ),
                const SizedBox(height: AppSpacing.navGap),
                AppText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 14 / 12,
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
