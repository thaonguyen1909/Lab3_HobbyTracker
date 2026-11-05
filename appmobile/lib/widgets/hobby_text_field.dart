import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';

import '../theme/hobby_theme.dart';
import '../theme/tokens.dart';

/// C02 — externally controlled draft; an error never clears the text.
/// Password visibility is an actual reversible interaction, not a placeholder.
class HobbyTextField extends StatefulWidget {
  const HobbyTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.enabled = true,
    this.obscureText = false,
    this.onChanged,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;

  @override
  State<HobbyTextField> createState() => _HobbyTextFieldState();
}

class _HobbyTextFieldState extends State<HobbyTextField> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.hobbyPalette;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          AppText(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (widget.label.isNotEmpty) const SizedBox(height: 7),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: widget.obscureText && !_passwordVisible,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          style: theme.textTheme.bodyMedium,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            counterText: widget.maxLength == null ? null : '',
            hintText: widget.hintText == null
                ? null
                : context.tr(widget.hintText!),
            errorText: widget.errorText == null
                ? null
                : context.tr(widget.errorText!),
            constraints: const BoxConstraints(minHeight: AppSizes.minTap),
            suffixIcon: widget.obscureText
                ? IconButton(
                    key: const ValueKey('password-visibility'),
                    tooltip: context.tr(
                      _passwordVisible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                    ),
                    onPressed: widget.enabled
                        ? () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          )
                        : null,
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: palette.muted,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
