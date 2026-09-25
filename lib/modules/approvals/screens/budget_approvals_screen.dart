import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/indent_detail_dialog.dart';
import '../../../shared_widgets/dialogs/new_budget_request_dialog.dart';
import '../../../shared_widgets/dialogs/raise_indent_dialog.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../models/indent_model.dart';
import '../models/budget_approval_model.dart';

class BudgetApprovalsScreen extends StatefulWidget {
  const BudgetApprovalsScreen({super.key});

  @override
  State<BudgetApprovalsScreen> createState() => _BudgetApprovalsScreenState();
}

class _BudgetApprovalsScreenState extends State<BudgetApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: To approve / Received, 1: My indents / Initiated, 2: All

  @override
  void initState() {
    super.initState();
    context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.of(context);

    final authState = context.watch<AuthBloc>().state;
    bool isAcademicExecutive = false;
    bool isDirector = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      if (role.contains('director') || roleLabel.contains('director')) {
        isDirector = true;
      }
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae')) {
        isAcademicExecutive = true;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          await ExitConfirmationDialog.show(context);
        }
      },
      child: Scaffold(
        floatingActionButton: const TodoFloatingActionButton(),
        drawer: const CustomLeftDrawer(currentRoute: '/approvals/budget'),
        appBar: const CustomAppBar(),
        body: AnnouncementBannerWrapper(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title with Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDirector ? s.budgetIndents : 'Requests & Approvals',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDirector
                                  ? s.budgetIndentsSubtitle
                                  : 'Requests you have raised — closures, change requests, meeting invites and budget spend.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (isDirector) {
                            RaiseIndentDialog.show(
                              context,
                              onCreated: () {
                                context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent());
                              },
                            );
                          } else {
                            NewBudgetRequestDialog.show(context);
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          isDirector ? '+ ${s.raiseIndent}' : '+ New budget request',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // Tabs for Director: [To approve, My indents, All] (underlined style as in Screenshot 3)
                if (isDirector) ...[
                  Row(
                    children: [
                      _buildUnderlineTab(
                        title: s.toApproveTab,
                        isSelected: _selectedTabIndex == 0,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                      const SizedBox(width: 24),
                      _buildUnderlineTab(
                        title: s.myIndentsTab,
                        isSelected: _selectedTabIndex == 1,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                      const SizedBox(width: 24),
                      _buildUnderlineTab(
                        title: s.allIndentsTab,
                        isSelected: _selectedTabIndex == 2,
                        onTap: () => setState(() => _selectedTabIndex = 2),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                ] else if (!isAcademicExecutive) ...[
                  // Segmented Pill Tabs for other roles
                  BlocBuilder<ApprovalsBloc, ApprovalsState>(
                    builder: (context, state) {
                      int receivedCount = 0;
                      int initiatedCount = 0;
                      if (state is ApprovalsLoadedState) {
                        receivedCount = state.budgetReceived.length;
                        initiatedCount = state.budgetInitiated.length;
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
                            _buildPillTabButton(
                              title: 'Received by Me ${receivedCount > 0 ? "($receivedCount)" : ""}',
                              isSelected: _selectedTabIndex == 0,
                              onTap: () => setState(() => _selectedTabIndex = 0),
                            ),
                            _buildPillTabButton(
                              title: 'Initiated by Me ${initiatedCount > 0 ? "($initiatedCount)" : ""}',
                              isSelected: _selectedTabIndex == 1,
                              onTap: () => setState(() => _selectedTabIndex = 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Content Body
                BlocBuilder<ApprovalsBloc, ApprovalsState>(
                  builder: (context, state) {
                    if (state is ApprovalsLoadingState) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
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
                                    .add(FetchBudgetApprovalsDataEvent()),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is ApprovalsLoadedState) {
                      if (isDirector) {
                        // Director indents display
                        List<IndentItemModel> indentsList = [];
                        if (_selectedTabIndex == 0) {
                          indentsList = state.indentsInbox;
                        } else if (_selectedTabIndex == 1) {
                          // My indents (fallback to indentsInbox filtered or empty)
                          indentsList = [];
                        } else {
                          // All indents
                          indentsList = state.indentsAll;
                        }

                        if (indentsList.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: indentsList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildIndentCard(indentsList[index]);
                          },
                        );
                      }

                      // Non-director budget approval list
                      final items = isAcademicExecutive
                          ? [...state.budgetReceived, ...state.budgetInitiated]
                          : (_selectedTabIndex == 0
                              ? state.budgetReceived
                              : state.budgetInitiated);

                      if (items.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildBudgetCard(items[index], isDirector: isDirector);
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
      ),),
    );
  }

  Widget _buildUnderlineTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFDC2626) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildPillTabButton({
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
            Icon(Icons.currency_rupee_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No budget items found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCreatedDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '24 Aug, 15:44';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatNeededDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '27 Aug 26';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  // Indent Card matching Screenshot 3
  Widget _buildIndentCard(IndentItemModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isApproved = item.status.toLowerCase() == 'approved';

    return InkWell(
      onTap: () {
        IndentDetailDialog.show(context, indentId: item.id, initialIndent: item);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left green highlight indicator
              Container(
                width: 4,
                color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: [IND-2026-0001] [Approved] badge  ...  Amount (₹11,000)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.indentNo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.status.capitalize(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₹${item.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Purpose
                      if (item.purpose != null && item.purpose!.isNotEmpty) ...[
                        Text(
                          item.purpose!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Meta: by Swapnika · Admission Counselling · 24 Sept, 13:49
                      Text(
                        'by ${item.raisedBy ?? "Swapnika"} · ${item.departmentName ?? "Admission Counselling"} · ${_formatCreatedDate(item.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Voucher VCH-2026-0001 ready
                      if (item.voucherNo != null && item.voucherNo!.isNotEmpty)
                        Text(
                          'Voucher ${item.voucherNo} ready',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
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

  Widget _buildBudgetCard(BudgetApprovalModel item, {required bool isDirector}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isApproved = item.status.toLowerCase() == 'approved';
    final isRejected = item.status.toLowerCase() == 'rejected';

    final currencyStr = item.currency.isNotEmpty ? item.currency : 'INR';
    final amountStr = item.amount != null ? item.amount!.toStringAsFixed(2) : '0.00';
    final categoryStr = (item.category != null && item.category!.isNotEmpty) ? item.category! : 'General';
    final titleStr = (item.title != null && item.title!.isNotEmpty) ? item.title! : 'test';
    final requestedByStr = (item.requestedBy != null && item.requestedBy!.isNotEmpty) ? item.requestedBy! : 'Test_Manager';
    final createdStr = _formatCreatedDate(item.createdAt);
    final neededStr = _formatNeededDate(item.neededBy);
    final justificationStr = (item.justification != null && item.justification!.isNotEmpty) ? item.justification! : (item.note ?? '');

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
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Currency & Amount
          Text(
            '$currencyStr $amountStr',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // 2. Category
          Text(
            categoryStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isApproved
                  ? const Color(0xFFDCFCE7)
                  : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF9C3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.status.toLowerCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isApproved
                    ? const Color(0xFF15803D)
                    : (isRejected ? const Color(0xFF991B1B) : const Color(0xFFA16207)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Meta line
          Text(
            '$titleStr · raised by $requestedByStr · $createdStr · needed by $neededStr',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),

          // 5. Justification line
          if (justificationStr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              justificationStr,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[300] : const Color(0xFF475569),
              ),
            ),
          ],

          // 6. Action buttons
          if (isDirector && !isApproved && !isRejected && _selectedTabIndex == 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    context.read<ApprovalsBloc>().add(
                          DecideBudgetEvent(id: item.id, decision: 'approve'),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget approved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    'Approve',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    context.read<ApprovalsBloc>().add(
                          DecideBudgetEvent(id: item.id, decision: 'reject'),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget request rejected.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),

    );
  }
}
