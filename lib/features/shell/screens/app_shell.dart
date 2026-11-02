import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/hyper_view_model.dart';
import '../../../viewmodels/data_providers.dart';

import '../../../widgets/app_navigation_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: AppNavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onSelected: (index) {
        ref
            .read(hyperProvider.notifier)
            .onBackground(
              ref.read(preferencesProvider).valueOrNull?.pauseOnExit ?? true,
            );
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    ),
  );
}
