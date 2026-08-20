import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../constants/approvals_const_strings.dart';
import '../models/task_approval_model.dart';

class TaskApprovalsScreen extends StatefulWidget {
  const TaskApprovalsScreen({super.key});

  @override
  State<TaskApprovalsScreen> createState() => _TaskApprovalsScreenState();
}

class _TaskApprovalsScreenState extends State<TaskApprovalsScreen> {
  int _selectedTabIndex = 0; // 0: Received by Me, 1: Initiated by Me

  @override
  void initState() {
    super.initState();
    context.read<ApprovalsBloc>().add(FetchTaskApprovalsDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const CustomLeftDrawer(currentRoute: '/approvals/tasks'),
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ApprovalsBloc>().add(FetchTaskApprovalsDataEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Awaiting Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    ApprovalsConstStrings.approvalsHeader,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  BlocBuilder<ApprovalsBloc, ApprovalsState>(
                    builder: (context, state) {
                      int awaitingCount = 0;
                      if (state is ApprovalsLoadedState) {
                        awaitingCount = state.taskApprovalsReceived
                            .where((e) => e.status.toLowerCase() == 'pending')
                            .length;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$awaitingCount ${ApprovalsConstStrings.awaitingYou}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ApprovalsConstStrings.approvalsSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Pill Tabs
              BlocBuilder<ApprovalsBloc, ApprovalsState>(
                builder: (context, state) {
                  int receivedCount = 0;
                  int initiatedCount = 0;
                  if (state is ApprovalsLoadedState) {
                    receivedCount = state.taskApprovalsReceived.length;
                    initiatedCount = state.taskApprovalsInitiated.length;
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
                          title: '${ApprovalsConstStrings.receivedByMe} ${receivedCount > 0 ? "($receivedCount)" : "0"}',
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
                                  .add(FetchTaskApprovalsDataEvent()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ApprovalsLoadedState) {
                    final items = _selectedTabIndex == 0
                        ? state.taskApprovalsReceived
                        : state.taskApprovalsInitiated;

                    if (items.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildTaskApprovalCard(items[index]);
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
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              ApprovalsConstStrings.noTaskApprovals,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskApprovalCard(TaskApprovalModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighPriority = (item.priority ?? '').toLowerCase() == 'high';

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
              // Left Accent Strip
              Container(
                width: 4,
                color: isHighPriority ? const Color(0xFFF97316) : const Color(0xFF3B82F6),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges Row
                      Row(
                        children: [
                          if (item.taskNo != null) ...[
                            Text(
                              item.taskNo!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (item.priority != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF08A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.priority!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF854D0E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Closure',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title & Metadata
                      if (item.title != null)
                        Text(
                          item.title!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      if (item.requestedBy != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'requested by ${item.requestedBy}${item.createdAt != null ? " · ${_formatDate(item.createdAt!)}" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600,
                          ),
                        ),
                      ],

                      // Note Box
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              ApprovalsConstStrings.approveClosure,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              ApprovalsConstStrings.reject,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
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

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day} ${_monthName(dt.month)}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
