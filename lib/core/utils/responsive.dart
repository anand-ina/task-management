import 'package:flutter/widgets.dart';

/// Central breakpoints for phone / tablet layouts.
///
/// * Phone  : shortest side < 600
/// * Tablet : shortest side >= 600 (portrait or landscape)
///
/// Use [Responsive.columnsFor] with the width coming from a LayoutBuilder so
/// the value is correct even when the persistent tablet sidebar takes space.
class Responsive {
  Responsive._();

  /// Shortest-side breakpoint that classifies a device as a tablet.
  static const double tabletShortestSide = 600;

  /// Minimum window width at which the navigation drawer is pinned as a
  /// persistent sidebar (tablet portrait 768+ and every tablet landscape).
  static const double persistentSidebarMinWidth = 720;

  /// Width of the persistent tablet sidebar.
  static const double sidebarWidth = 264;

  /// Max width used for forms / settings style pages so they do not stretch
  /// edge-to-edge on large tablets.
  static const double formMaxWidth = 760;

  /// Max width used for general content pages on very wide screens.
  static const double contentMaxWidth = 1280;

  /// Content width from which card lists switch to 2 columns.
  static const double twoColumnMinWidth = 700;

  /// Content width from which card lists switch to 3 columns.
  static const double threeColumnMinWidth = 1150;

  /// Device-level check. Uses the real window size (not the narrowed
  /// MediaQuery that AppScaffold gives the content area next to the sidebar),
  /// so it returns the same answer anywhere in the widget tree.
  static bool isTablet(BuildContext context) =>
      deviceSize(context).shortestSide >= tabletShortestSide;

  /// Logical size of the whole window / device screen.
  static Size deviceSize(BuildContext context) {
    // Registers a MediaQuery dependency so callers rebuild on rotation.
    final mqSize = MediaQuery.sizeOf(context);
    final view = View.maybeOf(context);
    if (view == null) return mqSize;
    return view.physicalSize / view.devicePixelRatio;
  }

  static bool isPhone(BuildContext context) => !isTablet(context);

  /// Width below which a phone is treated as "small" (4" – 5" devices,
  /// e.g. 320 x 568 iPhone SE 1st gen, 360dp Androids, 375pt iPhone SE/8).
  static const double smallPhoneMaxWidth = 380;

  /// True for small phones (shortest side < 380dp).
  static bool isSmallPhone(BuildContext context) =>
      deviceSize(context).shortestSide < smallPhoneMaxWidth;

  /// Font scale applied app-wide (every screen, dialog and bottom sheet) so
  /// the same UI fits small phones, normal phones and tablets.
  ///  * < 340dp  (4" phones, 320 wide)        → 0.82
  ///  * < 380dp  (small phones, 360 / 375)    → 0.88
  ///  * < 400dp  (compact phones, 390 / 393)  → 0.94
  ///  * >= 400dp (large phones) and tablets   → 1.0
  static double fontScaleFor(Size size) {
    final shortest = size.shortestSide;
    if (shortest < 340) return 0.82;
    if (shortest < smallPhoneMaxWidth) return 0.88;
    if (shortest < 400) return 0.94;
    return 1.0;
  }

  /// Wraps [child] with a MediaQuery whose text scaler is adjusted for the
  /// device size. The user's accessibility font size is respected but capped
  /// so layouts don't break (1.3x on phones, 1.5x on tablets).
  static Widget scaleText(BuildContext context, Widget child) {
    final mq = MediaQuery.of(context);
    final base = fontScaleFor(mq.size);
    final maxUserScale = mq.size.shortestSide >= tabletShortestSide ? 1.5 : 1.3;
    final userScaler = mq.textScaler.clamp(maxScaleFactor: maxUserScale);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: _MultipliedTextScaler(userScaler, base),
      ),
      child: child,
    );
  }

  static bool isLandscape(BuildContext context) {
    final size = deviceSize(context);
    return size.width > size.height;
  }

  /// True when the drawer should be shown as a pinned sidebar.
  static bool showPersistentSidebar(BuildContext context) {
    final size = deviceSize(context);
    return size.shortestSide >= tabletShortestSide &&
        size.width >= persistentSidebarMinWidth;
  }

  /// Number of card columns for the given available content width.
  static int columnsFor(double width, {int maxColumns = 3}) {
    int cols = 1;
    if (width >= threeColumnMinWidth) {
      cols = 3;
    } else if (width >= twoColumnMinWidth) {
      cols = 2;
    }
    return cols > maxColumns ? maxColumns : cols;
  }

  /// Grid column count for small stat / KPI tiles.
  static int statColumnsFor(double width, {int phone = 2}) {
    if (width >= 1100) return 4;
    if (width >= 700) return 3;
    return phone;
  }

  /// Horizontal page padding that grows a little on tablets.
  static double pagePadding(BuildContext context) =>
      isTablet(context) ? 20 : 12;
}

extension ResponsiveContext on BuildContext {
  bool get isTablet => Responsive.isTablet(this);
  bool get isPhone => Responsive.isPhone(this);
  bool get showPersistentSidebar => Responsive.showPersistentSidebar(this);
}

/// A [TextScaler] that multiplies another scaler by a constant factor.
class _MultipliedTextScaler extends TextScaler {
  final TextScaler parent;
  final double factor;

  const _MultipliedTextScaler(this.parent, this.factor);

  @override
  double scale(double fontSize) => parent.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => parent.textScaleFactor * factor;

  @override
  bool operator ==(Object other) =>
      other is _MultipliedTextScaler &&
      other.parent == parent &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(parent, factor);
}
