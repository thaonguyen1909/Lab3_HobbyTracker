import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LanguageStore {
  Future<String?> read();
  Future<void> write(String code);
}

class DeviceLanguageStore implements LanguageStore {
  @override
  Future<String?> read() async =>
      SharedPreferencesAsync().getString('app_language');
  @override
  Future<void> write(String code) async =>
      SharedPreferencesAsync().setString('app_language', code);
}

class LanguageState {
  const LanguageState({
    this.code = 'en',
    this.loading = true,
    this.saving = false,
    this.error,
  });
  final String code;
  final bool loading, saving;
  final String? error;
}

class LanguageController extends StateNotifier<LanguageState> {
  LanguageController(this.store) : super(const LanguageState()) {
    unawaited(restore());
  }
  final LanguageStore store;
  Future<void> restore() async {
    try {
      final code = await store.read();
      if (mounted) {
        state = LanguageState(code: code == 'vi' ? 'vi' : 'en', loading: false);
      }
    } catch (_) {
      if (mounted) state = const LanguageState(loading: false);
    }
  }

  Future<bool> select(String code) async {
    if (state.loading || state.saving || !['en', 'vi'].contains(code)) {
      return false;
    }
    final previous = state.code;
    state = LanguageState(code: previous, loading: false, saving: true);
    try {
      await store.write(code);
      if (!mounted) return false;
      state = LanguageState(code: code, loading: false);
      return true;
    } catch (_) {
      if (mounted) {
        state = LanguageState(
          code: previous,
          loading: false,
          error: 'Could not save language. Please try again.',
        );
      }
      return false;
    }
  }
}

final languageStoreProvider = Provider<LanguageStore>(
  (ref) => DeviceLanguageStore(),
);
final languageProvider =
    StateNotifierProvider<LanguageController, LanguageState>(
      (ref) => LanguageController(ref.watch(languageStoreProvider)),
    );
