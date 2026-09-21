import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import '../bloc/complaints_bloc.dart';
import '../bloc/complaints_event.dart';
import '../bloc/complaints_state.dart';
import '../dialogs/raise_complaint_dialog.dart';
import '../dialogs/ticket_details_dialog.dart';
import '../models/ticket_meta_model.dart';
import '../models/ticket_model.dart';
import 'complaints_history_insights_screen.dart';
import 'suggestion_box_entry_screen.dart';

class SourceComplaintsScreen extends StatefulWidget {
  final String source; // 'parent' or 'student'

  const SourceComplaintsScreen({
    super.key,
    required this.source,
  });

  @override
  State<SourceComplaintsScreen> createState() => _SourceComplaintsScreenState();
}

class _SourceComplaintsScreenState extends State<SourceComplaintsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _currentStatusTab = 'everything'; // 'everything', 'open', 'overdue', 'resolved'
  String _currentTypes = 'complaint,feedback';
  String _selectedCategory = 'All categories';
  String _selectedMine = "Everyone's";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTickets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTickets() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (mounted) {
      context.read<ComplaintsBloc>().add(
            FetchSourceComplaintsEvent(
              source: widget.source,
              statusTab: _currentStatusTab,
              types: _currentTypes,
              category: _selectedCategory,
              mine: _selectedMine,
              searchQuery: _searchController.text.trim(),
            ),
          );
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 800;
    final String currentRoute;
    if (widget.source == 'parent') {
      currentRoute = '/complaints/parents';
    } else if (widget.source == 'staff') {
      currentRoute = '/complaints/staff';
    } else {
      currentRoute = '/complaints/students';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await ExitConfirmationDialog.show(context);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: const CustomAppBar(),
        drawer: CustomLeftDrawer(currentRoute: currentRoute),
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: BlocBuilder<ComplaintsBloc, ComplaintsState>(
            builder: (context, state) {
              List<TicketItemModel> items = [];
              TicketCountsModel counts = const TicketCountsModel();
              TicketMetaModel meta = const TicketMetaModel();
              bool isLoading = false;
              String? errorMessage;

              if (state is ComplaintsLoadingState) {
                isLoading = true;
              } else if (state is SourceComplaintsLoadedState && state.source == widget.source) {
                items = state.items;
                counts = state.counts;
                meta = state.meta;
                isLoading = state.isLoading;
                errorMessage = state.errorMessage;
              }

              return RefreshIndicator(
                color: const Color(0xFF8B1D24),
                onRefresh: _fetchTickets,
                child: isLoading && items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFF8B1D24)),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Title, Subtitle, and Action Buttons
                            _buildHeaderRow(s, isDark, isMobile),
                            const SizedBox(height: 18),

                            if (errorMessage != null) ...[
                              _buildErrorBanner(errorMessage, isDark),
                              const SizedBox(height: 16),
                            ],

                            // Stat Summary Cards (6 cards)
                            _buildStatCardsRow(counts, s, isDark),
                            const SizedBox(height: 20),

                            // Tabs Row (Everything, Open, Past target date, Resolved)
                            _buildTabsRow(s, isDark),
                            const SizedBox(height: 16),

                            // Filter Bar (Search, Type, Category, Mine)
                            _buildFilterBar(meta, s, isDark),
                            const SizedBox(height: 16),

                            // Ticket Container List (Cards)
                            _buildTicketsContainerList(items, s, isDark, isMobile),
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

  Widget _buildHeaderRow(AppStrings s, bool isDark, bool isMobile) {
    final String title;
    final String subtitle;
    if (widget.source == 'parent') {
      title = s.parentsComplaintsAndFeedbacks;
      subtitle = s.parentsComplaintsSubtitle;
    } else if (widget.source == 'staff') {
      title = s.staffComplaintsAndFeedbacks;
      subtitle = s.staffComplaintsSubtitle;
    } else {
      title = s.studentsComplaintsAndFeedbacks;
      subtitle = s.studentsComplaintsSubtitle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              _buildHeaderActions(s, isDark),
            ],
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(s, isDark),
        ],
      ],
    );
  }

  Widget _buildHeaderActions(AppStrings s, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Suggestion Box Entry button (for students only)
        if (widget.source == 'student')
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SuggestionBoxEntryScreen()),
              );
            },
            icon: const Text('🗳️', style: TextStyle(fontSize: 13)),
            label: Text(
              s.suggestionBoxEntry,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

        // Dashboard button
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComplaintsHistoryInsightsScreen()),
            );
          },
          icon: const Icon(Icons.dashboard_outlined, size: 15),
          label: Text(
            s.complaintsDashboardTitle,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),

        // Raise Request button
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => const RaiseComplaintDialog(),
            ).then((val) {
              if (val == true) {
                _fetchTickets();
              }
            });
          },
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: Text(
            s.raiseRequestButton,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B1D24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 6 Stat Cards (Everything received, New - not picked up, In progress, Past target date, Resolved this month, Avg. time to resolve)
  Widget _buildStatCardsRow(TicketCountsModel counts, AppStrings s, bool isDark) {
    final totalCount = counts.allTickets > 0
        ? counts.allTickets
        : (counts.newCount + counts.inProgress + counts.overdue + counts.resolvedMonth);

    final cards = [
      _buildStatCard(
        count: totalCount.toString(),
        label: s.statEverythingReceived,
        accentColor: const Color(0xFF1E293B),
        isDark: isDark,
        isSelected: _currentStatusTab == 'everything',
        onTap: () {
          setState(() => _currentStatusTab = 'everything');
          _fetchTickets();
        },
      ),
      _buildStatCard(
        count: counts.newCount.toString(),
        label: s.statNewNotPickedUp,
        accentColor: const Color(0xFFF59E0B),
        isDark: isDark,
        isSelected: false,
        onTap: () {
          setState(() => _currentStatusTab = 'open');
          _fetchTickets();
        },
      ),
      _buildStatCard(
        count: counts.inProgress.toString(),
        label: s.statInProgress,
        accentColor: const Color(0xFF3B82F6),
        isDark: isDark,
        isSelected: _currentStatusTab == 'open',
        onTap: () {
          setState(() => _currentStatusTab = 'open');
          _fetchTickets();
        },
      ),
      _buildStatCard(
        count: counts.overdue.toString(),
        label: s.statPastTargetDate,
        accentColor: const Color(0xFFEF4444),
        isDark: isDark,
        isSelected: _currentStatusTab == 'overdue',
        onTap: () {
          setState(() => _currentStatusTab = 'overdue');
          _fetchTickets();
        },
      ),
      _buildStatCard(
        count: counts.resolvedMonth.toString(),
        label: s.statResolvedThisMonth,
        accentColor: const Color(0xFF10B981),
        isDark: isDark,
        isSelected: _currentStatusTab == 'resolved',
        onTap: () {
          setState(() => _currentStatusTab = 'resolved');
          _fetchTickets();
        },
      ),
      _buildStatCard(
        count: counts.avgDays != null ? '${counts.avgDays}' : '—',
        label: s.statAvgTimeToResolve,
        accentColor: const Color(0xFF06B6D4),
        isDark: isDark,
        isSelected: false,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: card,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color accentColor,
    required bool isDark,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B1D24)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accentColor == const Color(0xFF1E293B) && isDark ? Colors.white : accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsRow(AppStrings s, bool isDark) {
    final tabs = [
      {'key': 'everything', 'label': s.tabEverything},
      {'key': 'open', 'label': s.tabOpen},
      {'key': 'overdue', 'label': s.tabPastTargetDate},
      {'key': 'resolved', 'label': s.tabResolved},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _currentStatusTab == tab['key'];
            return InkWell(
              onTap: () {
                if (_currentStatusTab != tab['key']) {
                  setState(() {
                    _currentStatusTab = tab['key']!;
                  });
                  _fetchTickets();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xFF8B1D24) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tab['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF8B1D24)
                        : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterBar(TicketMetaModel meta, AppStrings s, bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 750;

    final searchField = SizedBox(
      width: isMobile ? double.infinity : 280,
      height: 38,
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: s.searchTicketsPlaceholder,
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          ),
          prefixIcon: const Icon(Icons.search, size: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF8B1D24)),
          ),
        ),
        onSubmitted: (_) => _fetchTickets(),
      ),
    );

    final typeDropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currentTypes,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: [
            DropdownMenuItem(
              value: 'complaint,feedback',
              child: Text(s.filterComplaintsAndFeedback),
            ),
            DropdownMenuItem(
              value: 'complaint',
              child: Text(s.filterComplaintsOnly),
            ),
            DropdownMenuItem(
              value: 'feedback',
              child: Text(s.filterFeedbackOnly),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _currentTypes = val);
              _fetchTickets();
            }
          },
        ),
      ),
    );

    final categoryDropdown = SearchableFilterDropdown<String>(
      value: _selectedCategory,
      hint: s.filterAllCategories,
      searchHint: 'Search category...',
      items: [
        SearchableDropdownItem<String>(value: 'All categories', label: s.filterAllCategories),
        ...meta.categories.map(
          (c) => SearchableDropdownItem<String>(value: c, label: c),
        ),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedCategory = val);
          _fetchTickets();
        }
      },
    );

    final mineDropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMine,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: [
            DropdownMenuItem(value: "Everyone's", child: Text(s.filterEveryones)),
            DropdownMenuItem(value: "owned", child: Text(s.assignedToMe)),
            DropdownMenuItem(value: "raised", child: Text(s.createdByMe)),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedMine = val);
              _fetchTickets();
            }
          },
        ),
      ),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        searchField,
        typeDropdown,
        categoryDropdown,
        mineDropdown,
      ],
    );
  }

  /// Tickets rendered strictly as a container list (not table format) per user specification
  Widget _buildTicketsContainerList(
    List<TicketItemModel> items,
    AppStrings s,
    bool isDark,
    bool isMobile,
  ) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 40,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                s.noTicketsFound,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header Row (if wide screen)
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withOpacity(0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: _buildHeaderCell(s.colTicket, isDark)),
                  Expanded(flex: 2, child: _buildHeaderCell(s.colType, isDark)),
                  Expanded(flex: 2, child: _buildHeaderCell(s.colStudent, isDark)),
                  Expanded(flex: 3, child: _buildHeaderCell(s.colAbout, isDark)),
                  Expanded(flex: 2, child: _buildHeaderCell(s.colCategory, isDark)),
                  Expanded(flex: 2, child: _buildHeaderCell(s.colStatus, isDark)),
                  Expanded(flex: 2, child: _buildHeaderCell(s.colWith, isDark)),
                  Expanded(flex: 3, child: _buildHeaderCell(s.colReceived, isDark)),
                  Expanded(flex: 2, child: _buildHeaderCell(s.colTask, isDark)),
                ],
              ),
            ),

          // Container Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            itemBuilder: (context, index) {
              final ticket = items[index];
              return isMobile
                  ? _buildMobileTicketContainerCard(ticket, s, isDark)
                  : _buildDesktopTicketContainerRow(ticket, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
    );
  }

  void _onTicketTapped(TicketItemModel ticket) {
    TicketDetailsDialog.show(
      context,
      ticketId: ticket.id,
      onUpdated: _fetchTickets,
    );
  }

  /// Container Row for Desktop / Tablet screens
  Widget _buildDesktopTicketContainerRow(TicketItemModel ticket, bool isDark) {
    final isConfidential = ticket.visibility.toLowerCase() == 'confidential';
    final isOverdue = ticket.taskDueDate != null &&
        ticket.taskDueDate!.isNotEmpty &&
        DateTime.tryParse(ticket.taskDueDate!)?.isBefore(DateTime.now()) == true &&
        ticket.status.toLowerCase() != 'resolved';

    return InkWell(
      onTap: () => _onTicketTapped(ticket),
      hoverColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // TICKET
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ticket.ticketNo,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (isConfidential) ...[
                    const SizedBox(width: 4),
                    const Text('🔒', style: TextStyle(fontSize: 11)),
                  ],
                ],
              ),
            ),

            // TYPE
            Expanded(
              flex: 2,
              child: _buildTypePill(ticket.type, isDark),
            ),

            // STUDENT
            Expanded(
              flex: 2,
              child: Text(
                ticket.studentName?.isNotEmpty == true
                    ? '${ticket.studentName} · ${ticket.classSection ?? ''}'
                    : '—',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ABOUT
            Expanded(
              flex: 3,
              child: Text(
                ticket.aboutUserName?.isNotEmpty == true
                    ? 'Staff — ${ticket.aboutUserName}'
                    : (ticket.aboutDepartmentName?.isNotEmpty == true
                        ? 'Dept — ${ticket.aboutDepartmentName}'
                        : (ticket.aboutText?.isNotEmpty == true ? ticket.aboutText! : '—')),
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // CATEGORY
            Expanded(
              flex: 2,
              child: Text(
                ticket.category.isNotEmpty ? ticket.category : '—',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF475569),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // STATUS
            Expanded(
              flex: 2,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _buildStatusPill(ticket.status, isDark),
                  if (isOverdue) _buildOverduePill(),
                ],
              ),
            ),

            // WITH
            Expanded(
              flex: 2,
              child: Text(
                ticket.ownerName?.isNotEmpty == true ? ticket.ownerName! : '—',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // RECEIVED
            Expanded(
              flex: 3,
              child: Text(
                _formatDate(ticket.receivedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                ),
              ),
            ),

            // TASK
            Expanded(
              flex: 2,
              child: Text(
                ticket.taskNo?.isNotEmpty == true ? ticket.taskNo! : '—',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Container Card for Mobile screens
  Widget _buildMobileTicketContainerCard(TicketItemModel ticket, AppStrings s, bool isDark) {
    final isConfidential = ticket.visibility.toLowerCase() == 'confidential';
    final isOverdue = ticket.taskDueDate != null &&
        ticket.taskDueDate!.isNotEmpty &&
        DateTime.tryParse(ticket.taskDueDate!)?.isBefore(DateTime.now()) == true &&
        ticket.status.toLowerCase() != 'resolved';

    return InkWell(
      onTap: () => _onTicketTapped(ticket),
      hoverColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      ticket.ticketNo,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (isConfidential) ...[
                      const SizedBox(width: 4),
                      const Text('🔒', style: TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
                _buildTypePill(ticket.type, isDark),
              ],
            ),
            const SizedBox(height: 8),

            if (ticket.studentName?.isNotEmpty == true) ...[
              Text(
                '${s.studentHeader}: ${ticket.studentName} · ${ticket.classSection ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
            ],

            if (ticket.aboutUserName?.isNotEmpty == true) ...[
              Text(
                'About: Staff — ${ticket.aboutUserName}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
            ],

            Row(
              children: [
                Text(
                  '${ticket.category} · ',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                _buildStatusPill(ticket.status, isDark),
                if (isOverdue) ...[
                  const SizedBox(width: 4),
                  _buildOverduePill(),
                ],
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'With: ${ticket.ownerName ?? '—'}',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                Text(
                  _formatDate(ticket.receivedAt),
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePill(String type, bool isDark) {
    final isComplaint = type.toLowerCase().contains('complaint');
    final color = isComplaint ? const Color(0xFFE11D48) : const Color(0xFF2563EB);
    final bg = isComplaint
        ? (isDark ? const Color(0xFF881337).withOpacity(0.35) : const Color(0xFFFFF1F2))
        : (isDark ? const Color(0xFF1E3A8A).withOpacity(0.35) : const Color(0xFFEFF6FF));

    final label = isComplaint ? 'Complaint' : 'Feedback / Suggestion';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'new':
        color = const Color(0xFFD97706);
        bg = isDark ? const Color(0xFF78350F).withOpacity(0.4) : const Color(0xFFFEF3C7);
        break;
      case 'in_progress':
        color = const Color(0xFF2563EB);
        bg = isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFFDBEAFE);
        break;
      case 'resolved':
        color = const Color(0xFF16A34A);
        bg = isDark ? const Color(0xFF14532D).withOpacity(0.4) : const Color(0xFFDCFCE7);
        break;
      default:
        color = const Color(0xFF64748B);
        bg = isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOverduePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'overdue',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFFDC2626),
        ),
      ),
    );
  }
}
