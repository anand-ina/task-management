import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/fines_bloc.dart';
import '../bloc/fines_event.dart';
import '../bloc/fines_state.dart';

class PerformanceSettingsScreen extends StatelessWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => FinesBloc()..add(FetchFineTypesEvent()),
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
          drawer: const CustomLeftDrawer(currentRoute: '/performance-settings'),
          appBar: const CustomAppBar(),
          body: BlocBuilder<FinesBloc, FinesState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FinesBloc>().add(FetchFineTypesEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Text(
                            s.performanceSettingsTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              s.directorOnlyBadge,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.performanceSettingsSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (state is FinesLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
                        )
                      else if (state is FinesErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<FinesBloc>().add(FetchFineTypesEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Side-by-Side Card Sections
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;

                            final fineCard = _buildPolicyCard(
                              context,
                              s,
                              title: s.finePolicyHeader,
                              colHeader: '₹ AMOUNT',
                              items: [
                                {'label': 'Late task closure', 'amount': '50.00'},
                                {'label': 'Missed DSR', 'amount': '25.00'},
                                {'label': 'Overdue > 3 days', 'amount': '100.00'},
                              ],
                              addButtonText: s.addFineTypeButton,
                            );

                            final rewardCard = _buildPolicyCard(
                              context,
                              s,
                              title: s.rewardPolicyHeader,
                              colHeader: 'POINTS',
                              items: [
                                {'label': 'Early completion', 'amount': '50.00'},
                                {'label': 'Top performer', 'amount': '150.00'},
                                {'label': 'Zero overdue (month)', 'amount': '200.00'},
                              ],
                              addButtonText: s.addRewardTypeButton,
                            );

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: fineCard),
                                  const SizedBox(width: 16),
                                  Expanded(child: rewardCard),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  fineCard,
                                  const SizedBox(height: 16),
                                  rewardCard,
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bottom Action Buttons
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(s.saveSettingsButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(s.resetToDefaultsButton),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildPolicyCard(
    BuildContext context,
    AppStrings s, {
    required String title,
    required String colHeader,
    required List<Map<String, String>> items,
    required String addButtonText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),

          // Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              Text(colHeader, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
            ],
          ),
          const Divider(height: 16),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final row = items[index];

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row['label']!,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  SizedBox(
                    width: 100,
                    height: 36,
                    child: TextField(
                      controller: TextEditingController(text: row['amount']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Add Type Button
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 14),
            label: Text(addButtonText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
