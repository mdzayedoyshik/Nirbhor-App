import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── State ────────────────────────────────────────────────────────────────────
class ThemeState extends Equatable {
  final ThemeMode mode;
  const ThemeState(this.mode);

  @override
  List<Object> get props => [mode];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────
class ThemeCubit extends Cubit<ThemeState> {
  static const _prefKey = 'theme_mode';

  ThemeCubit() : super(const ThemeState(ThemeMode.system));

  /// Load persisted preference; call once after construction.
  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    final mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    emit(ThemeState(mode));
  }

  /// Change theme and persist the selection.
  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefKey, value);
    emit(ThemeState(mode));
  }

  Future<void> toggleTheme() async {
    final next =
        state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }
}
