import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Marks the subtree that is rendered next to a pinned (persistent) sidebar.
///
/// [CustomLeftDrawer] reads it to switch into sidebar mode and the
/// [CustomAppBar] reads it to hide the hamburger / back button.
class PersistentSidebarScope extends InheritedWidget {
  /// True for the sidebar itself, false for the page content next to it.
  final bool isSidebar;

  const PersistentSidebarScope({
    super.key,
    required this.isSidebar,
    required super.child,
  });

  static PersistentSidebarScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PersistentSidebarScope>();

  /// True when [context] is the sidebar rendered in pinned mode.
  static bool isPinnedSidebar(BuildContext context) =>
      maybeOf(context)?.isSidebar ?? false;

  /// True when [context] is page content shown next to the pinned sidebar.
  static bool hasPinnedSidebar(BuildContext context) =>
      maybeOf(context) != null;

  @override
  bool updateShouldNotify(PersistentSidebarScope oldWidget) =>
      oldWidget.isSidebar != isSidebar;
}

/// Drop-in replacement for [Scaffold] used by every screen that owns the
/// navigation drawer.
///
/// * Phone            → a normal [Scaffold] with a slide-in drawer.
/// * Tablet (>=720dp) → the drawer is pinned on the left as a sidebar (same as
///   the web portal) and the page content takes the remaining width.
///
/// The content side receives a [MediaQuery] whose width excludes the sidebar,
/// so every `MediaQuery.sizeOf(context).width` / LayoutBuilder in the screens
/// keeps computing the correct available width.
class AppScaffold extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  /// Optional max width for the page body on tablets (forms, chat, FAQ…).
  /// The body is centred and capped to this width; phones are unaffected.
  final double? maxContentWidth;

  const AppScaffold({
    super.key,
    this.scaffoldKey,
    this.appBar,
    this.drawer,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.maxContentWidth,
  });

  Widget? _buildBody() {
    final maxWidth = maxContentWidth;
    if (body == null || maxWidth == null) return body;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return body!;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: math.min(constraints.maxWidth, maxWidth),
            height: constraints.maxHeight,
            child: body,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinSidebar = drawer != null && Responsive.showPersistentSidebar(context);

    if (!pinSidebar) {
      return Scaffold(
        key: scaffoldKey,
        appBar: appBar,
        drawer: drawer,
        body: _buildBody(),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      );
    }

    final mq = MediaQuery.of(context);
    const sidebarWidth = Responsive.sidebarWidth;
    final contentMq = mq.copyWith(
      size: Size(mq.size.width - sidebarWidth, mq.size.height),
      padding: mq.padding.copyWith(left: 0),
      viewPadding: mq.viewPadding.copyWith(left: 0),
    );

    return Material(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.subtleBorder(context)),
              ),
            ),
            child: PersistentSidebarScope(
              isSidebar: true,
              child: drawer!,
            ),
          ),
          Expanded(
            child: MediaQuery(
              data: contentMq,
              child: PersistentSidebarScope(
                isSidebar: false,
                child: Scaffold(
                  key: scaffoldKey,
                  appBar: appBar,
                  body: _buildBody(),
                  floatingActionButton: floatingActionButton,
                  floatingActionButtonLocation: floatingActionButtonLocation,
                  bottomNavigationBar: bottomNavigationBar,
                  backgroundColor: backgroundColor,
                  resizeToAvoidBottomInset: resizeToAvoidBottomInset,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
