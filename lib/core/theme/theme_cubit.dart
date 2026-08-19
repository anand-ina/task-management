import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/preferences_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light) {
    loadSavedTheme();
  }

  Future<void> loadSavedTheme() async {
    final modeStr = await PreferencesService().getThemeMode();
    switch (modeStr) {
      case 'dark':
        emit(ThemeMode.dark);
        break;
      case 'system':
        emit(ThemeMode.system);
        break;
      case 'light':
      default:
        emit(ThemeMode.light);
        break;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    String modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';
    if (mode == ThemeMode.system) modeStr = 'system';
    await PreferencesService().saveThemeMode(modeStr);
  }

  Future<void> toggleLightDark() async {
    if (state == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
