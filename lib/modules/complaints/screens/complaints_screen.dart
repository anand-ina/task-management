import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/complaints_bloc.dart';
import '../bloc/complaints_event.dart';
import '../bloc/complaints_state.dart';
import '../dialogs/raise_complaint_dialog.dart';
import '../dialogs/ticket_details_dialog.dart';
import '../models/ticket_model.dart';
import 'complaints_history_insights_screen.dart';
import 'suggestion_box_entry_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  final int? initialTicketId;
  final String? initialSearchQuery;
  final String? initialStatusTab;
  final String? initialTypeFilter;
  final String? initialSourceFilter;

  const ComplaintsScreen({
    super.key,
    this.initialTicketId,
    this.initialSearchQuery,
    this.initialStatusTab,
    this.initialTypeFilter,
    this.initialSourceFilter,
  });

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['all', 'open', 'overdue', 'resolved'];

  @override
  void initState() {
    super.initState();
    int initialTabIndex = 1; // default to 'open'
    if (widget.initialStatusTab != null) {
      final s = widget.initialStatusTab!.toLowerCase();
      if (s == 'all' || s == 'everything') {
        initialTabIndex = 0;
      } else if (s == 'open') {
        initialTabIndex = 1;
      } else if (s == 'overdue') {
        initialTabIndex = 2;
      } else if (s == 'resolved') {
        initialTabIndex = 3;
      }
    }
    _tabController = TabController(length: 4, vsync: this, initialIndex: initialTabIndex);
    _tabController.addListener(_handleTabSelection);

    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialStatus = widget.initialStatusTab ?? 'open';
      _dispatchFetchWithCurrentFilters(
        status: initialStatus,
        type: widget.initialTypeFilter,
        source: widget.initialSourceFilter,
        query: widget.initialSearchQuery,
      );
      if (widget.initialTicketId != null) {
        TicketDetailsDialog.show(
          context,
          ticketId: widget.initialTicketId!,
          onUpdated: () => _dispatchFetchWithCurrentFilters(),
        );
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final tabKey = _tabs[_tabController.index];
      _dispatchFetchWithCurrentFilters(status: tabKey);
    }
  }

  void _dispatchFetchWithCurrentFilters({
    String? status,
    String? type,
    String? source,
    String? category,
    String? mine,
    String? owner,
    String? query,
  }) {
    final state = context.read<ComplaintsBloc>().state;
    String currentStatus = status ?? (state is ComplaintsLoadedState ? state.statusTab : _tabs[_tabController.index]);
    String currentType = type ?? (state is ComplaintsLoadedState ? state.typeFilter : 'All types');
    String currentSource = source ?? (state is ComplaintsLoadedState ? state.sourceFilter : 'Parents & students');
    String currentCategory = category ?? (state is ComplaintsLoadedState ? state.categoryFilter : 'All categories');
    String currentMine = mine ?? (state is ComplaintsLoadedState ? state.mineFilter : '');
    String currentQuery = query ?? _searchController.text;

    context.read<ComplaintsBloc>().add(FetchComplaintsEvent(
      statusTab: currentStatus,
      type: currentType,
      source: currentSource,
      category: currentCategory,
      mine: currentMine,
      searchQuery: currentQuery,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Color _getStatusBgColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'new':
        return isDark ? Colors.amber.shade900.withOpacity(0.3) : const Color(0xFFFEF3C7);
      case 'in_progress':
        return isDark ? Colors.blue.shade900.withOpacity(0.3) : const Color(0xFFDBEAFE);
      case 'resolved':
        return isDark ? Colors.green.shade900.withOpacity(0.3) : const Color(0xFFDCFCE7);
      case 'overdue':
        return isDark ? Colors.red.shade900.withOpacity(0.3) : const Color(0xFFFEE2E2);
      default:
        return isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFD97706);
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'overdue':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await ExitConfirmationDialog.show(context);
        }
      },
      child: Scaffold(
        appBar: const CustomAppBar(),
        drawer: const CustomLeftDrawer(currentRoute: '/complaints'),
        backgroundColor: isDark ? const Color(0xFF0D1424) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF8B1D24),
            onRefresh: () async {
              final tabKey = _tabs[_tabController.index];
              context.read<ComplaintsBloc>().add(FetchComplaintsEvent(statusTab: tabKey));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title & Header Actions
                  _buildHeaderRow(context, s, isDark),
                  const SizedBox(height: 20),

                  // Stat Summary Cards
                  _buildStatCardsRow(s, isDark),
                  const SizedBox(height: 24),

                  // Tabs
                  _buildTabBar(s, isDark),
                  const SizedBox(height: 16),

                  // Search and Filters
                  _buildFilterBar(s, isDark),
                  const SizedBox(height: 16),

                  // Ticket List Table / Mobile Cards
                  _buildTicketContent(s, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, AppStrings s, bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 750;

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
                    s.complaintsAndFeedbackTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.complaintsAndFeedbackSubtitle,
                    style: TextStyle(
                      fontSize: 13,
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
          const SizedBox(height: 14),
          _buildHeaderActions(s, isDark),
        ],
      ],
    );
  }

  Widget _buildHeaderActions(AppStrings s, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SuggestionBoxEntryScreen()),
            );
          },
          icon: const Text('🗳', style: TextStyle(fontSize: 14)),
          label: Text(s.suggestionBoxEntryButton, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
            side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ComplaintsHistoryInsightsScreen()),
            );
          },
          icon: const Text('▤', style: TextStyle(fontSize: 14)),
          label: Text(s.historyAndInsightsButton, style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
            side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => RaiseComplaintDialog.show(
            context,
            onTicketCreated: () {
              final tabKey = _tabs[_tabController.index];
              _dispatchFetchWithCurrentFilters(status: tabKey);
            },
          ),
           label: Text(s.raiseRequestButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B1D24),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsRow(AppStrings s, bool isDark) {
    return BlocBuilder<ComplaintsBloc, ComplaintsState>(
      builder: (context, state) {
        TicketCountsModel counts = const TicketCountsModel();
        String currentStatus = 'open';
        if (state is ComplaintsLoadedState) {
          counts = state.counts;
          currentStatus = state.statusTab;
        }

        final totalCount = counts.allTickets > 0
            ? counts.allTickets
            : (counts.newCount + counts.inProgress + counts.overdue + counts.resolvedMonth);

        final cards = [
          _buildStatCard(
            count: totalCount.toString(),
            label: s.statEverythingReceived,
            accentColor: const Color(0xFF1E293B),
            isDark: isDark,
            isSelected: currentStatus == 'all' || currentStatus == 'everything',
            onTap: () {
              if (_tabController.index != 0) {
                _tabController.animateTo(0);
              }
              _dispatchFetchWithCurrentFilters(status: 'all');
            },
          ),
          _buildStatCard(
            count: counts.newCount.toString(),
            label: s.statNewNotPickedUp,
            accentColor: const Color(0xFFF59E0B),
            isDark: isDark,
            isSelected: currentStatus == 'new',
            onTap: () {
              final newStatus = currentStatus == 'new' ? _tabs[_tabController.index] : 'new';
              _dispatchFetchWithCurrentFilters(status: newStatus);
            },
          ),
          _buildStatCard(
            count: counts.inProgress.toString(),
            label: s.statInProgress,
            accentColor: const Color(0xFF3B82F6),
            isDark: isDark,
            isSelected: currentStatus == 'in_progress',
            onTap: () {
              final newStatus = currentStatus == 'in_progress' ? _tabs[_tabController.index] : 'in_progress';
              _dispatchFetchWithCurrentFilters(status: newStatus);
            },
          ),
          _buildStatCard(
            count: counts.overdue.toString(),
            label: s.statPastTargetDate,
            accentColor: const Color(0xFFEF4444),
            isDark: isDark,
            isSelected: currentStatus == 'overdue',
            onTap: () {
              if (_tabController.index != 2) {
                _tabController.animateTo(2);
              }
              _dispatchFetchWithCurrentFilters(status: 'overdue');
            },
          ),
          _buildStatCard(
            count: counts.resolvedMonth.toString(),
            label: s.statResolvedThisMonth,
            accentColor: const Color(0xFF10B981),
            isDark: isDark,
            isSelected: currentStatus == 'resolved',
            onTap: () {
              if (_tabController.index != 3) {
                _tabController.animateTo(3);
              }
              _dispatchFetchWithCurrentFilters(status: 'resolved');
            },
          ),
          _buildStatCard(
            count: counts.avgDays != null ? '${counts.avgDays}d' : '—',
            label: s.statAvgTimeToResolve,
            accentColor: const Color(0xFF06B6D4),
            isDark: isDark,
            isSelected: false,
            onTap: null,
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
      },
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color accentColor,
    required bool isDark,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (accentColor == const Color(0xFF1E293B) && isDark ? Colors.white : accentColor)
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
                color: accentColor == const Color(0xFF1E293B) && isDark ? Colors.white70 : accentColor,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                height: 1.2,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppStrings s, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF8B1D24),
        indicatorWeight: 3,
        labelColor: const Color(0xFF8B1D24),
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: [
          Tab(text: s.tabEverything),
          Tab(text: s.tabOpen),
          Tab(text: s.tabPastTargetDate),
          Tab(text: s.tabResolved),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppStrings s, bool isDark) {
    return BlocBuilder<ComplaintsBloc, ComplaintsState>(
      builder: (context, state) {
        String typeFilter = 'All types';
        String sourceFilter = 'Parents & students';
        String categoryFilter = 'All categories';
        String ownerFilter = s.filterEveryones;
        String mineFilter = '';
        List<String> categories = [];

        if (state is ComplaintsLoadedState) {
          typeFilter = state.typeFilter;
          sourceFilter = state.sourceFilter;
          categoryFilter = state.categoryFilter;
          ownerFilter = state.ownerFilter;
          mineFilter = state.mineFilter;
          categories = state.meta.categories;
        }

        String selectedOwnerLabel = s.filterEveryones;
        if (mineFilter == 'owned' || ownerFilter == s.receivedByMe) {
          selectedOwnerLabel = s.receivedByMe;
        } else if (mineFilter == 'raised' || ownerFilter == s.assignedByMe) {
          selectedOwnerLabel = s.assignedByMe;
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Search Input
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _searchController,
                onChanged: (val) {
                  _dispatchFetchWithCurrentFilters(query: val);
                },
                decoration: InputDecoration(
                  hintText: s.searchTicketsPlaceholder,
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),

            // Type Dropdown
            _buildFilterDropdown(
              value: typeFilter,
              items: [s.filterAllTypes, s.typeComplaint, s.typeFeedbackSuggestion, s.typeAppreciation],
              isDark: isDark,
              onChanged: (val) {
                if (val != null) {
                  context.read<ComplaintsBloc>().add(FilterComplaintsEvent(typeFilter: val));
                  _dispatchFetchWithCurrentFilters(type: val);
                }
              },
            ),

            // Source Dropdown
            _buildFilterDropdown(
              value: sourceFilter,
              items: [s.filterParentsAndStudents, s.receivedFromParent, s.receivedFromStudent],
              isDark: isDark,
              onChanged: (val) {
                if (val != null) {
                  context.read<ComplaintsBloc>().add(FilterComplaintsEvent(sourceFilter: val));
                  _dispatchFetchWithCurrentFilters(source: val);
                }
              },
            ),

            // Category Dropdown
            _buildFilterDropdown(
              value: categoryFilter,
              items: [s.filterAllCategories, ...categories],
              isDark: isDark,
              onChanged: (val) {
                if (val != null) {
                  context.read<ComplaintsBloc>().add(FilterComplaintsEvent(categoryFilter: val));
                  _dispatchFetchWithCurrentFilters(category: val);
                }
              },
            ),

            // Owner Dropdown (Everyone's, Received by me, Assigned by me)
            _buildFilterDropdown(
              value: selectedOwnerLabel,
              items: [s.filterEveryones, s.receivedByMe, s.assignedByMe],
              isDark: isDark,
              onChanged: (val) {
                if (val != null) {
                  String newMine = '';
                  if (val == s.receivedByMe) {
                    newMine = 'owned';
                  } else if (val == s.assignedByMe) {
                    newMine = 'raised';
                  }
                  context.read<ComplaintsBloc>().add(FilterComplaintsEvent(ownerFilter: val));
                  _dispatchFetchWithCurrentFilters(mine: newMine, owner: val);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 12),
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 10)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTicketContent(AppStrings s, bool isDark) {
    return BlocBuilder<ComplaintsBloc, ComplaintsState>(
      builder: (context, state) {
        if (state is ComplaintsLoadingState) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF8B1D24)),
            ),
          );
        }

        if (state is ComplaintsErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (state is ComplaintsLoadedState) {
          final items = state.filteredItems;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  s.noTicketsFound,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          if (screenWidth < 750) {
            // Mobile comfortable card view!
            return Column(
              children: items.map((ticket) => _buildMobileTicketCard(ticket, s, isDark)).toList(),
            );
          }

          // Full Desktop / Tablet Horizontal Table
          return _buildDesktopTicketTable(items, s, isDark);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMobileTicketCard(TicketItemModel ticket, AppStrings s, bool isDark) {
    final statusBg = _getStatusBgColor(ticket.status, isDark);
    final statusText = _getStatusTextColor(ticket.status);

    return InkWell(
      onTap: () => TicketDetailsDialog.show(
        context,
        ticketId: ticket.id,
        onUpdated: () => _dispatchFetchWithCurrentFilters(),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Ticket No & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.ticketNo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Type Chip & Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.type,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(ticket.receivedAt),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: From / Student
            Text(
              '${s.colFrom}: ${ticket.source.toUpperCase()} ${ticket.isAnonymous ? "· Anon" : ""} | ${s.colStudent}: ${ticket.studentName ?? "—"} · ${ticket.classSection ?? ""}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),

            // Row 4: Description
            if (ticket.description.isNotEmpty) ...[
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
            ],

            const Divider(height: 1),
            const SizedBox(height: 8),

            // Row 5: Owner & Task
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${s.colWith}: ${ticket.ownerName ?? "—"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${s.colTask}: ${ticket.taskNo ?? "—"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTicketTable(List<TicketItemModel> items, AppStrings s, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
          horizontalMargin: 16,
          columnSpacing: 20,
          columns: [
            DataColumn(label: Text(s.colTicket, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colFrom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colStudent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colAbout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colWith, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colReceived, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
            DataColumn(label: Text(s.colTask, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          ],
          rows: items.map((ticket) {
            final statusBg = _getStatusBgColor(ticket.status, isDark);
            final statusText = _getStatusTextColor(ticket.status);

            return DataRow(
              onSelectChanged: (_) => TicketDetailsDialog.show(
                context,
                ticketId: ticket.id,
                onUpdated: () => _dispatchFetchWithCurrentFilters(),
              ),
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => TicketDetailsDialog.show(
                      context,
                      ticketId: ticket.id,
                      onUpdated: () => _dispatchFetchWithCurrentFilters(),
                    ),
                    child: Text(
                      ticket.ticketNo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.type,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${ticket.source.toUpperCase()}${ticket.isAnonymous ? " · Anon" : ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    '${ticket.studentName ?? "—"} · ${ticket.classSection ?? ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    ticket.aboutKind,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    ticket.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusText,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    ticket.ownerName ?? '—',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(ticket.receivedAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    ticket.taskNo ?? '—',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
