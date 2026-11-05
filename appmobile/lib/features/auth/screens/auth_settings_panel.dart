import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tokens.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../widgets/hobby_button.dart';
import '../../../widgets/feature_widgets.dart';
import '../../../theme/hobby_theme.dart';

/// Real Phase 02 account actions within the Lab 2 Settings screen.
class AuthSettingsPanel extends ConsumerWidget {
  const AuthSettingsPanel({super.key, this.compact = true});
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentUserProvider);
    final action = ref.watch(authViewModelProvider);
    if (session == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          AppText('Tài khoản', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            session.displayName?.isNotEmpty == true
                ? session.displayName!
                : context.tr('Hobby Tracker user'),
          ),
          if (session.email != null)
            Text(session.email!, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (!session.hasGoogle) ...[
            HobbyButton(
              key: const ValueKey('link-google'),
              label: 'Liên kết Google',
              variant: HobbyButtonVariant.outline,
              expand: true,
              onPressed: action.busy
                  ? null
                  : () async {
                      final accepted = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const AppText('Liên kết tài khoản Google?'),
                          content: const AppText(
                            'Chỉ liên kết Google có cùng email với tài khoản hiện tại, sau khi bạn xác nhận.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const AppText('Hủy'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const AppText('Tiếp tục'),
                            ),
                          ],
                        ),
                      );
                      if (!context.mounted) return;
                      if (accepted == true) {
                        await ref
                            .read(authViewModelProvider.notifier)
                            .linkGoogle();
                      }
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        HobbyButton(
          key: const ValueKey('sign-out'),
          label: '⇥ Sign Out',
          variant: HobbyButtonVariant.danger,
          expand: true,
          isLoading: action.busy,
          onPressed: action.busy
              ? null
              : () => showEditor(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        'Sign out?',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 32),
                      AppText(
                        'Your hobbies and history stay in your account. Signing out returns to the Sign In screen.',
                        style: TextStyle(color: context.hobbyPalette.muted),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: HobbyButton(
                              label: 'Cancel',
                              variant: HobbyButtonVariant.secondary,
                              onPressed: () => Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pop(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: HobbyButton(
                              label: 'Sign Out',
                              variant: HobbyButtonVariant.danger,
                              onPressed: () async {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                await ref
                                    .read(authViewModelProvider.notifier)
                                    .signOut();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        if (action.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: AppText(
              action.message!,
              style: TextStyle(
                color: action.isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
