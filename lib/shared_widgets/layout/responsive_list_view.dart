import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Drop-in replacement for `ListView.builder` / `ListView.separated` for
/// vertical card lists.
///
/// On phones (or whenever the available width is narrow) it renders the exact
/// same single-column list. On tablets it lays the cards out in 2 (or 3)
/// columns, row by row, so cards keep their natural (variable) height and no
/// fixed grid aspect ratio is needed.
class ResponsiveListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;
  final bool? primary;
  final Axis scrollDirection;
  final int maxColumns;
  final double columnSpacing;
  final double rowSpacing;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const ResponsiveListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.maxColumns = 2,
    this.columnSpacing = 12,
    this.rowSpacing = 0,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  }) : separatorBuilder = null;

  const ResponsiveListView.separated({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required IndexedWidgetBuilder this.separatorBuilder,
    this.padding,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.primary,
    this.scrollDirection = Axis.vertical,
    this.maxColumns = 2,
    this.columnSpacing = 12,
    this.rowSpacing = 0,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  Widget _singleColumn() {
    if (separatorBuilder != null) {
      return ListView.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
        padding: padding,
        physics: physics,
        controller: controller,
        shrinkWrap: shrinkWrap,
        primary: primary,
        scrollDirection: scrollDirection,
        keyboardDismissBehavior: keyboardDismissBehavior,
      );
    }
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      padding: padding,
      physics: physics,
      controller: controller,
      shrinkWrap: shrinkWrap,
      primary: primary,
      scrollDirection: scrollDirection,
      keyboardDismissBehavior: keyboardDismissBehavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (scrollDirection != Axis.vertical || itemCount <= 1 || maxColumns <= 1) {
      return _singleColumn();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding =
            padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
        final available = constraints.maxWidth - resolvedPadding.horizontal;
        final columns = available.isFinite
            ? Responsive.columnsFor(available, maxColumns: maxColumns)
            : 1;
        if (columns <= 1) return _singleColumn();

        final rowCount = (itemCount + columns - 1) ~/ columns;

        Widget buildRow(BuildContext ctx, int row) {
          final children = <Widget>[];
          for (int c = 0; c < columns; c++) {
            final index = row * columns + c;
            if (c > 0) children.add(SizedBox(width: columnSpacing));
            children.add(
              Expanded(
                child: index < itemCount
                    ? itemBuilder(ctx, index)
                    : const SizedBox.shrink(),
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        }

        return ListView.separated(
          itemCount: rowCount,
          padding: padding,
          physics: physics,
          controller: controller,
          shrinkWrap: shrinkWrap,
          primary: primary,
          keyboardDismissBehavior: keyboardDismissBehavior,
          itemBuilder: buildRow,
          separatorBuilder: (ctx, row) {
            if (separatorBuilder != null) {
              // Re-use the original separator (spacing / divider) between rows.
              return separatorBuilder!(ctx, (row + 1) * columns - 1);
            }
            return SizedBox(height: rowSpacing);
          },
        );
      },
    );
  }
}

/// Lays out an already-built list of widgets (for example a `.map().toList()`
/// inside a Column) in 1/2/3 columns depending on the available width.
class ResponsiveWrapColumns extends StatelessWidget {
  final List<Widget> children;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveWrapColumns({
    super.key,
    required this.children,
    this.maxColumns = 2,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width.isFinite
            ? Responsive.columnsFor(width, maxColumns: maxColumns)
            : 1;
        if (columns <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }
        final rows = <Widget>[];
        for (int i = 0; i < children.length; i += columns) {
          final rowChildren = <Widget>[];
          for (int c = 0; c < columns; c++) {
            if (c > 0) rowChildren.add(SizedBox(width: spacing));
            final index = i + c;
            rowChildren.add(Expanded(
              child: index < children.length
                  ? children[index]
                  : const SizedBox.shrink(),
            ));
          }
          if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Centers [child] and caps its width on tablets (forms, settings, profile…).
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.formMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Title-row actions (badge + button) that stack vertically on phones and sit
/// in one row on tablets, with the last child pushed to the right edge.
///
/// Must be used as a direct child of a Row (it becomes `Expanded` on tablets).
class AdaptiveHeaderActions extends StatelessWidget {
  final List<Widget> children;

  const AdaptiveHeaderActions({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final visible = children.where((w) => w is! SizedBox).toList();
    if (!Responsive.isTablet(context)) {
      return Column(children: children);
    }
    return Expanded(
      child: Row(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i == visible.length - 1 && visible.length > 1) const Spacer(),
            visible[i],
          ],
        ],
      ),
    );
  }
}
