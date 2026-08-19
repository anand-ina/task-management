import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/preferences_service.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en')) {
    loadSavedLanguage();
  }

  Future<void> loadSavedLanguage() async {
    final langCode = await PreferencesService().getLanguage();
    emit(Locale(langCode));
  }

  Future<void> setLanguage(String langCode) async {
    emit(Locale(langCode));
    await PreferencesService().saveLanguage(langCode);
  }
}
