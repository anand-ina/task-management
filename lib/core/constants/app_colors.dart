import 'package:flutter/material.dart';

class AppColors {
  // Common / Standard base colors
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white60 = Colors.white60;
  static const Color white54 = Colors.white54;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color black45 = Colors.black45;
  static const Color transparent = Colors.transparent;
  static const Color grey = Colors.grey;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;
  static const Color orange = Colors.orange;
  static const Color amber = Colors.amber;
  static const Color purple = Colors.purple;
  static const Color teal = Colors.teal;
  static const Color indigo = Colors.indigo;
  static const Color cyan = Colors.cyan;
  static const Color pink = Colors.pink;
  static const Color deepPurple = Colors.deepPurple;
  static const Color amberAccent = Colors.amberAccent;
  static const Color blueAccent = Colors.blueAccent;

  // Material Grey Shades
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Brand colors
  static const Color primaryNavy = Color(0xFF132A50);
  static const Color primaryRed = Color(0xFFB91C1C);
  static const Color primaryRedDark = Color(0xFF991B1B);
  static const Color maroon = Color(0xFF8B1D24);
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyCard = Color(0xFF1E293B);
  static const Color navyHeader = Color(0xFF0B132B);
  static const Color tealHeader = Color(0xFF007580);
  static const Color tealLight = Color(0xFFE6FFFA);

  // Status colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color neutralGray = Color(0xFF64748B);

  // Palette Tints
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF090D16);

  static const Color blue50 = Color(0xFFDBEAFE);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue800 = Color(0xFF1E40AF);
  static const Color blue900 = Color(0xFF1E3A8A);
  static const Color blueDark = Color(0xFF1E3A8A);
  static const Color blueLight = Color(0xFFDBEAFE);

  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red400 = Color(0xFFF87171);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red800 = Color(0xFF991B1B);
  static const Color red900 = Color(0xFF7F1D1D);
  static const Color red950 = Color(0xFF450A0A);
  static const Color redLight = Color(0xFFFEE2E2);
  static const Color rose = Color(0xFFF43F5E);

  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green200 = Color(0xFFBBF7D0);
  static const Color green300 = Color(0xFF86EFAC);
  static const Color green400 = Color(0xFF4ADE80);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);
  static const Color green800 = Color(0xFF166534);
  static const Color green900 = Color(0xFF14532D);
  static const Color greenLight = Color(0xFFDCFCE7);

  static const Color yellow100 = Color(0xFFFEF08A);
  static const Color yellow200 = Color(0xFFFEF3C7);
  static const Color yellow800 = Color(0xFF854D0E);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  static const Color amberDark = Color(0xFFB45309);
  static const Color amberLight = Color(0xFFFEF3C7);

  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange800 = Color(0xFF9A3412);

  static const _CallableColor textMuted = _CallableColor(0xFF94A3B8);

  // Light Mode palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCardBg = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark Mode palette
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkCardBg = Color(0xFF131C2E);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // App Bar palette - Strictly Black & White only
  static const Color appBarLight = Colors.white;
  static const Color appBarDark = Colors.black;

  /// Dynamic App Bar background color strictly white or black
  static Color appBarBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? appBarDark
        : appBarLight;
  }

  // Button colors
  static const Color buttonPrimary = Color(0xFF1E40AF); // Light Mode (Blue)
  static const Color buttonPrimaryDark = Color(0xFF3B82F6); // Dark Mode (Blue)

  /// App-level dynamic button color matching current theme
  static Color button(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? buttonPrimaryDark
        : buttonPrimary;
  }

  /// App-level dynamic circular progress indicator color matching current theme
  static Color progressIndicator(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? buttonPrimaryDark
        : buttonPrimary;
  }

  // Context-aware dynamic helpers
  static Color scaffoldBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBg : lightBg;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCardBg : lightCardBg;
  }

  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCardBg : lightCardBg;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;
  }

  static Color subtleBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate700 : slate200;
  }

  static Color subtleBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate900 : slate100;
  }

  static Color chipBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  }

  /// Theme-adaptive accent blue (light: #2563EB, dark: #60A5FA)
  static Color accentBlue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? blue400
        : blue600;
  }

  /// Theme-adaptive deep link/role blue (light: #1E3A8A, dark: #60A5FA)
  static Color linkBlue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? blue400
        : blue900;
  }

  /// Theme-adaptive status badge colors
  static Color badgeYellowBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate700 : yellow200;
  }

  static Color badgeYellowFg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFBBF24) : amber700;
  }

  static Color badgeOrangeBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate700 : orange100;
  }

  static Color badgeOrangeFg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFB923C) : orange800;
  }

  static Color badgeBlueBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate800 : blue50;
  }

  static Color badgeBlueFg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? blue400 : blue700;
  }

  static Color badgeGreenBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate800 : const Color(0xFFDCFCE7);
  }

  static Color badgeGreenFg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);
  }

  static Color badgeRedBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? slate800 : const Color(0xFFFEE2E2);
  }

  /// Dynamic primary brand color matching current theme
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? primaryRed
        : primaryNavy;
  }

  /// Scaffold background dynamic helper
  static Color background(BuildContext context) {
    return scaffoldBg(context);
  }

  static Color badgeRedFg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF87171) : red700;
  }
}

class _CallableColor extends Color {
  const _CallableColor(super.value);

  Color call([BuildContext? context]) {
    if (context == null) return this;
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
  }
}
