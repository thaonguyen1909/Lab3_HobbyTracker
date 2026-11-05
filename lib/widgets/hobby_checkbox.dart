import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// C10 — check states with a minimum 48dp hit area, including a tappable label.
class HobbyCheckbox extends StatelessWidget {
  const HobbyCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr(label),
    checked: value,
    enabled: enabled,
    child: InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: AppSizes.minTap,
            height: AppSizes.minTap,
            child: Checkbox(
              value: value,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    ),
  );
}
