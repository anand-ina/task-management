import 'dart:math' as math;
import 'package:flutter/material.dart';

class SearchableDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  const SearchableDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.trailing,
  });
}

class SearchableFilterDropdown<T> extends StatefulWidget {
  final T? value;
  final String hint;
  final String? searchHint;
  final List<SearchableDropdownItem<T?>> items;
  final ValueChanged<T?> onChanged;
  final double? width;
  final double? minPopupWidth;
  final int maxVisibleCount;
  final bool isExpanded;
  final Widget Function(BuildContext context, VoidCallback onTap, bool isOpen)? customTrigger;

  const SearchableFilterDropdown({
    super.key,
    required this.value,
    required this.hint,
    this.searchHint,
    required this.items,
    required this.onChanged,
    this.width,
    this.minPopupWidth,
    this.maxVisibleCount = 4,
    this.isExpanded = false,
    this.customTrigger,
  });

  @override
  State<SearchableFilterDropdown<T>> createState() => _SearchableFilterDropdownState<T>();
}

class _SearchableFilterDropdownState<T> extends State<SearchableFilterDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _isOpen) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Check if opening below fits, otherwise open above
    final spaceBelow = screenSize.height - (offset.dy + size.height);
    const popupMaxHeight = 225.0;
    final openUpwards = spaceBelow < popupMaxHeight && offset.dy > spaceBelow;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final popupWidth = math.max(size.width, widget.minPopupWidth ?? 220.0);

    // Keep popup within screen horizontal boundaries
    double dx = 0;
    if (offset.dx + popupWidth > screenSize.width - 12) {
      dx = (screenSize.width - 12) - (offset.dx + popupWidth);
    }
    if (offset.dx + dx < 12) {
      dx = 12 - offset.dx;
    }

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Full screen transparent barrier to close dropdown on tap outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            // Anchored dropdown menu
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: openUpwards ? Alignment.topLeft : Alignment.bottomLeft,
              followerAnchor: openUpwards ? Alignment.bottomLeft : Alignment.topLeft,
              offset: Offset(dx, openUpwards ? -4.0 : 4.0),
              child: SizedBox(
                width: popupWidth,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.22),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: _DropdownPopupContent<T>(
                      items: widget.items,
                      selectedValue: widget.value,
                      searchHint: widget.searchHint ?? 'Search ${widget.hint}...',
                      maxVisibleCount: widget.maxVisibleCount,
                      onSelect: (val) {
                        _closeDropdown();
                        widget.onChanged(val);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customTrigger != null) {
      return CompositedTransformTarget(
        link: _layerLink,
        child: widget.customTrigger!(context, _toggleDropdown, _isOpen),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedItem = widget.items.where((it) => it.value == widget.value).firstOrNull;
    final isSelected = widget.value != null;
    final displayText = isSelected ? (selectedItem?.label ?? widget.hint) : widget.hint;

    final triggerContent = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isOpen
              ? const Color(0xFF991B1B)
              : (isSelected
                  ? const Color(0xFF991B1B).withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
          width: _isOpen ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ],
      ),
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(8),
        child: widget.width != null
            ? SizedBox(width: widget.width, child: triggerContent)
            : (widget.isExpanded
                ? SizedBox(width: double.infinity, child: triggerContent)
                : triggerContent),
      ),
    );
  }
}

class _DropdownPopupContent<T> extends StatefulWidget {
  final List<SearchableDropdownItem<T?>> items;
  final T? selectedValue;
  final String searchHint;
  final int maxVisibleCount;
  final ValueChanged<T?> onSelect;

  const _DropdownPopupContent({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.searchHint,
    this.maxVisibleCount = 4,
    required this.onSelect,
  });

  @override
  State<_DropdownPopupContent<T>> createState() => _DropdownPopupContentState<T>();
}

class _DropdownPopupContentState<T> extends State<_DropdownPopupContent<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = widget.items.where((it) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchesLabel = it.label.toLowerCase().contains(q);
      final matchesSubtitle = it.subtitle != null && it.subtitle!.toLowerCase().contains(q);
      return matchesLabel || matchesSubtitle;
    }).toList();

    // Showing only 4 items at a time in the viewport; remaining items are visible upon scrolling
    final hasSubtitles = widget.items.any((it) => it.subtitle != null && it.subtitle!.isNotEmpty);
    final itemHeight = hasSubtitles ? 48.0 : 38.0;
    final maxVisibleCount = widget.maxVisibleCount;
    final visibleCount = math.min(filteredItems.length, maxVisibleCount);
    final listHeight = visibleCount == 0 ? 44.0 : (visibleCount * itemHeight);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Box at top of the dropdown
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: SizedBox(
            height: 34,
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(fontSize: 12),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 15,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(Icons.close, size: 14),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: Color(0xFF991B1B),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),

        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),

        // 2. Scrollable item list showing 4 items max at once
        SizedBox(
          height: listHeight,
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                )
              : Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: filteredItems.length > maxVisibleCount,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredItems.length,
                    itemExtent: itemHeight,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = item.value == widget.selectedValue;

                      return InkWell(
                        onTap: () => widget.onSelect(item.value),
                        child: Container(
                          height: itemHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          color: isSelected
                              ? (isDark
                                  ? const Color(0xFF991B1B).withValues(alpha: 0.2)
                                  : const Color(0xFF991B1B).withValues(alpha: 0.08))
                              : Colors.transparent,
                          child: Row(
                            children: [
                              if (item.leading != null) ...[
                                item.leading!,
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF991B1B)
                                            : (isDark ? Colors.grey.shade200 : const Color(0xFF1E293B)),
                                      ),
                                    ),
                                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (item.trailing != null) ...[
                                const SizedBox(width: 8),
                                item.trailing!,
                              ] else if (isSelected) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Color(0xFF991B1B),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
