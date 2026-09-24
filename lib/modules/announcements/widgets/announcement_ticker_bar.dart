import 'dart:async';
import 'package:flutter/material.dart';
import 'package:samskar_taskmanager/core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../models/announcement_model.dart';

class AnnouncementTickerBar extends StatefulWidget {
  final List<AnnouncementModel> announcements;

  const AnnouncementTickerBar({
    super.key,
    required this.announcements,
  });

  @override
  State<AnnouncementTickerBar> createState() => _AnnouncementTickerBarState();
}

class _AnnouncementTickerBarState extends State<AnnouncementTickerBar> {
  late final ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isAutoScrolling = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    // Continuous non-stop scroll every half second (500ms)
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_scrollController.hasClients || !_isAutoScrolling) return;
      if (!_scrollController.position.hasContentDimensions) return;

      final currentScroll = _scrollController.offset;
      final nextTarget = currentScroll + 30.0;

      _scrollController.animateTo(
        nextTarget,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showAnnouncementDialog(BuildContext context, AnnouncementModel item, bool isDark) {
    final s = AppStrings.of(context);
    final isCritical = item.priority == 'critical';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Color(0xFFDFBFBF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              isCritical ? Icons.warning_amber_rounded : Icons.campaign_rounded,
              color: isCritical ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCritical
                    ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                    : (isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isCritical ? 'CRITICAL' : 'INFO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCritical
                      ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
                      : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.body.isNotEmpty ? item.body : item.title,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.cancelButton,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeList = widget.announcements.where((a) => a.active).toList();

    if (activeList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Comfortable light & dark styling
    final barBgColor = isDark ? const Color(0xFF0F172A) : const Color(
        0xFFDCE6EF);
    final barBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final badgeBgColor = isDark ?   AppColors.buttonPrimaryDark:AppColors.buttonPrimary;
    final titleTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final dotColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Container(
      width: double.infinity,
      height: 38,
      decoration: BoxDecoration(
        color: barBgColor,
        border: Border(
          bottom: BorderSide(color: barBorderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Left Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.buttonPrimaryDark:AppColors.buttonPrimary) ,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  s.announcementsTickerLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          // Scrolling Marquee content
          Expanded(
            child: Listener(
              onPointerDown: (_) => _isAutoScrolling = false,
              onPointerUp: (_) {
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (mounted) _isAutoScrolling = true;
                });
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // Infinite items: never ends or stops
                itemBuilder: (context, index) {
                  final announcement = activeList[index % activeList.length];
                  final isCritical = announcement.priority == 'critical';

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showAnnouncementDialog(context, announcement, isDark),
                        borderRadius: BorderRadius.circular(4),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Priority indicator chip
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isCritical
                                      ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2))
                                      : (isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF)),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: isCritical
                                        ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5))
                                        : (isDark ? const Color(0xFF1E40AF) : const Color(0xFFBFDBFE)),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isCritical ? 'CRITICAL' : 'INFO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isCritical
                                        ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
                                        : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8)),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Text(
                                announcement.title,
                                style: TextStyle(
                                  color: titleTextColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (announcement.body.isNotEmpty) ...[
                                Text(
                                  ' — ',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  announcement.body,
                                  style: TextStyle(
                                    color: bodyTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Dot separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
