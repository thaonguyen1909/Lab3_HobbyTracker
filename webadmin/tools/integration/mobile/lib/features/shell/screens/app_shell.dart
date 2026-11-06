import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/app_navigation_bar.dart';
import '../../../viewmodels/data_providers.dart';
import '../../../models/hobby_data.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}
class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) ref.invalidate(flagsProvider);
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.invalidate(flagsProvider);
  }
  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(flagsProvider).valueOrNull ?? const RuntimeFlags();
    final blocked = flags.maintenance || flags.upgradeRequired || (!flags.community && widget.navigationShell.currentIndex == 1);
    final body = blocked ? SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.info_outline, size: 40), const SizedBox(height: 16),
        Text(flags.upgradeRequired ? 'Vui lòng cập nhật ứng dụng' : flags.maintenance ? 'Ứng dụng đang bảo trì' : 'Cộng đồng đang tạm đóng', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(flags.message.isNotEmpty ? flags.message : flags.upgradeRequired ? 'Phiên bản tối thiểu: ${flags.minVersion}' : 'Vui lòng quay lại sau.', textAlign: TextAlign.center),
        const SizedBox(height: 16), FilledButton(onPressed: () => ref.invalidate(flagsProvider), child: const Text('Kiểm tra lại')),
      ]),
    ))) : Column(children: [
      if (flags.message.isNotEmpty) SafeArea(bottom: false, child: MaterialBanner(content: Text(flags.message), actions: [TextButton(onPressed: () => ref.invalidate(flagsProvider), child: const Text('Làm mới'))])),
      Expanded(child: widget.navigationShell),
    ]);
    return Scaffold(body: body, bottomNavigationBar: AppNavigationBar(
      selectedIndex: widget.navigationShell.currentIndex,
      onSelected: (index) => widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex),
    ));
  }
}
