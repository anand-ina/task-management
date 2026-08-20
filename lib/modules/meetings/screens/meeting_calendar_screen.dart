import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/meetings_bloc.dart';
import '../bloc/meetings_event.dart';
import '../bloc/meetings_state.dart';
import '../models/meeting_model.dart';

class MeetingCalendarScreen extends StatefulWidget {
  const MeetingCalendarScreen({super.key});

  @override
  State<MeetingCalendarScreen> createState() => _MeetingCalendarScreenState();
}

class _MeetingCalendarScreenState extends State<MeetingCalendarScreen> {
  String _selectedViewMode = 'work_week'; // 'day', 'work_week', 'week', 'month'
  DateTime _selectedDate = DateTime(2026, 8, 10); // Initial anchor date matching API meetings sample

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => MeetingsBloc()..add(FetchMeetingCalendarEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/meetings-calendar'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<MeetingsBloc, MeetingsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MeetingsBloc>().add(FetchMeetingCalendarEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Subtitle
                      Text(
                        s.meetingCalendar,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.meetingCalendarSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Calendar Outer Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Navigation & View Mode Controls Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  // Today Button
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() => _selectedDate = DateTime.now());
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(s.todayButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),

                                  // Prev Button
                                  IconButton(
                                    onPressed: _navigatePrev,
                                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),

                                  // Next Button
                                  IconButton(
                                    onPressed: _navigateNext,
                                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),

                                  // Dynamic Date Range Display Text
                                  Text(
                                    _getDynamicDateRangeText(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  // View Mode Segmented Controls
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildViewModePill(s.dayView, 'day'),
                                        _buildViewModePill(s.workWeekView, 'work_week'),
                                        _buildViewModePill(s.weekView, 'week'),
                                        _buildViewModePill(s.monthView, 'month'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Calendar Grid View Body
                            if (state is MeetingsLoadingState)
                              const Padding(
                                padding: EdgeInsets.all(60),
                                child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                              )
                            else if (state is MeetingsErrorState)
                              Center(
                                child: Column(
                                  children: [
                                    Text(state.message, style: const TextStyle(color: Colors.red)),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => context.read<MeetingsBloc>().add(FetchMeetingCalendarEvent()),
                                      child: Text(s.retryButton),
                                    ),
                                  ],
                                ),
                              )
                            else if (state is MeetingCalendarLoadedState)
                              // Horizontal Scrollable Container for Mobile Responsiveness
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: _getGridMinWidth(),
                                  ),
                                  child: _buildCalendarGrid(context, s, state.meetings),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
                      ),
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

  double _getGridMinWidth() {
    switch (_selectedViewMode) {
      case 'day':
        return 350;
      case 'work_week':
        return 650;
      case 'week':
        return 800;
      case 'month':
        return 850;
      default:
        return 650;
    }
  }

  void _navigatePrev() {
    setState(() {
      if (_selectedViewMode == 'day') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      } else if (_selectedViewMode == 'work_week' || _selectedViewMode == 'week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_selectedViewMode == 'month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
      }
    });
  }

  void _navigateNext() {
    setState(() {
      if (_selectedViewMode == 'day') {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      } else if (_selectedViewMode == 'work_week' || _selectedViewMode == 'week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_selectedViewMode == 'month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
      }
    });
  }

  String _getDynamicDateRangeText() {
    if (_selectedViewMode == 'day') {
      return '${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
    }

    if (_selectedViewMode == 'month') {
      return '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';
    }

    // Work Week or Week
    final monday = _getMondayOfWeek(_selectedDate);
    final countDays = _selectedViewMode == 'work_week' ? 4 : 6;
    final endDate = monday.add(Duration(days: countDays));

    if (monday.month == endDate.month) {
      return '${monday.day} – ${endDate.day} ${_monthNames[monday.month - 1]} ${monday.year}';
    } else {
      return '${monday.day} ${_monthNames[monday.month - 1].substring(0, 3)} – ${endDate.day} ${_monthNames[endDate.month - 1].substring(0, 3)} ${endDate.year}';
    }
  }

  DateTime _getMondayOfWeek(DateTime dt) {
    final weekdayIndex = dt.weekday; // 1: Mon, ..., 7: Sun
    return dt.subtract(Duration(days: weekdayIndex - 1));
  }

  List<DateTime> _getDynamicDays() {
    if (_selectedViewMode == 'day') {
      return [_selectedDate];
    }

    final monday = _getMondayOfWeek(_selectedDate);

    if (_selectedViewMode == 'work_week') {
      return List.generate(5, (index) => monday.add(Duration(days: index)));
    }

    if (_selectedViewMode == 'week') {
      return List.generate(7, (index) => monday.add(Duration(days: index)));
    }

    // Month view: show days of current month or weeks
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return List.generate(daysInMonth, (index) => DateTime(_selectedDate.year, _selectedDate.month, index + 1));
  }

  Widget _buildViewModePill(String label, String mode) {
    final isSelected = _selectedViewMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedViewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, AppStrings s, List<MeetingItemModel> meetings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dynamicDays = _getDynamicDays();

    final timeSlots = [
      '8 AM', '9 AM', '10 AM', '11 AM', '12 PM',
      '1 PM', '2 PM', '3 PM', '4 PM', '5 PM',
      '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM'
    ];

    return Table(
      border: TableBorder.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        width: 1,
      ),
      columnWidths: {
        0: const FixedColumnWidth(60),
        for (int i = 0; i < dynamicDays.length; i++) i + 1: const FlexColumnWidth(1),
      },
      children: [
        // Days Dynamic Header Row
        TableRow(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          children: [
            const SizedBox.shrink(),
            ...dynamicDays.map((d) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _dayNames[d.weekday - 1],
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ],
                  ),
                )),
          ],
        ),

        // Time Slot Rows
        ...timeSlots.map((slot) {
          final slotHour = _parseSlotHour(slot);

          return TableRow(
            children: [
              // Time Slot Label
              Container(
                height: 56,
                padding: const EdgeInsets.only(top: 6, right: 6),
                alignment: Alignment.topRight,
                child: Text(
                  slot,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),

              // Dynamic Day Columns
              ...dynamicDays.map((dayDate) {
                final matchingMeetings = meetings.where((m) {
                  try {
                    final dt = DateTime.parse(m.startsAt);
                    return dt.year == dayDate.year &&
                        dt.month == dayDate.month &&
                        dt.day == dayDate.day &&
                        dt.hour == slotHour;
                  } catch (_) {
                    return false;
                  }
                }).toList();

                return Container(
                  height: 56,
                  padding: const EdgeInsets.all(3),
                  child: matchingMeetings.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          children: matchingMeetings.map((m) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatMeetingTime(m.startsAt, m.endsAt),
                                    style: const TextStyle(fontSize: 8, color: Colors.black54),
                                  ),
                                  Text(
                                    m.title,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (m.organizer != null)
                                    Text(
                                      m.organizer!,
                                      style: TextStyle(fontSize: 8, color: isDark ? Colors.white70 : Colors.black54),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  int _parseSlotHour(String slot) {
    if (slot == '12 PM') return 12;
    if (slot.contains('AM')) {
      final h = int.tryParse(slot.replaceAll(' AM', '').trim()) ?? 0;
      return h == 12 ? 0 : h;
    } else {
      final h = int.tryParse(slot.replaceAll(' PM', '').trim()) ?? 0;
      return h == 12 ? 12 : h + 12;
    }
  }

  String _formatMeetingTime(String startIso, String endIso) {
    try {
      final s = DateTime.parse(startIso);
      final e = DateTime.parse(endIso);
      return '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}–${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
