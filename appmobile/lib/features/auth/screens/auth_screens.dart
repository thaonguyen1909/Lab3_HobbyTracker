import '../../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../theme/hobby_theme.dart';
import '../../../theme/tokens.dart';
import '../../../viewmodels/auth_view_model.dart';
import '../../../widgets/hobby_app_bar.dart';
import '../../../widgets/hobby_button.dart';
import '../../../widgets/design_widgets.dart';
import '../../../widgets/hobby_text_field.dart';

bool _validEmail(String text) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text.trim());

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.title,
    required this.description,
    required this.children,
    this.showBack = false,
  });
  final String title;
  final String description;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final signin = !showBack, forgot = title == 'Reset password';
    return Scaffold(
      appBar: const HobbyAppBar(title: 'hobby', auth: true),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showBack) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () => context.go(RoutePaths.login),
                        icon: const Icon(Icons.chevron_left, size: 18),
                        label: const AppText('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  DesignHero(
                    eyebrow: signin
                        ? 'YOUR SPACE TO GROW'
                        : forgot
                        ? 'ACCOUNT RECOVERY'
                        : 'START SOMETHING WONDERFUL',
                    title: signin
                        ? 'Make time for\nwhat you love.'
                        : forgot
                        ? 'Find your way\nback.'
                        : 'Your hobbies.\nYour journey.',
                    subtitle: signin
                        ? 'A little progress goes a long way.'
                        : null,
                  ),
                  SizedBox(height: signin ? 36 : 36),
                  if (signin) ...[
                    const Eyebrow('WELCOME BACK'),
                    const SizedBox(height: 16),
                  ],
                  AppText(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  if (forgot) ...[
                    AppText(
                      description,
                      style: TextStyle(color: context.hobbyPalette.muted),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthNotice extends StatelessWidget {
  const _AuthNotice({required this.state});
  final AuthActionState state;
  @override
  Widget build(BuildContext context) {
    if (state.message == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: AppText(
          state.message!,
          key: const ValueKey('auth-notice'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: state.isError
                ? Theme.of(context).colorScheme.error
                : context.hobbyPalette.primaryDark,
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? emailError;
  String? passwordError;
  @override
  void initState() {
    super.initState();
    // Clear prior form feedback without clearing user drafts on request failure.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authViewModelProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      emailError = _validEmail(email.text) ? null : 'Nhập email hợp lệ.';
      passwordError = password.text.isNotEmpty ? null : 'Nhập mật khẩu.';
    });
    if (emailError != null || passwordError != null) return;
    await ref
        .read(authViewModelProvider.notifier)
        .emailSignIn(email.text, password.text);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authViewModelProvider);
    return _AuthLayout(
      title: 'Sign in',
      description: 'Đăng nhập để tiếp tục những sở thích của bạn.',
      children: [
        HobbyTextField(
          key: const ValueKey('login-email'),
          label: 'Email address',
          hintText: 'you@example.com',
          controller: email,
          enabled: !action.busy,
          errorText: emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.sm),
        HobbyTextField(
          key: const ValueKey('login-password'),
          label: 'Password',
          controller: password,
          enabled: !action.busy,
          obscureText: true,
          errorText: passwordError,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: action.busy
                ? null
                : () => context.go(RoutePaths.forgotPassword),
            child: const AppText('Forgot?'),
          ),
        ),
        HobbyButton(
          key: const ValueKey('login-submit'),
          label: 'Sign In ›',
          expand: true,
          isLoading: action.busy,
          onPressed: action.busy ? null : login,
        ),
        const SizedBox(height: AppSpacing.sm),
        HobbyButton(
          key: const ValueKey('login-google'),
          label: 'Continue with Google',
          icon: Icons.login,
          variant: HobbyButtonVariant.outline,
          expand: true,
          isLoading: action.busy,
          onPressed: action.busy
              ? null
              : () => ref.read(authViewModelProvider.notifier).googleSignIn(),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: action.busy ? null : () => context.go(RoutePaths.register),
          child: const AppText('New to hobby? Create account'),
        ),
        _AuthNotice(state: action),
      ],
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  String? nameError, emailError, passError, confirmationError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authViewModelProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> register() async {
    setState(() {
      final length = name.text.trim().runes.length;
      nameError = length >= 2 && length <= 80
          ? null
          : 'Tên phải có từ 2 đến 80 ký tự.';
      emailError = _validEmail(email.text) ? null : 'Nhập email hợp lệ.';
      passError = password.text.length >= 6
          ? null
          : 'Mật khẩu phải có ít nhất 6 ký tự.';
      confirmationError = password.text == confirmation.text
          ? null
          : 'Mật khẩu xác nhận không khớp.';
    });
    if (nameError != null ||
        emailError != null ||
        passError != null ||
        confirmationError != null) {
      return;
    }
    await ref
        .read(authViewModelProvider.notifier)
        .register(email.text, password.text, displayName: name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authViewModelProvider);
    return _AuthLayout(
      title: 'Create account',
      description: 'Tạo tài khoản để lưu hành trình của bạn trên đám mây.',
      showBack: true,
      children: [
        HobbyTextField(
          key: const ValueKey('register-name'),
          label: 'Your name',
          controller: name,
          enabled: !action.busy,
          errorText: nameError,
        ),
        const SizedBox(height: AppSpacing.sm),
        HobbyTextField(
          key: const ValueKey('register-email'),
          label: 'Email address',
          hintText: 'you@example.com',
          controller: email,
          enabled: !action.busy,
          keyboardType: TextInputType.emailAddress,
          errorText: emailError,
        ),
        const SizedBox(height: AppSpacing.sm),
        HobbyTextField(
          key: const ValueKey('register-password'),
          label: 'Password',
          controller: password,
          enabled: !action.busy,
          obscureText: true,
          errorText: passError,
        ),
        const SizedBox(height: AppSpacing.sm),
        HobbyTextField(
          key: const ValueKey('register-confirm'),
          label: 'Confirm password',
          controller: confirmation,
          enabled: !action.busy,
          obscureText: true,
          errorText: confirmationError,
        ),
        const SizedBox(height: AppSpacing.lg),
        HobbyButton(
          key: const ValueKey('register-submit'),
          label: 'Create Account',
          expand: true,
          isLoading: action.busy,
          onPressed: action.busy ? null : register,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: action.busy ? null : () => context.go(RoutePaths.login),
          child: const AppText('Already have an account? Sign in'),
        ),
        _AuthNotice(state: action),
      ],
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final email = TextEditingController();
  String? emailError;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(authViewModelProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> reset() async {
    setState(
      () => emailError = _validEmail(email.text) ? null : 'Nhập email hợp lệ.',
    );
    if (emailError != null) return;
    await ref.read(authViewModelProvider.notifier).reset(email.text);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authViewModelProvider);
    return _AuthLayout(
      title: 'Reset password',
      description: 'Enter your email address to receive a reset link.',
      showBack: true,
      children: [
        HobbyTextField(
          key: const ValueKey('reset-email'),
          label: 'Email address',
          hintText: 'you@example.com',
          controller: email,
          enabled: !action.busy,
          keyboardType: TextInputType.emailAddress,
          errorText: emailError,
        ),
        const SizedBox(height: AppSpacing.lg),
        HobbyButton(
          key: const ValueKey('reset-submit'),
          label: 'Request reset link',
          expand: true,
          isLoading: action.busy,
          onPressed: action.busy ? null : reset,
        ),
        _AuthNotice(state: action),
      ],
    );
  }
}
