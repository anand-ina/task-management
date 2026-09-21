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

class AppreciationsScreen extends StatefulWidget {
  const AppreciationsScreen({super.key});

  @override
  State<AppreciationsScreen> createState() => _AppreciationsScreenState();
}

class _AppreciationsScreenState extends State<AppreciationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  String _selectedScope = 'Everyone';
  String _selectedCategory = 'All categories';
  String _selectedMine = "Everyone's";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppreciations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppreciations() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (mounted) {
      context.read<ComplaintsBloc>().add(
            FetchAppreciationsEvent(
              category: _selectedCategory,
              mine: _selectedMine,
              searchQuery: _searchController.text.trim(),
              source: _selectedScope,
            ),
          );
    }
  }

  String _formatSimpleDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _getStatusBgColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'new':
        return isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7);
      case 'pending_reward':
      case 'awaiting_approval':
        return isDark ? const Color(0xFF4C0519) : const Color(0xFFFFE4E6);
      case 'awarded':
      case 'resolved':
        return isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
      case 'recorded':
        return isDark ? const Color(0xFF083344) : const Color(0xFFCFFAFE);
      default:
        return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    }
  }

  Color _getStatusTextColor(String status, bool isDark) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFD97706);
      case 'pending_reward':
      case 'awaiting_approval':
        return const Color(0xFFE11D48);
      case 'awarded':
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'recorded':
        return const Color(0xFF0891B2);
      default:
        return isDark ? Colors.grey.shade300 : const Color(0xFF475569);
    }
  }

  String _formatStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return 'New';
      case 'pending_reward':
        return 'Pending reward';
      case 'awarded':
        return 'Awarded';
      case 'recorded':
        return 'Recorded';
      case 'resolved':
        return 'Resolved';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 800;

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
        drawer: const CustomLeftDrawer(currentRoute: '/complaints/appreciations'),
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
              } else if (state is AppreciationsLoadedState) {
                items = state.items;
                counts = state.counts;
                meta = state.meta;
                isLoading = state.isLoading;
                errorMessage = state.errorMessage;
              }

              return RefreshIndicator(
                color: const Color(0xFF8B1D24),
                onRefresh: _fetchAppreciations,
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

                            // 4 Stat Summary Cards
                            _buildStatCardsRow(counts, s, isDark),
                            const SizedBox(height: 20),

                            // Filter Bar
                            _buildFilterBar(meta, s, isDark),
                            const SizedBox(height: 16),

                            // Content: Table on desktop, Cards on mobile
                            if (isMobile)
                              _buildMobileCardsList(items, s, isDark)
                            else
                              _buildDesktopTable(items, s, isDark),
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
                    s.appreciations,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.appreciationsSubtitle,
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
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => const RaiseComplaintDialog(),
            ).then((val) {
              if (val == true) {
                _fetchAppreciations();
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
            foregroundColor: Colors.white,
            elevation: 0,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF87171)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.red.shade200 : const Color(0xFFB91C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4 Stat Summary Cards matching Image 1
  Widget _buildStatCardsRow(TicketCountsModel counts, AppStrings s, bool isDark) {
    final cards = [
      _buildStatCard(
        count: counts.allTickets.toString(),
        label: s.appreciationsReceived,
        accentColor: const Color(0xFF10B981),
        isDark: isDark,
      ),
      _buildStatCard(
        count: counts.recorded.toString(),
        label: s.recordedBadge,
        accentColor: const Color(0xFF06B6D4),
        isDark: isDark,
      ),
      _buildStatCard(
        count: counts.pendingReward.toString(),
        label: s.awaitingDirectorApproval,
        accentColor: const Color(0xFFF43F5E),
        isDark: isDark,
      ),
      _buildStatCard(
        count: counts.awarded.toString(),
        label: s.rewardPointsGiven,
        accentColor: const Color(0xFF3B82F6),
        isDark: isDark,
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
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Filter Bar matching Image 1
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14),
                  onPressed: () {
                    _searchController.clear();
                    _fetchAppreciations();
                  },
                )
              : null,
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
        onSubmitted: (_) => _fetchAppreciations(),
      ),
    );

    final scopeDropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedScope,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: [
            DropdownMenuItem(value: 'Everyone', child: Text(s.scopeEveryone)),
            DropdownMenuItem(value: 'Parents', child: Text(s.scopeParents)),
            DropdownMenuItem(value: 'Students', child: Text(s.scopeStudents)),
            DropdownMenuItem(value: 'Staff', child: Text(s.scopeStaff)),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedScope = val);
              _fetchAppreciations();
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
          _fetchAppreciations();
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
            DropdownMenuItem(value: "Everyone's", child: Text(s.everyonesFilter)),
            DropdownMenuItem(value: "owned", child: Text(s.assignedToMe)),
            DropdownMenuItem(value: "raised", child: Text(s.createdByMe)),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedMine = val);
              _fetchAppreciations();
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
        scopeDropdown,
        categoryDropdown,
        mineDropdown,
      ],
    );
  }

  /// Desktop Data Table matching Image 1
  Widget _buildDesktopTable(List<TicketItemModel> items, AppStrings s, bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final headerTextColor = isDark ? Colors.grey.shade300 : const Color(0xFF64748B);

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            s.noTicketsFound,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1000),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(headerBg),
              headingTextStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: headerTextColor,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              columnSpacing: 20,
              horizontalMargin: 16,
              columns: const [
                DataColumn(label: Text('TICKET')),
                DataColumn(label: Text('TYPE')),
                DataColumn(label: Text('FROM')),
                DataColumn(label: Text('STUDENT')),
                DataColumn(label: Text('ABOUT')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('WITH')),
                DataColumn(label: Text('RECEIVED')),
                DataColumn(label: Text('TASK')),
              ],
              rows: items.map((ticket) {
                return DataRow(
                  onSelectChanged: (_) {
                    _openTicketDetails(ticket.id);
                  },
                  cells: [
                    // TICKET
                    DataCell(
                      Text(
                        ticket.ticketNo,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1D24),
                        ),
                      ),
                    ),
                    // TYPE
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Appreciation',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                    // FROM
                    DataCell(
                      Text(
                        ticket.source.isNotEmpty
                            ? '${ticket.source[0].toUpperCase()}${ticket.source.substring(1)}'
                            : '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // STUDENT
                    DataCell(
                      Text(
                        (ticket.studentName != null && ticket.studentName!.isNotEmpty)
                            ? ticket.studentName!
                            : '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // ABOUT
                    DataCell(
                      Text(
                        (ticket.aboutUserName != null && ticket.aboutUserName!.isNotEmpty)
                            ? ticket.aboutUserName!
                            : ((ticket.aboutText != null && ticket.aboutText!.isNotEmpty)
                                ? ticket.aboutText!
                                : '—'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // CATEGORY
                    DataCell(
                      Text(
                        ticket.category.isNotEmpty ? ticket.category : '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    // STATUS
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(ticket.status, isDark),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatStatusLabel(ticket.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusTextColor(ticket.status, isDark),
                          ),
                        ),
                      ),
                    ),
                    // WITH
                    DataCell(
                      Text(
                        (ticket.ownerName != null && ticket.ownerName!.isNotEmpty)
                            ? ticket.ownerName!
                            : '—',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // RECEIVED
                    DataCell(
                      Text(
                        _formatSimpleDate(ticket.receivedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // TASK
                    DataCell(
                      ticket.taskNo != null && ticket.taskNo!.isNotEmpty
                          ? Text(
                              ticket.taskNo!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            )
                          : Text(
                              '—',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Mobile Cards List
  Widget _buildMobileCardsList(List<TicketItemModel> items, AppStrings s, bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            s.noTicketsFound,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.map((ticket) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openTicketDetails(ticket.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket.ticketNo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B1D24),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(ticket.status, isDark),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatStatusLabel(ticket.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusTextColor(ticket.status, isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (ticket.aboutUserName != null && ticket.aboutUserName!.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'About: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          ticket.aboutUserName!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (ticket.description.isNotEmpty) ...[
                    Text(
                      ticket.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ticket.category.isNotEmpty ? ticket.category : '—',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        _formatSimpleDate(ticket.receivedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openTicketDetails(int ticketId) {
    showDialog(
      context: context,
      builder: (ctx) => TicketDetailsDialog(ticketId: ticketId),
    ).then((_) {
      _fetchAppreciations();
    });
  }
}
