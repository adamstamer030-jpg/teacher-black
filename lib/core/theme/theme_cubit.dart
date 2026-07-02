import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_colors.dart';
import '../../data/repositories/settings_repository.dart';

class ThemeState {
  final ThemeMode mode;
  final String colorName;
  final double fontScale;

  const ThemeState({
    this.mode = ThemeMode.light,
    this.colorName = 'بنفسجي',
    this.fontScale = 1.0,
  });

  Color get seedColor => AppColors.appSeedColors[colorName] ?? AppColors.primary;

  ThemeState copyWith({ThemeMode? mode, String? colorName, double? fontScale}) =>
      ThemeState(
        mode: mode ?? this.mode,
        colorName: colorName ?? this.colorName,
        fontScale: fontScale ?? this.fontScale,
      );
}

class ThemeCubit extends Cubit<ThemeState> {
  final SettingsRepository settingsRepository;
  ThemeCubit(this.settingsRepository) : super(const ThemeState()) {
    _load();
  }

  Future<void> _load() async {
    final modeStr = await settingsRepository.get(SettingsRepository.keyThemeMode);
    final colorStr = await settingsRepository.get(SettingsRepository.keySeedColor);
    final fontStr = await settingsRepository.get(SettingsRepository.keyFontScale);

    if (isClosed) return;

    final mode = switch (modeStr) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };

    emit(state.copyWith(
      mode: mode,
      colorName: colorStr ?? state.colorName,
      fontScale: double.tryParse(fontStr ?? '') ?? state.fontScale,
    ));
  }

  Future<void> setDarkMode(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(mode: mode));
    await settingsRepository.set(
        SettingsRepository.keyThemeMode, isDark ? 'dark' : 'light');
  }

  Future<void> setColor(String colorName) async {
    emit(state.copyWith(colorName: colorName));
    await settingsRepository.set(SettingsRepository.keySeedColor, colorName);
  }

  Future<void> setFontScale(double scale) async {
    emit(state.copyWith(fontScale: scale));
    await settingsRepository.set(SettingsRepository.keyFontScale, scale.toString());
  }
}
