import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/approvals/bloc/approvals_bloc.dart';
import '../../../modules/approvals/bloc/approvals_event.dart';
import '../../../modules/approvals/bloc/approvals_state.dart';
import '../../../modules/approvals/models/organisation_approval_model.dart';
import '../animations/app_animations.dart';
import 'task_detail_dialog.dart';

class OrganisationApprovalsDialog extends StatefulWidget {
  const OrganisationApprovalsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showSmoothDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const OrganisationApprovalsDialog(),
    );
  }

  @override
  State<OrganisationApprovalsDialog> createState() => _OrganisationApprovalsDialogState();
}

class _OrganisationApprovalsDialogState extends State<OrganisationApprovalsDialog> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedBranchId; // null means 'All Branches'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApprovalsBloc>().add(FetchOrganisationApprovalsEvent());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getPriorityBgColor(String? priority) {
    final p = priority?.toLowerCase() ?? '';
    if (p.contains('emergency')) return const Color(0xFFFEE2E2);
    if (p.contains('top')) return const Color(0xFFFFEDD5);
    if (p.contains('high')) return const Color(0xFFFEF3C7);
    if (p.contains('medium')) return const Color(0xFFDBEAFE);
    return const Color(0xFFF1F5F9);
  }

  Color _getPriorityTextColor(String? priority) {
    final p = priority?.toLowerCase() ?? '';
    if (p.contains('emergency')) return const Color(0xFFDC2626);
    if (p.contains('top')) return const Color(0xFFEA580C);
    if (p.contains('high')) return const Color(0xFFD97706);
    if (p.contains('medium')) return const Color(0xFF2563EB);
    return const Color(0xFF64748B);
  }

  String _formatPriorityLabel(String? priority, AppStrings s) {
    final p = priority?.toLowerCase() ?? '';
    if (p.contains('emergency')) return s.emergencyPriority;
    if (p.contains('top')) return s.topMostPriority;
    if (p.contains('high')) return s.highPriority;
    if (p.contains('medium')) return s.mediumPriority;
    if (p.contains('low')) return s.lowPriority;
    return priority ?? '';
  }

  void _onOpenTaskDetail(BuildContext context, int? taskId) {
    if (taskId == null || taskId <= 0) return;
    TaskDetailDialog.show(
      context,
      taskId: taskId,
      showOnlyCloneAndCancel: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 720;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 12,
        vertical: isTablet ? 24 : 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 980,
          maxHeight: size.height * 0.92,
        ),
        padding: EdgeInsets.all(isTablet ? 22 : 14),
        child: BlocBuilder<ApprovalsBloc, ApprovalsState>(
          builder: (context, state) {
            final isLoading = state is ApprovalsLoadingState;
            final isError = state is ApprovalsErrorState;
            final items = state is ApprovalsLoadedState ? state.organisationApprovals : <OrganisationApprovalModel>[];

            // Compute branch list and counts
            final Map<int, Map<String, dynamic>> branchCounts = {};
            for (final item in items) {
              final bId = item.branchId ?? 0;
              if (!branchCounts.containsKey(bId)) {
                branchCounts[bId] = {
                  'id': bId,
                  'name': item.branchName ?? 'Branch',
                  'code': item.branchCode ?? '',
                  'count': 0,
                };
              }
              branchCounts[bId]!['count'] = (branchCounts[bId]!['count'] as int) + 1;
            }

            // Filter items
            final filteredItems = items.where((item) {
              if (_selectedBranchId != null && item.branchId != _selectedBranchId) {
                return false;
              }
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final matchNo = item.taskNo?.toLowerCase().contains(query) ?? false;
                final matchTitle = item.title?.toLowerCase().contains(query) ?? false;
                final matchReq = item.requestedBy?.toLowerCase().contains(query) ?? false;
                final matchAppr = item.approverName?.toLowerCase().contains(query) ?? false;
                final matchNote = item.note?.toLowerCase().contains(query) ?? false;
                if (!matchNo && !matchTitle && !matchReq && !matchAppr && !matchNote) {
                  return false;
                }
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header Row
                _buildHeader(context, s, isDark, items.length),
                const SizedBox(height: 16),

                // 2. Branch Filter Section
                _buildBranchFilters(s, isDark, items.length, branchCounts),
                const SizedBox(height: 14),

                // 3. Search and Counter Row
                _buildSearchAndCounterRow(s, isDark, filteredItems.length, items.length),
                const SizedBox(height: 12),

                // 4. Content Area
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : isError
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text((state as ApprovalsErrorState).message),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<ApprovalsBloc>().add(FetchOrganisationApprovalsEvent());
                                    },
                                    child: Text(s.retryButton),
                                  ),
                                ],
                              ),
                            )
                          : filteredItems.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.assignment_turned_in_outlined,
                                          size: 48,
                                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          s.noApprovalsFound,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : isTablet
                                  ? _buildTableView(context, s, isDark, filteredItems)
                                  : _buildMobileCardsView(context, s, isDark, filteredItems),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 5. Footer Row
                _buildFooter(context, s, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s, bool isDark, int totalCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.layers_rounded,
            color: Color(0xFF0F766E),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      s.approvalsFromOrganisationTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                s.approvalsFromOrganisationSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.close,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchFilters(
    AppStrings s,
    bool isDark,
    int totalCount,
    Map<int, Map<String, dynamic>> branchCounts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.place_outlined,
              size: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              s.filterByBranch,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // All Branches chip
              _buildBranchChip(
                label: s.allBranchesCount(totalCount),
                count: null,
                code: null,
                isSelected: _selectedBranchId == null,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedBranchId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              // Branch specific chips
              ...branchCounts.values.map((branch) {
                final bId = branch['id'] as int;
                final bName = branch['name'] as String;
                final bCode = branch['code'] as String;
                final bCount = branch['count'] as int;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildBranchChip(
                    label: bName,
                    count: bCount,
                    code: bCode,
                    isSelected: _selectedBranchId == bId,
                    isDark: isDark,
                    onTap: () {
                      setState(() {
                        _selectedBranchId = bId;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBranchChip({
    required String label,
    required int? count,
    required String? code,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F766E).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E))
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E))
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
            if (code != null && code.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndCounterRow(
    AppStrings s,
    bool isDark,
    int filteredCount,
    int totalCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: s.searchByTaskIdTitleRequester,
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: Icon(
                      Icons.clear,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          s.showingRequestsCount(filteredCount, totalCount),
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTableView(
    BuildContext context,
    AppStrings s,
    bool isDark,
    List<OrganisationApprovalModel> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    s.taskIdHeader,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    s.taskTitleHeader,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    s.branchHeader,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    s.tasksByPriority,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    s.requestedByHeader,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    s.designatedApproverHeader,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Text(
                    s.requestedOnHeader,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    s.actionHeader,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows List
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => _onOpenTaskDetail(context, item.taskId),
                  hoverColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text(
                            item.taskNo ?? '—',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title ?? '—',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (item.note != null && item.note!.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Text('💬 ', style: TextStyle(fontSize: 10)),
                                    Flexible(
                                      child: Text(
                                        '"${item.note}"',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.branchCode ?? '—',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getPriorityBgColor(item.priority),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatPriorityLabel(item.priority, s),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _getPriorityTextColor(item.priority),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 13,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.requestedBy ?? '—',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            item.approverName ?? '—',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: Text(
                            item.formattedRequestedOn,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: OutlinedButton(
                              onPressed: () => _onOpenTaskDetail(context, item.taskId),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                s.viewAction,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardsView(
    BuildContext context,
    AppStrings s,
    bool isDark,
    List<OrganisationApprovalModel> items,
  ) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _onOpenTaskDetail(context, item.taskId),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${index + 1} ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          item.taskNo ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (item.branchCode != null && item.branchCode!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.branchCode!,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPriorityBgColor(item.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatPriorityLabel(item.priority, s),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityTextColor(item.priority),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (item.note != null && item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '💬 "${item.note}"',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.requestedByHeader}: ${item.requestedBy ?? "—"}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                          Text(
                            '${s.designatedApproverHeader}: ${item.approverName ?? "—"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.formattedRequestedOn,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _onOpenTaskDetail(context, item.taskId),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Text(
                        s.viewAction,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, AppStrings s, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            s.clickAnyTaskRowToView,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide(
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
          ),
          child: Text(
            s.closeButton,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
