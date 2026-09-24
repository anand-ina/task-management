import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/announcements_bloc.dart';
import '../bloc/announcements_event.dart';
import '../bloc/announcements_state.dart';
import '../dialogs/create_announcement_dialog.dart';
import '../dialogs/delete_announcement_dialog.dart';
import '../models/announcement_model.dart';
import '../widgets/announcement_ticker_bar.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementsBloc>().add(const FetchAnnouncementsEvent());
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM, HH:mm').format(dt);
  }

  String _buildMetadataString(AnnouncementModel item) {
    final parts = <String>[];
    if (item.createdByName != null && item.createdByName!.isNotEmpty) {
      parts.add('by ${item.createdByName}');
    }
    if (item.createdAt != null) {
      parts.add(_formatDate(item.createdAt));
    }
    if (item.startsAt != null) {
      parts.add('from ${_formatDate(item.startsAt)}');
    }
    if (item.endsAt != null) {
      parts.add('until ${_formatDate(item.endsAt)}');
    }
    return parts.join(' · ');
  }

  Color _getPriorityBorderColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'info':
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _getPriorityBgColor(String priority, bool isDark) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEE2E2);
      case 'warning':
        return isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7);
      case 'info':
      default:
        return isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFE2E8F0);
    }
  }

  Color _getPriorityTextColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'warning':
        return const Color(0xFFD97706);
      case 'info':
      default:
        return const Color(0xFF334155);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit) {
          // Handled inside ExitConfirmationDialog
        }
      },
      child: Scaffold(
        drawer: const CustomLeftDrawer(currentRoute: '/announcements'),
        appBar: const CustomAppBar(),
        body: BlocConsumer<AnnouncementsBloc, AnnouncementsState>(
          listener: (context, state) {
            if (state is AnnouncementsLoadedState && state.successMessage != null) {
              String msg = '';
              if (state.successMessage == 'created') {
                msg = s.announcementCreatedSuccess;
              } else if (state.successMessage == 'updated') {
                msg = s.announcementUpdatedSuccess;
              } else if (state.successMessage == 'deleted') {
                msg = s.announcementDeletedSuccess;
              } else if (state.successMessage == 'deactivated') {
                msg = s.announcementDeactivatedSuccess;
              } else if (state.successMessage == 'activated') {
                msg = s.announcementActivatedSuccess;
              }
              if (msg.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: const Color(0xFF16A34A),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } else if (state is AnnouncementsLoadedState && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AnnouncementsLoadingState) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is AnnouncementsErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AnnouncementsBloc>().add(const FetchAnnouncementsEvent());
                      },
                      child: Text(s.retryButton),
                    ),
                  ],
                ),
              );
            }

            final announcements = state is AnnouncementsLoadedState ? state.announcements : <AnnouncementModel>[];
            final activeAnnouncements = state is AnnouncementsLoadedState
                ? state.activeAnnouncements
                : announcements.where((a) => a.active).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top scrolling marquee banner for active announcements
                if (activeAnnouncements.isNotEmpty)
                  AnnouncementTickerBar(announcements: activeAnnouncements),

                // Main content area
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<AnnouncementsBloc>().add(const FetchAnnouncementsEvent());
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Announcements count & + New announcement button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.announcements,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      '${announcements.length}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  CreateAnnouncementDialog.show(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.button(context),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  s.newAnnouncement,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            s.announcementsSubtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Cards List
                          if (announcements.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  s.noAnnouncementsFound,
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 860;
                                return isWide
                                    ? Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: announcements.map((item) {
                                          final cardWidth = (constraints.maxWidth - 16) / 2;
                                          return SizedBox(
                                            width: cardWidth,
                                            child: _buildAnnouncementCard(context, s, item, isDark),
                                          );
                                        }).toList(),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: announcements.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                                        itemBuilder: (context, index) =>
                                            _buildAnnouncementCard(context, s, announcements[index], isDark),
                                      );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AppStrings s,
    AnnouncementModel announcement,
    bool isDark,
  ) {
    final borderColor = _getPriorityBorderColor(announcement.priority);
    final chipBg = _getPriorityBgColor(announcement.priority, isDark);
    final chipText = _getPriorityTextColor(announcement.priority);
    final metadata = _buildMetadataString(announcement);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Left accent stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              color: borderColor,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Priority badge + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        announcement.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: chipText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Body details
                if (announcement.body.isNotEmpty) ...[
                  Text(
                    announcement.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Metadata: by author, created date, from, until
                if (metadata.isNotEmpty) ...[
                  Text(
                    metadata,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action buttons: Deactivate/Activate, Edit, Delete
                Row(
                  children: [
                    // Deactivate / Activate
                    _buildPillButton(
                      label: announcement.active ? s.deactivate : s.activate,
                      isDark: isDark,
                      onTap: () {
                        context.read<AnnouncementsBloc>().add(
                              ToggleActiveAnnouncementEvent(
                                id: announcement.id,
                                active: !announcement.active,
                              ),
                            );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Edit
                    _buildPillButton(
                      label: s.edit,
                      isDark: isDark,
                      onTap: () {
                        CreateAnnouncementDialog.show(
                          context,
                          existingAnnouncement: announcement,
                        );
                      },
                    ),
                    const SizedBox(width: 8),

                    // Delete
                    _buildPillButton(
                      label: s.delete,
                      textColor: const Color(0xFFDC2626),
                      isDark: isDark,
                      onTap: () async {
                        final confirmed = await DeleteAnnouncementDialog.show(
                          context,
                          announcement: announcement,
                        );
                        if (confirmed && context.mounted) {
                          context.read<AnnouncementsBloc>().add(
                                DeleteAnnouncementEvent(announcement.id),
                              );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool isDark,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor ?? (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
