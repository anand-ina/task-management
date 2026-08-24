import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/schedule_meeting_dialog.dart';
import '../bloc/meetings_bloc.dart';
import '../bloc/meetings_event.dart';
import '../bloc/meetings_state.dart';
import '../models/meeting_model.dart';

class MyScheduledMeetingsScreen extends StatefulWidget {
  const MyScheduledMeetingsScreen({super.key});

  @override
  State<MyScheduledMeetingsScreen> createState() => _MyScheduledMeetingsScreenState();
}

class _MyScheduledMeetingsScreenState extends State<MyScheduledMeetingsScreen> {
  int _selectedTabIndex = 0; // 0: All, 1: Initiated by Me, 2: Received by Me
  final DioClient _dioClient = DioClient();
  final Set<dynamic> _attendedMeetingIds = {};

  Future<void> _markAttended(BuildContext context, MeetingItemModel item) async {
    try {
      final meetingId = item.rawId ?? item.id;
      final response = await _dioClient.dio.post('${ApiConstants.baseUrl}/meetings/$meetingId/attend');
      debugPrint('[Meetings] attend API URL: ${ApiConstants.baseUrl}/meetings/$meetingId/attend, response: ${response.data}');
      if (mounted) {
        setState(() {
          _attendedMeetingIds.add(item.id);
          if (item.rawId != null) _attendedMeetingIds.add(item.rawId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked! +2 points earned 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _attendedMeetingIds.add(item.id);
          if (item.rawId != null) _attendedMeetingIds.add(item.rawId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked! +2 points earned 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showMeetingReminder(BuildContext context, MeetingItemModel item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          alignment: Alignment.topRight,
                insetPadding: const EdgeInsets.only(top: 60, right: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('🔔 ', style: TextStyle(fontSize: 12)),
                          Text(
                            'MEETING REMINDER',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatMeetingDate(item.startsAt)} · ${item.location ?? "Online"}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Join', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Snooze', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Not available', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Delivery follows your notification preferences.',
                        style: TextStyle(fontSize: 9.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }

  Future<void> _showMeetingHappenedDialog(BuildContext context, MeetingItemModel item) async {
    final controller = TextEditingController(text: 'test comment');

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Text('dev-task.srivyn.in says', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a note for the approver (what was covered, who attended):',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.all(10),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65A30D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('OK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _dioClient.dio.post(
          '${ApiConstants.baseUrl}/meetings/${item.id}/complete',
          data: {'note': result},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting marked as completed!'), backgroundColor: Colors.green),
          );
          context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => MeetingsBloc()..add(FetchMyScheduledMeetingsEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await ExitConfirmationDialog.show(context);
          if (shouldExit) {
            // Handled inside exit dialog
          }
        },
        child: Scaffold(
          drawer: const CustomLeftDrawer(currentRoute: '/my-meetings'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<MeetingsBloc, MeetingsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.myScheduledMeetings,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.meetingsOrganizeOrInvitedSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => ScheduleMeetingDialog.show(context),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text(
                                  '+ New meeting',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.notifications_active_outlined, size: 14, color: Colors.amber),
                                label: Text(s.previewRemindersButton, style: const TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                      const SizedBox(height: 16),

                      // Auto status-report slots banner
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Text('📝 ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : const Color(0xFF92400E),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: s.autoStatusReportSlotsToday,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          s.dsrTimeSlot,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Segmented Tab Control
                      if (state is MyScheduledMeetingsLoadedState) ...[
                        Builder(
                          builder: (context) {
                            final meetings = state.meetings;
                            final initiated = meetings.where((m) => m.isOrganizer == true).length;
                            final received = meetings.where((m) => m.isOrganizer != true).length;
                            final total = meetings.length;

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTabPill(
                                    title: '${s.allTab} $total',
                                    isSelected: _selectedTabIndex == 0,
                                    onTap: () => setState(() => _selectedTabIndex = 0),
                                  ),
                                  _buildTabPill(
                                    title: '${s.initiatedByMe} $initiated',
                                    isSelected: _selectedTabIndex == 1,
                                    onTap: () => setState(() => _selectedTabIndex = 1),
                                  ),
                                  _buildTabPill(
                                    title: '${s.receivedByMe} $received',
                                    isSelected: _selectedTabIndex == 2,
                                    onTap: () => setState(() => _selectedTabIndex = 2),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // State Handling
                      if (state is MeetingsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is MeetingsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
                                },
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is MyScheduledMeetingsLoadedState)
                        _buildMeetingsList(context, s, state.meetings)
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill({
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
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(BuildContext context, AppStrings s, List<MeetingItemModel> meetings) {
    final filtered = meetings.where((m) {
      if (_selectedTabIndex == 1) return m.isOrganizer == true;
      if (_selectedTabIndex == 2) return m.isOrganizer != true;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No meetings found.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _buildMeetingCard(context, s, filtered[index]);
      },
    );
  }

  Widget _buildMeetingCard(BuildContext context, AppStrings s, MeetingItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPendingCompletion = item.completionStatus?.toLowerCase() == 'pending';
    final isAttended = item.myAttended == true || _attendedMeetingIds.contains(item.id) || (item.rawId != null && _attendedMeetingIds.contains(item.rawId));
    final showRsvp = !isAttended && item.myResponse != null && item.myResponse!.toLowerCase() == 'pending';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Blue Accent Strip
              Container(
                width: 4,
                color: const Color(0xFF1E3A8A),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Badge: Completion awaiting approval (if pending)
                      if (isPendingCompletion) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            s.completionAwaitingApproval,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Meeting Title
                      Text(
                        item.title.isNotEmpty ? item.title : 'Untitled Meeting',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Time & Location
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatMeetingDate(item.startsAt)} · ${item.location ?? "In person"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Organizer
                      Text(
                        'Organizer: ${item.organizer ?? "Vamsi"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Invitee Chips
                      if (item.invitees.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.invitees.map((inv) {
                            final isAccepted = (inv.response ?? '').toLowerCase() == 'accepted';
                            final isOptional = inv.required == false;
                            final label = '${inv.name}${isOptional ? " (opt)" : ""}${isAccepted ? " ✓" : ""}';

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAccepted
                                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isAccepted
                                      ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      // RSVP Options (Yes / No / Maybe)
                      if (showRsvp) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'RSVP:  ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            InkWell(
                              onTap: () => _submitRsvp(context, item, 'accepted'),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => _submitRsvp(context, item, 'declined'),
                              child: const Text(
                                'No',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => _submitRsvp(context, item, 'tentative'),
                              child: Text(
                                'Maybe',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Action Links Row: Join / Mark attended OR Meeting happened + Reminder
                      Row(
                        children: [
                          if (isAttended) ...[
                            InkWell(
                              onTap: () => _showMeetingReminder(context, item),
                              child: Text(
                                s.reminderButton,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ] else ...[
                            if (item.myResponse?.toLowerCase() == 'pending') ...[
                              InkWell(
                                onTap: () => _markAttended(context, item),
                                child: Row(
                                  children: [
                                    const Text('👥 ', style: TextStyle(fontSize: 11)),
                                    Text(
                                      s.joinMarkAttendedButton,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              InkWell(
                                onTap: () => _showMeetingHappenedDialog(context, item),
                                child: Row(
                                  children: [
                                    Text(
                                      '✓ ${s.meetingHappenedButton}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () => _showMeetingReminder(context, item),
                              child: Text(
                                s.reminderButton,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRsvp(BuildContext context, MeetingItemModel item, String responseValue) async {
    try {
      await _dioClient.dio.post(
        '${ApiConstants.baseUrl}/meetings/${item.id}/rsvp',
        data: {'response': responseValue},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSVP submitted as $responseValue'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<MeetingsBloc>().add(FetchMyScheduledMeetingsEvent());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('RSVP saved: $responseValue'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatMeetingDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }
}
