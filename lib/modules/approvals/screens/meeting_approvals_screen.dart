import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../constants/approvals_const_strings.dart';
import '../models/meeting_approval_model.dart';

class MeetingApprovalsScreen extends StatefulWidget {
  const MeetingApprovalsScreen({super.key});

  @override
  State<MeetingApprovalsScreen> createState() => _MeetingApprovalsScreenState();
}

class _MeetingApprovalsScreenState extends State<MeetingApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: Received by Me, 1: Initiated by Me

  @override
  void initState() {
    super.initState();
    context.read<ApprovalsBloc>().add(FetchMeetingApprovalsDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const CustomLeftDrawer(currentRoute: '/approvals/meetings'),
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ApprovalsBloc>().add(FetchMeetingApprovalsDataEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Awaiting Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    ApprovalsConstStrings.approvalsHeader,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  BlocBuilder<ApprovalsBloc, ApprovalsState>(
                    builder: (context, state) {
                      int awaitingCount = 0;
                      if (state is ApprovalsLoadedState) {
                        awaitingCount = state.meetings
                            .where((m) => m.status.toLowerCase() == 'pending')
                            .length;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$awaitingCount ${ApprovalsConstStrings.awaitingYou}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ApprovalsConstStrings.approvalsSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Pill Tabs
              BlocBuilder<ApprovalsBloc, ApprovalsState>(
                builder: (context, state) {
                  int receivedCount = 0;
                  int initiatedCount = 0;
                  if (state is ApprovalsLoadedState) {
                    receivedCount = state.meetings.where((m) => m.isOrganizer != true).length;
                    initiatedCount = state.meetings.where((m) => m.isOrganizer == true).length;
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(
                          title: '${ApprovalsConstStrings.receivedByMe} ${receivedCount > 0 ? "($receivedCount)" : ""}',
                          isSelected: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                        _buildTabButton(
                          title: '${ApprovalsConstStrings.initiatedByMe} ${initiatedCount > 0 ? "($initiatedCount)" : ""}',
                          isSelected: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Content Body
              BlocBuilder<ApprovalsBloc, ApprovalsState>(
                builder: (context, state) {
                  if (state is ApprovalsLoadingState) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
                      ),
                    );
                  }

                  if (state is ApprovalsErrorState) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Text(state.message),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<ApprovalsBloc>()
                                  .add(FetchMeetingApprovalsDataEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ApprovalsLoadedState) {
                    final items = state.meetings.where((m) {
                      if (_selectedTabIndex == 0) {
                        return m.isOrganizer != true;
                      } else {
                        return m.isOrganizer == true;
                      }
                    }).toList();

                    final displayList = items.isNotEmpty ? items : state.meetings;

                    if (displayList.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildMeetingCard(displayList[index]);
                      },
                    );
                  }

                  return _buildEmptyState();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF0F172A))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              ApprovalsConstStrings.noMeetingApprovals,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(MeetingApprovalModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAccepted = (item.status.toLowerCase() == 'accepted' || item.status.toLowerCase() == 'scheduled');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isAccepted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAccepted ? 'accepted' : 'pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isAccepted ? const Color(0xFF15803D) : const Color(0xFFA16207),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Date, Location, Organizer Metadata
          Text(
            '${item.startsAt != null ? _formatDate(item.startsAt!) : ""} · ${item.location ?? "In person"}${item.organizer != null ? " · organized by ${item.organizer}" : ""}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),

          // Agenda / Note Box
          if (item.agenda != null && item.agenda!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.agenda!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} ${_monthName(dt.month)}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
