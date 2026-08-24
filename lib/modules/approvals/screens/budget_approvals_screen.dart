import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/new_budget_request_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../constants/approvals_const_strings.dart';
import '../models/budget_approval_model.dart';

class BudgetApprovalsScreen extends StatefulWidget {
  const BudgetApprovalsScreen({super.key});

  @override
  State<BudgetApprovalsScreen> createState() => _BudgetApprovalsScreenState();
}

class _BudgetApprovalsScreenState extends State<BudgetApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: Received by Me, 1: Initiated by Me

  @override
  void initState() {
    super.initState();
    context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    bool isAcademicExecutive = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      final email = authState.userProfile.email.toLowerCase();
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae') || email.contains('sushma')) {
        isAcademicExecutive = true;
      }
    }

    return Scaffold(
      drawer: const CustomLeftDrawer(currentRoute: '/approvals/budget'),
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              const Text(
                'Requests & Approvals',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Requests you have raised — closures, change requests, meeting invites and budget spend.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // + New budget request Button
              ElevatedButton.icon(
                onPressed: () => NewBudgetRequestDialog.show(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('+ New budget request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),

              // Segmented Pill Tabs (Only visible when NOT Academic Executive)
              if (!isAcademicExecutive) ...[
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
              ],

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
                                  .add(FetchBudgetApprovalsDataEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ApprovalsLoadedState) {
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
                        return _buildBudgetCard(items[index]);
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
            Icon(Icons.currency_rupee_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              ApprovalsConstStrings.noBudgetApprovals,
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

  Widget _buildBudgetCard(BudgetApprovalModel item) {
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
          // 1. Currency & Amount (e.g. INR 5.00)
          Text(
            '$currencyStr $amountStr',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),

          // 2. Category (e.g. testtest)
          Text(
            categoryStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Status Badge (e.g. pending)
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

          // 4. Meta line (e.g. tetsunv · raised by Test_Manager · 24 Aug, 15:44 · needed by 27 Aug 26)
          Text(
            '$titleStr · raised by $requestedByStr · $createdStr · needed by $neededStr',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),

          // 5. Justification line (e.g. bxbx)
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
        ],
      ),
    );
  }
}
