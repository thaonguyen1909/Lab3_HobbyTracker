import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/tokens.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../widgets/async_states.dart';
import '../../../widgets/hobby_button.dart';
import '../../../widgets/hobby_dialog.dart';

/// Intentionally not a bypass; authenticated routes stay closed while checking.
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: LoadingState(label: 'Đang xác minh phiên đăng nhập…'),
      ),
    ),
  );
}

class AuthFailureScreen extends ConsumerWidget {
  const AuthFailureScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authViewModelProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ErrorState(
                  message:
                      'Không thể đồng bộ hồ sơ tài khoản. Kiểm tra mạng, Firestore Rules và thử lại.',
                  onRetry: () => ref.invalidate(authSessionProvider),
                ),
                const SizedBox(height: AppSpacing.md),
                HobbyButton(
                  label: 'Đổi tài khoản',
                  expand: true,
                  variant: HobbyButtonVariant.outline,
                  isLoading: status.busy,
                  onPressed: status.busy
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (dialogContext) => HobbyDialog(
                            title: 'Đổi tài khoản?',
                            message:
                                'Đăng xuất phiên hiện tại để đăng nhập tài khoản khác.',
                            confirmLabel: 'Đăng xuất',
                            onConfirm: () {
                              final vm = ref.read(
                                authViewModelProvider.notifier,
                              );
                              Navigator.pop(dialogContext);
                              vm.signOut();
                            },
                          ),
                        ),
                ),
                if (status.isError && status.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: AppText(
                      status.message!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
