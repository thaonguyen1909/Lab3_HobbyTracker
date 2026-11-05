import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/screens/app_shell.dart';
import '../../features/hobbies/screens/hobbies_screens.dart';
import '../../features/practice/screens/practice_screens.dart';
import '../../features/community/screens/community_screens.dart';
import '../../features/community/screens/moments/moments_screen.dart';
import '../../features/community/screens/moments/moment_composer_screen.dart';
import '../../features/community/screens/moments/moment_viewer_screen.dart';
import '../../features/community/screens/moments/moment_alerts_screen.dart';
import '../../features/settings/screens/settings_screens.dart';
import '../../theme/tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/auth_view_model.dart';
import '../../features/auth/screens/auth_screens.dart';
import '../../features/auth/screens/auth_gates.dart';
import '../../widgets/async_states.dart';
import 'route_paths.dart';

/// React to auth stream changes without creating a new Router for each event.
class _AuthRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.listen(authSessionProvider, (previous, next) => refresh.refresh());
  final router = GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authSessionProvider);
      final path = state.matchedLocation;
      final isAuthRoute =
          path == RoutePaths.login ||
          path == RoutePaths.register ||
          path == RoutePaths.forgotPassword;
      if (auth.isLoading) {
        return path == RoutePaths.authLoading ? null : RoutePaths.authLoading;
      }
      if (auth.hasError) {
        return path == RoutePaths.authFailure ? null : RoutePaths.authFailure;
      }
      final user = auth.valueOrNull;
      if (user == null) return isAuthRoute ? null : RoutePaths.login;
      if (isAuthRoute ||
          path == RoutePaths.authLoading ||
          path == RoutePaths.authFailure) {
        return RoutePaths.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.authLoading,
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: RoutePaths.authFailure,
        builder: (context, state) => const AuthFailureScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'hyper',
                    builder: (context, state) => HyperScreen(
                      initialHobby: state.uri.queryParameters['hobby'],
                      initialPlan: state.uri.queryParameters['plan'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.feed,
                builder: (context, state) => const FeedScreen(),
              ),
              GoRoute(
                path: RoutePaths.groups,
                builder: (context, state) => const GroupsScreen(),
                routes: [
                  GoRoute(
                    path: ':groupId/moments/:momentId',
                    builder: (context, state) => MomentViewerScreen(
                      groupId: state.pathParameters['groupId']!,
                      momentId: state.pathParameters['momentId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: RoutePaths.moments,
                builder: (context, state) =>
                    MomentsScreen(groupId: state.uri.queryParameters['group']),
                routes: [
                  GoRoute(
                    path: 'alerts',
                    builder: (context, state) => const MomentAlertsScreen(),
                  ),
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => MomentComposerScreen(
                      groupId: state.uri.queryParameters['group'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: RoutePaths.activities,
                builder: (context, state) => const ActivitiesScreen(),
              ),
              GoRoute(
                path: RoutePaths.people,
                builder: (context, state) => const PeopleScreen(),
              ),
              GoRoute(
                path: RoutePaths.chats,
                builder: (context, state) => const ChatsScreen(),
              ),
              GoRoute(
                path: '/community/chat/:id',
                builder: (context, state) =>
                    ConversationScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.hobbies,
                builder: (context, state) => const HobbiesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        HobbyDetailScreen(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: ':section',
                    builder: (context, state) => SettingsDetailScreen(
                      section: state.pathParameters['section']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const AppText('Không tìm thấy trang')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ErrorState(
            message: 'Route không tồn tại: ${state.uri.path}',
            onRetry: () => context.go(RoutePaths.login),
          ),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
