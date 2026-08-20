import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
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

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          drawer: const CustomLeftDrawer(currentRoute: '/events'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<EventsBloc, EventsState>(
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
                      // Header Title & Subtitle
                      Text(
                        s.eventsTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.eventsSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // View Mode Switcher Controls
                      Row(
                        children: [
                          _buildViewModeButton(Icons.list_rounded, s.listView, 'list'),
                          const SizedBox(width: 8),
                          _buildViewModeButton(Icons.history_rounded, s.dayView, 'day'),
                          const SizedBox(width: 8),
                          _buildViewModeButton(Icons.calendar_month_rounded, s.calendarView, 'calendar'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // State Content
                      if (state is EventsLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is EventsErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<EventsBloc>().add(FetchEventsEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is EventsLoadedState)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sub Tabs Row (Assigned to me / Events)
                            Row(
                              children: [
                                _buildSubTab('★ ${s.assignedToMeTab} (0)', 0),
                                const SizedBox(width: 16),
                                _buildSubTab('${s.eventsTab} (${state.events.length})', 1),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Render View Mode Content
                            if (_selectedViewMode == 'calendar')
                              _buildMonthCalendarView(context, s, state.events)
                            else
                              _buildEventsListView(context, s, state.events),
                          ],
                        )
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

  Widget _buildViewModeButton(IconData icon, String label, String mode) {
    final isSelected = _selectedViewMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      onPressed: () => setState(() => _selectedViewMode = mode),
      icon: Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A)) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0F172A) : (isDark ? Colors.white24 : Colors.black12),
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
              color: isSelected ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)) : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 80,
            color: isSelected ? (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C)) : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsListView(BuildContext context, AppStrings s, List<EventModel> events) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _selectedSubTab == 0 ? events.where((e) => e.isMine == true).toList() : events;

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('No events found.', style: TextStyle(color: Colors.grey))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 180,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            final progress = item.total > 0 ? (item.done / item.total) : 0.0;
            final isDraft = item.reviewStatus.toLowerCase() == 'draft';

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Red Accent Line
                    Container(height: 3, color: const Color(0xFFB91C1C)),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Date Badge Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _formatEventDate(item.eventDate),
                                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Department Chips
                          if (item.departments != null && item.departments!.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              children: item.departments!.split(',').map((dep) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dep.trim(),
                                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 10),

                          // Progress Stats & Status Badge Row
                          Row(
                            children: [
                              Text(
                                '${item.done} of ${item.total} done · owner: ${item.owner ?? "N/A"}',
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDraft
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.reviewStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDraft
                                        ? (isDark ? Colors.white70 : const Color(0xFF475569))
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Checklist Button
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                            ),
                            child: Text(
                              '${s.checklistLabel} (${item.done}/${item.total})',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthCalendarView(BuildContext context, AppStrings s, List<EventModel> events) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'August 2026',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 700),
              child: Table(
                border: TableBorder.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                children: [
                  // Days Header Row
                  TableRow(
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    children: dayNames.map((d) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      );
                    }).toList(),
                  ),

                  // Calendar Grid Weeks
                  ...List.generate(5, (weekIndex) {
                    return TableRow(
                      children: List.generate(7, (dayOfWeek) {
                        final cellNumber = weekIndex * 7 + dayOfWeek - 5; // Aligning Aug 1 2026 to Sat
                        if (cellNumber < 1 || cellNumber > 31) {
                          return const SizedBox(height: 64);
                        }

                        final matchingEvents = events.where((e) {
                          try {
                            final dt = DateTime.parse(e.eventDate);
                            return dt.day == cellNumber;
                          } catch (_) {
                            return false;
                          }
                        }).toList();

                        return Container(
                          height: 64,
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$cellNumber',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ...matchingEvents.map((ev) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '★ ${ev.title}',
                                    style: const TextStyle(fontSize: 9, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
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
