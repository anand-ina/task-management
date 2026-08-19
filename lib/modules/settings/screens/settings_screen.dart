import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/language_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const CustomLeftDrawer(currentRoute: '/preferences'),
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.settings,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              s.appearanceSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 700;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAppearanceCard(context, s, isDark)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildLanguageCard(context, s, isDark)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildAppearanceCard(context, s, isDark),
                      const SizedBox(height: 20),
                      _buildLanguageCard(context, s, isDark),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, AppStrings s, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.appearance,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.appearanceSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              s.themeMode,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),

            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, currentMode) {
                return Column(
                  children: [
                    _buildThemeRadioTile(
                      context,
                      title: s.themeLight,
                      icon: Icons.light_mode_outlined,
                      iconColor: Colors.amber,
                      mode: ThemeMode.light,
                      groupValue: currentMode,
                    ),
                    const SizedBox(height: 8),
                    _buildThemeRadioTile(
                      context,
                      title: s.themeDark,
                      icon: Icons.dark_mode_outlined,
                      iconColor: Colors.amber,
                      mode: ThemeMode.dark,
                      groupValue: currentMode,
                    ),
                    const SizedBox(height: 8),
                    _buildThemeRadioTile(
                      context,
                      title: s.themeSystem,
                      icon: Icons.desktop_windows_outlined,
                      iconColor: Colors.grey,
                      mode: ThemeMode.system,
                      groupValue: currentMode,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeRadioTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required ThemeMode mode,
    required ThemeMode groupValue,
  }) {
    final isSelected = mode == groupValue;

    return InkWell(
      onTap: () {
        context.read<ThemeCubit>().setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFB91C1C) : Colors.black12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFB91C1C) : Colors.grey,
                  width: isSelected ? 5 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, AppStrings s, bool isDark) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.language,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.languageSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            BlocBuilder<LanguageCubit, Locale>(
              builder: (context, currentLocale) {
                final langCode = currentLocale.languageCode;

                return Column(
                  children: [
                    _buildLangRadioTile(
                      context,
                      title: s.langEnglish,
                      langCode: 'en',
                      groupValue: langCode,
                    ),
                    const SizedBox(height: 8),
                    _buildLangRadioTile(
                      context,
                      title: s.langTelugu,
                      langCode: 'te',
                      groupValue: langCode,
                    ),
                    const SizedBox(height: 8),
                    _buildLangRadioTile(
                      context,
                      title: s.langHindi,
                      langCode: 'hi',
                      groupValue: langCode,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangRadioTile(
    BuildContext context, {
    required String title,
    required String langCode,
    required String groupValue,
  }) {
    final isSelected = langCode == groupValue;

    return InkWell(
      onTap: () {
        context.read<LanguageCubit>().setLanguage(langCode);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFB91C1C) : Colors.black12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFB91C1C) : Colors.grey,
                  width: isSelected ? 5 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'abc',
                style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
