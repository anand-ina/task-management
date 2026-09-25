import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/create_event_dialog.dart';
import '../bloc/events_bloc.dart';
import '../bloc/events_event.dart';
import '../bloc/events_state.dart';
import '../models/event_model.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedViewMode = 'list'; // 'list', 'day', 'calendar'
  int _selectedSubTab = 1; // 0: Assigned to me, 1: Events
  final DioClient _dioClient = DioClient();

  DateTime _selectedDayDate = DateTime.now();
  DateTime _selectedWeekDate = DateTime.now();
  DateTime _selectedMonthDate = DateTime.now();
  DateTime _selectedThreeMonthsDate = DateTime.now();

  // Map of eventId -> Map of expansion/loading state
  final Map<int, bool> _expandedChecklists = {};
  final Map<int, List<dynamic>> _eventChecklists = {};
  final Map<int, bool> _loadingChecklists = {};

  // Map of checklistItemId -> comment text
  final Map<int, String> _commentInputs = {};
  final Map<int, bool> _activeCommentInputs = {};

  Future<void> _fetchEventChecklist(int eventId) async {
    setState(() => _loadingChecklists[eventId] = true);

    try {
      final res = await _dioClient.dio.get('${ApiConstants.baseUrl}/events/$eventId/checklist');
      final data = res.data;
      if (mounted) {
        if (data is Map<String, dynamic> && data['items'] is List) {
          setState(() {
            _eventChecklists[eventId] = data['items'];
          });
        } else if (data is List) {
          setState(() {
            _eventChecklists[eventId] = data;
          });
        } else {
          setState(() {
            _eventChecklists[eventId] = [];
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _eventChecklists[eventId] = [];
        });
      }
    } finally {
      if (mounted) setState(() => _loadingChecklists[eventId] = false);
    }
  }

  Future<void> _sendChecklistComment(int itemId, String text) async {
    if (text.trim().isEmpty) return;

    try {
      await _dioClient.dio.get('${ApiConstants.baseUrl}/events/checklist/$itemId/comments');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update posted successfully!'), backgroundColor: AppColors.green600),
        );
        setState(() {
          _activeCommentInputs[itemId] = false;
          _commentInputs[itemId] = '';
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update posted successfully!'), backgroundColor: AppColors.green600),
        );
        setState(() {
          _activeCommentInputs[itemId] = false;
          _commentInputs[itemId] = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocProvider(
      create: (context) => EventsBloc()..add(FetchEventsEvent()),
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
          floatingActionButton: const TodoFloatingActionButton(),
          drawer: const CustomLeftDrawer(currentRoute: '/events'),
          appBar: const CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: BlocBuilder<EventsBloc, EventsState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<EventsBloc>().add(FetchEventsEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Title & Subtitle + New Event Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.eventsTitle,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.eventsSubtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => CreateEventDialog.show(context),
                             label: const Text('+ New Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.button(context),
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // View Mode Switcher Controls (List, Day, Week, Month, 3 Months)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildViewModeButton(Icons.menu_rounded, '☰  ${s.listViewLabel}', 'list'),
                            const SizedBox(width: 8),
                            _buildViewModeButton(Icons.access_time_rounded, '◔  ${s.dayView}', 'day'),
                            const SizedBox(width: 8),
                            _buildViewModeButton(Icons.view_week_rounded, '▥  ${s.weekView}', 'week'),
                            const SizedBox(width: 8),
                            _buildViewModeButton(Icons.calendar_view_month_rounded, '▤  ${s.monthView}', 'month'),
                            const SizedBox(width: 8),
                            _buildViewModeButton(Icons.calendar_month_rounded, '▦  ${s.threeMonthsView}', '3months'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedViewMode == 'list') ...[
                        // Sub-tabs (Assigned to me, Events)
                        Row(
                          children: [
                            _buildSubTab(s.assignedToMeTab, 0),
                            const SizedBox(width: 24),
                            _buildSubTab(s.eventsTab, 1),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // View Modes Body
                      if (state is EventsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is EventsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: AppColors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<EventsBloc>().add(FetchEventsEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is EventsLoadedState) ...[
                        if (_selectedViewMode == 'list')
                          _buildEventsListView(context, s, state.events)
                        else if (_selectedViewMode == 'day')
                          _buildDayView(context, s, state.events)
                        else if (_selectedViewMode == 'week')
                          _buildWeekView(context, s, state.events)
                        else if (_selectedViewMode == 'month')
                          _buildMonthCalendarView(context, s, state.events)
                        else if (_selectedViewMode == '3months')
                          _buildThreeMonthsView(context, s, state.events),
                      ] else
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
      ),
    );
  }

  Widget _buildViewModeButton(IconData icon, String label, String mode) {
    final isSelected = _selectedViewMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      onPressed: () => setState(() => _selectedViewMode = mode),
      icon: Icon(icon, size: 14, color: isSelected ? AppColors.white : AppColors.textPrimary(context)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.white : AppColors.textPrimary(context),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? (isDark ? AppColors.navyHeader : AppColors.navyHeader) : AppColors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(
          color: isSelected ? AppColors.navyHeader : AppColors.border(context),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSubTab(String title, int index) {
    final isSelected = _selectedSubTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedSubTab = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? (isDark ? AppColors.redLight : AppColors.red700) : AppColors.textMuted(context),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 80,
            color: isSelected ? (isDark ? AppColors.redLight : AppColors.red700) : AppColors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildDayView(BuildContext context, AppStrings s, List<EventModel> events) {
    final dayStr = DateFormat('dd/MM/yyyy').format(_selectedDayDate);

    final matchingEvents = events.where((e) {
      try {
        final dt = DateTime.parse(e.eventDate);
        return dt.year == _selectedDayDate.year &&
            dt.month == _selectedDayDate.month &&
            dt.day == _selectedDayDate.day;
      } catch (_) {
        return false;
      }
    }).toList();

    final displayList = matchingEvents.isNotEmpty ? matchingEvents : events;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Navigation Header Row
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                setState(() {
                  _selectedDayDate = _selectedDayDate.subtract(const Duration(days: 1));
                });
              },
            ),
            Text(
              dayStr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                setState(() {
                  _selectedDayDate = _selectedDayDate.add(const Duration(days: 1));
                });
              },
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                setState(() => _selectedDayDate = DateTime(2026, 8, 14));
              },
              child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          '${DateFormat('EEE, d MMM yyyy').format(_selectedDayDate)} · ${displayList.length} event',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted(context)),
        ),
        const SizedBox(height: 12),

        ...displayList.map((item) => _buildEventCard(context, s, item)),
      ],
    );
  }

  Widget _buildEventsListView(BuildContext context, AppStrings s, List<EventModel> events) {
    final filtered = _selectedSubTab == 0 ? events.where((e) => e.isMine == true).toList() : events;

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(child: Text('No events found.', style: TextStyle(color: AppColors.textMuted(context)))),
      );
    }

    return Column(
      children: filtered.map((item) => _buildEventCard(context, s, item)).toList(),
    );
  }

  Widget _buildEventCard(BuildContext context, AppStrings s, EventModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = item.total > 0 ? (item.done / item.total) : 0.0;
    final isDraft = item.reviewStatus.toLowerCase() == 'draft';
    final isExpanded = _expandedChecklists[item.id] ?? false;
    final isLoadingList = _loadingChecklists[item.id] ?? false;
    final checklist = _eventChecklists[item.id] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 3, color: AppColors.red700),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.subtleBg(context),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatEventDate(item.eventDate),
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (item.departments != null && item.departments!.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: item.departments!.split(',').map((dep) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.subtleBg(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dep.trim(),
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Text(
                        '${item.done} of ${item.total} done · owner: ${item.owner ?? "N/A"}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDraft
                              ? AppColors.subtleBg(context)
                              : AppColors.greenLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.reviewStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDraft
                                ? AppColors.textSecondary(context)
                                : AppColors.green700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.border(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green600),
                    ),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: () {
                      final nowExpanded = !isExpanded;
                      setState(() => _expandedChecklists[item.id] = nowExpanded);
                      if (nowExpanded) {
                        _fetchEventChecklist(item.id);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(color: AppColors.border(context)),
                    ),
                    child: Text(
                      isExpanded ? 'Hide checklist' : '${s.checklistLabel} (${item.done}/${item.total})',
                      style: TextStyle(fontSize: 11, color: AppColors.textPrimary(context)),
                    ),
                  ),

                  // Expandable Checklist Section
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 6),
                    if (isLoadingList)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    else if (checklist.isEmpty)
                      Text('No checklist items.', style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)))
                    else
                      Column(
                        children: checklist.map((chk) {
                          final itemId = chk['id'] as int? ?? 17;
                          final text = chk['text']?.toString() ?? 'Item';
                          final status = chk['status']?.toString() ?? 'Open';
                          final commentCount = chk['comment_count'] ?? 0;
                          final attachCount = chk['attachment_count'] ?? 0;
                          final isBoxOpen = _activeCommentInputs[itemId] ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.subtleBg(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.border(context),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _activeCommentInputs[itemId] = !isBoxOpen;
                                        });
                                      },
                                      child: const Text(
                                        '💬 0 · 📎 0',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.blue, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Unassigned', style: TextStyle(fontSize: 10, color: AppColors.textMuted(context))),
                                  ],
                                ),

                                // Inline Comment / Proof Note Box
                                if (isBoxOpen) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'No updates yet — add a comment or upload proof.',
                                    style: TextStyle(fontSize: 10, color: AppColors.textMuted(context)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          onChanged: (val) => _commentInputs[itemId] = val,
                                          style: const TextStyle(fontSize: 11),
                                          decoration: InputDecoration(
                                            hintText: 'Add an update / proof note…',
                                            hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            filled: true,
                                            fillColor: AppColors.card(context),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.attach_file_rounded, size: 18, color: AppColors.textMuted(context)),
                                      const SizedBox(width: 6),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.button(context),
                                          foregroundColor: AppColors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        ),
                                        onPressed: () => _sendChecklistComment(itemId, _commentInputs[itemId] ?? ''),
                                        child: const Text('Send', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendarView(BuildContext context, AppStrings s, List<EventModel> events) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    final firstDayOfMonth = DateTime(_selectedMonthDate.year, _selectedMonthDate.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonthDate.year, _selectedMonthDate.month);
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    final numRows = ((startingWeekday + daysInMonth) / 7).ceil();
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonthDate),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const Spacer(),
              // Prev Button (<)
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: s.previousMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month - 1, 1);
                  });
                },
              ),
              const SizedBox(width: 8),
              // Today Button
              OutlinedButton(
                onPressed: () {
                  setState(() => _selectedMonthDate = DateTime.now());
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(s.todayButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              // Next Button (>)
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: s.nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 700),
              child: Table(
                border: TableBorder.all(color: AppColors.border(context)),
                children: [
                  // Days Header Row
                  TableRow(
                    decoration: BoxDecoration(color: AppColors.subtleBg(context)),
                    children: dayNames.map((d) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted(context)),
                        ),
                      );
                    }).toList(),
                  ),

                  // Calendar Grid Weeks
                  ...List.generate(numRows, (weekIndex) {
                    return TableRow(
                      children: List.generate(7, (dayOfWeek) {
                        final cellNumber = weekIndex * 7 + dayOfWeek - startingWeekday + 1;
                        if (cellNumber < 1 || cellNumber > daysInMonth) {
                          return const SizedBox(height: 64);
                        }

                        final isToday = cellNumber == now.day &&
                            _selectedMonthDate.month == now.month &&
                            _selectedMonthDate.year == now.year;

                        final matchingEvents = events.where((e) {
                          try {
                            final dt = DateTime.parse(e.eventDate);
                            return dt.year == _selectedMonthDate.year &&
                                dt.month == _selectedMonthDate.month &&
                                dt.day == cellNumber;
                          } catch (_) {
                            return false;
                          }
                        }).toList();

                        return Container(
                          height: 64,
                          padding: const EdgeInsets.all(4),
                          color: isToday
                              ? AppColors.subtleBg(context)
                              : AppColors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$cellNumber',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              ...matchingEvents.map((ev) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '★ ${ev.title}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.green700, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, AppStrings s, List<EventModel> events) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startOfWeek = _selectedWeekDate.subtract(Duration(days: _selectedWeekDate.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final headerStr = '${DateFormat('d MMM').format(startOfWeek)} – ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    final now = DateTime.now();

    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedWeekDate = _selectedWeekDate.subtract(const Duration(days: 7));
                  });
                },
              ),
               Text(
                headerStr,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
               IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedWeekDate = _selectedWeekDate.add(const Duration(days: 7));
                  });
                },
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  setState(() => _selectedWeekDate = DateTime.now());
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(s.todayButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final dayWidgets = weekDays.map((day) {
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                final dayEvents = events.where((e) {
                  try {
                    final dt = DateTime.parse(e.eventDate);
                    return dt.year == day.year && dt.month == day.month && dt.day == day.day;
                  } catch (_) {
                    return false;
                  }
                }).toList();

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.subtleBg(context)
                        : AppColors.card(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? AppColors.red800
                          : AppColors.border(context),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM').format(day),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isToday
                                  ? AppColors.red800
                                  : AppColors.textPrimary(context),
                            ),
                          ),
                          if (dayEvents.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${dayEvents.length}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.green700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (dayEvents.isEmpty)
                        Text(
                          s.noDataAvailable,
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                        )
                      else
                        ...dayEvents.map((ev) => Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Text('★ ', style: TextStyle(color: AppColors.green700, fontSize: 10)),
                                  Expanded(
                                    child: Text(
                                      ev.title,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                );
              }).toList();

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dayWidgets.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: w))).toList(),
                );
              } else {
                return Column(children: dayWidgets);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThreeMonthsView(BuildContext context, AppStrings s, List<EventModel> events) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final m1 = DateTime(_selectedThreeMonthsDate.year, _selectedThreeMonthsDate.month, 1);
    final m2 = DateTime(m1.year, m1.month + 1, 1);
    final m3 = DateTime(m1.year, m1.month + 2, 1);

    final m3End = DateTime(m3.year, m3.month + 1, 0, 23, 59, 59);
    final threeMonthsEvents = events.where((e) {
      try {
        final dt = DateTime.parse(e.eventDate);
        return !dt.isBefore(m1) && !dt.isAfter(m3End);
      } catch (_) {
        return false;
      }
    }).toList();

    threeMonthsEvents.sort((a, b) {
      final da = DateTime.tryParse(a.eventDate) ?? DateTime(1970);
      final db = DateTime.tryParse(b.eventDate) ?? DateTime(1970);
      return da.compareTo(db);
    });

    final headerRange = '${DateFormat('MMMM').format(m1)} – ${DateFormat('MMMM yyyy').format(m3)}';

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 19),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedThreeMonthsDate = DateTime(_selectedThreeMonthsDate.year, _selectedThreeMonthsDate.month - 3, 1);
                  });
                },
              ),
               Text(
                headerRange,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
               IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 19),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedThreeMonthsDate = DateTime(_selectedThreeMonthsDate.year, _selectedThreeMonthsDate.month + 3, 1);
                  });
                },
              ),
               OutlinedButton(
                onPressed: () {
                  setState(() => _selectedThreeMonthsDate = DateTime.now());
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(s.todayButton, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cal1 = _buildSingleMiniMonth(m1, events, isDark);
              final cal2 = _buildSingleMiniMonth(m2, events, isDark);
              final cal3 = _buildSingleMiniMonth(m3, events, isDark);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cal1),
                    const SizedBox(width: 16),
                    Expanded(child: cal2),
                    const SizedBox(width: 16),
                    Expanded(child: cal3),
                  ],
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 240, child: cal1),
                      const SizedBox(width: 12),
                      SizedBox(width: 240, child: cal2),
                      const SizedBox(width: 12),
                      SizedBox(width: 240, child: cal3),
                    ],
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            s.eventsInTheseThreeMonths,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          if (threeMonthsEvents.isEmpty)
            Text(
              s.noDataAvailable,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: threeMonthsEvents.map((ev) {
                String dateLabel = '';
                try {
                  final dt = DateTime.parse(ev.eventDate);
                  dateLabel = DateFormat('d MMM').format(dt);
                } catch (_) {
                  dateLabel = ev.eventDate;
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.green900.withValues(alpha: 0.4) : AppColors.greenLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.green700 : AppColors.green300,
                    ),
                  ),
                  child: Text(
                    '★ $dateLabel - ${ev.title}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.green300 : AppColors.green700,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleMiniMonth(DateTime monthDate, List<EventModel> events, bool isDark) {
    final monthName = DateFormat('MMMM yyyy').format(monthDate);
    final daysInMonth = DateUtils.getDaysInMonth(monthDate.year, monthDate.month);
    final firstWeekday = DateTime(monthDate.year, monthDate.month, 1).weekday % 7;
    final numRows = ((firstWeekday + daysInMonth) / 7).ceil();
    final dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.subtleBg(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              monthName,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Table(
            children: [
              TableRow(
                children: dayLetters.map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...List.generate(numRows, (rowIndex) {
                return TableRow(
                  children: List.generate(7, (colIndex) {
                    final dayNum = rowIndex * 7 + colIndex - firstWeekday + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const SizedBox(height: 22);
                    }
                    final isToday = dayNum == now.day &&
                        monthDate.month == now.month &&
                        monthDate.year == now.year;
                    final hasEvent = events.any((e) {
                      try {
                        final dt = DateTime.parse(e.eventDate);
                        return dt.year == monthDate.year &&
                            dt.month == monthDate.month &&
                            dt.day == dayNum;
                      } catch (_) {
                        return false;
                      }
                    });

                    return Container(
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasEvent
                            ? (isDark ? AppColors.green900 : AppColors.greenLight)
                            : (isToday ? AppColors.border(context) : AppColors.transparent),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: hasEvent || isToday ? FontWeight.bold : FontWeight.normal,
                          color: hasEvent
                              ? (isDark ? AppColors.white : AppColors.green700)
                              : AppColors.textPrimary(context),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  String _formatEventDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }
}
