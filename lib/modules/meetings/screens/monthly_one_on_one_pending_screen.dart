import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/schedule_one_on_one_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/meetings_bloc.dart';
import '../bloc/meetings_event.dart';
import '../bloc/meetings_state.dart';
import '../models/one_on_one_pending_model.dart';

class MonthlyOneOnOnePendingScreen extends StatefulWidget {
  const MonthlyOneOnOnePendingScreen({super.key});

  @override
  State<MonthlyOneOnOnePendingScreen> createState() => _MonthlyOneOnOnePendingScreenState();
}

class _MonthlyOneOnOnePendingScreenState extends State<MonthlyOneOnOnePendingScreen> {
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => MeetingsBloc()..add(FetchOneOnOnePendingEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/one-on-one-pending'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<MeetingsBloc, MeetingsState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row Title & Schedule 1:1 Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Monthly 1:1 Pending',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.staffWhoHaventCompletedMandatory,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => ScheduleOneOnOneDialog.show(context),
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: Text(s.scheduleOneOnOne, style: const TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // State Handling
                    if (state is MeetingsLoadingState)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                      )
                    else if (state is MeetingsErrorState)
                      Center(
                        child: Column(
                          children: [
                            Text(state.message, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                context.read<MeetingsBloc>().add(FetchOneOnOnePendingEvent());
                              },
                              child: Text(s.retryButton),
                            ),
                          ],
                        ),
                      )
                    else if (state is OneOnOnePendingLoadedState)
                      _buildPendingContainerList(context, s, state.pendingList)
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Single Styled Container List of Staff Members
  Widget _buildPendingContainerList(BuildContext context, AppStrings s, List<OneOnOnePendingModel> pendingList) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (pendingList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('All staff 1:1 meetings are completed!', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pendingList.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
        ),
        itemBuilder: (context, index) {
          final item = pendingList[index];
          return InkWell(
            onTap: () => ScheduleOneOnOneDialog.show(context, staffName: item.name),
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? const Radius.circular(12) : Radius.zero,
              bottom: index == pendingList.length - 1 ? const Radius.circular(12) : Radius.zero,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Staff Name
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Role Label Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.roleLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 1:1 Pending Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      s.oneOnOnePendingBadge,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
