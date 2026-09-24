import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models/fine_item_model.dart';
import '../repository/fines_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/dialogs/issue_fine_reward_dialog.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/fines_bloc.dart';
import '../bloc/fines_event.dart';
import '../bloc/fines_state.dart';

class FinesRewardsScreen extends StatefulWidget {
  const FinesRewardsScreen({super.key});

  @override
  State<FinesRewardsScreen> createState() => _FinesRewardsScreenState();
}

class _FinesRewardsScreenState extends State<FinesRewardsScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    bool isAcademicExecutive = false;
    bool isTeamLead = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      if (role.contains('executive') || role.contains('ae') || roleLabel.contains('executive') || roleLabel.contains('ae')) {
        isAcademicExecutive = true;
      }
      if (role.contains('team lead') ||
          role.contains('team_lead') ||
          role.contains('team leader') ||
          role.contains('team_leader') ||
          role.contains('tl') ||
          roleLabel.contains('team lead') ||
          roleLabel.contains('team_lead') ||
          roleLabel.contains('team leader') ||
          roleLabel.contains('team_leader') ||
          roleLabel.contains('tl')) {
        isTeamLead = true;
      }
    }

    return BlocProvider(
      create: (context) => FinesBloc()..add(FetchFinesEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: Scaffold(
          floatingActionButton: const TodoFloatingActionButton(),
          drawer: const CustomLeftDrawer(currentRoute: '/fines-rewards'),
          appBar: const CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: BlocBuilder<FinesBloc, FinesState>(
            builder: (context, state) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FinesBloc>().add(FetchFinesEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.finesRewardsTitle,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.finesRewardsSubtitle,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                          if (!isAcademicExecutive && !isTeamLead)
                            ElevatedButton(
                              onPressed: () => IssueFineRewardDialog.show(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.button(context),
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('+ Issue Fine / Reward', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Segmented Tabs Header (Overview, Summary, Audit Trail)
                      Row(
                        children: [
                          _buildTabButton(0, s.overviewTab),
                          const SizedBox(width: 24),
                          _buildTabButton(1, s.summaryTab),
                          const SizedBox(width: 24),
                          _buildTabButton(2, s.auditTrailTab),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (state is FinesLoadingState)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state is FinesErrorState)
                        Center(
                          child: Column(
                            children: [
                              Text(state.message, style: const TextStyle(color: AppColors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<FinesBloc>().add(FetchFinesEvent()),
                                child: Text(s.retryButton),
                              ),
                            ],
                          ),
                        )
                      else if (state is FinesLoadedState) ...[
                        if (_selectedTabIndex == 0) ...[
                          // Policy Cards Grid
                          _buildPolicyGrid(context, s, state.data),
                          const SizedBox(height: 24),

                          // Samskar Merchandise Store Section
                          _buildMerchandiseStore(context, s, state.data.me.points),
                          const SizedBox(height: 24),

                          // Fines & Rewards History List (Container Cards)
                          _buildFinesHistoryList(context, s, state.data.fines, isDark),
                        ] else if (_selectedTabIndex == 1) ...[
                          _buildSummaryTab(context, s, state.data, isDark),
                        ] else ...[
                          _buildAuditTrailTab(context, s, state.data.fines, isDark),
                        ],
                      ] else
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
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.textPrimary(context)
                  : AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 50,
            color: isSelected ? AppColors.red700 : AppColors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyGrid(BuildContext context, AppStrings s, FinesOverviewData data) {
    final policies = data.fineTypes.isNotEmpty
        ? data.fineTypes
            .map((ft) => {
                  'title': ft.label,
                  'amount': '₹${ft.amount}',
                  'isFine': ft.kind.toLowerCase() == 'fine',
                })
            .toList()
        : [
            {'title': 'Late task closure', 'amount': '₹50.00', 'isFine': true},
            {'title': 'Missed DSR', 'amount': '₹25.00', 'isFine': true},
            {'title': 'Overdue > 3 days', 'amount': '₹100.00', 'isFine': true},
            {'title': 'Early completion', 'amount': '₹50.00', 'isFine': false},
            {'title': 'Top performer', 'amount': '₹150.00', 'isFine': false},
            {'title': 'Zero overdue (month)', 'amount': '₹200.00', 'isFine': false},
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 75,
          ),
          itemCount: policies.length,
          itemBuilder: (context, index) {
            final p = policies[index];
            final isFine = p['isFine'] as bool;
            final accentColor = isFine ? AppColors.red600 : AppColors.green600;

            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      color: accentColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p['title'] as String,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p['amount'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.subtleBg(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isFine ? 'Fine' : 'Reward',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildMerchandiseStore(BuildContext context, AppStrings s, int userPoints) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final storeItems = [
      {'title': 'Samskar Pen', 'pts': '100 pts', 'icon': Icons.edit_rounded},
      {'title': 'Coffee Mug', 'pts': '200 pts', 'icon': Icons.local_cafe_rounded},
      {'title': 'Diary', 'pts': '250 pts', 'icon': Icons.menu_book_rounded},
      {'title': 'Lunch Box', 'pts': '300 pts', 'icon': Icons.takeout_dining_rounded},
      {'title': 'Pen Stand', 'pts': '200 pts', 'icon': Icons.dashboard_rounded},
      {'title': 'Headphones', 'pts': '800 pts', 'icon': Icons.headphones_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.samskarMerchandiseStoreHeader,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey, letterSpacing: 1.1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.green900 : AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+ $userPoints points available',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.green300 : AppColors.green700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 60,
                ),
                itemCount: storeItems.length,
                itemBuilder: (context, index) {
                  final item = storeItems[index];

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.subtleBg(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData, size: 22, color: AppColors.textSecondary(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              Text(
                                item['pts'] as String,
                                style: TextStyle(fontSize: 10, color: AppColors.textMuted(context)),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(s.redeemButton, style: const TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinesHistoryList(BuildContext context, AppStrings s, List<FineItemModel> fines, bool isDark) {
    if (fines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(s.noFinesOrRewardsYet, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${s.history} (${fines.length})',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fines.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = fines[index];
            final isReward = item.type.toLowerCase() == 'reward';
            final accentColor = isReward ? AppColors.green600 : AppColors.red600;
            final bgBadgeColor = isReward
                ? (isDark ? AppColors.green900 : AppColors.greenLight)
                : (isDark ? AppColors.red900 : AppColors.redLight);

            String formattedDate = item.createdAt;
            try {
              final dt = DateTime.parse(item.createdAt).toLocal();
              formattedDate = DateFormat('d MMM yyyy, hh:mm a').format(dt);
            } catch (_) {}

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bgBadgeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isReward ? Icons.military_tech_rounded : Icons.gavel_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                (item.reason != null && item.reason!.isNotEmpty)
                                    ? item.reason!
                                    : (item.label.isNotEmpty ? item.label : (isReward ? s.rewardLabel : s.fineLabel)),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${isReward ? "+" : "-"}₹${item.amount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.member.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.member,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            if (item.issuedBy != null && item.issuedBy!.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_outlined, size: 13, color: AppColors.textSecondary(context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${s.issuedByLabel}: ${item.issuedBy}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            if (item.taskNo != null || item.taskId != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.subtleBg(context),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.border(context)),
                                ),
                                child: Text(
                                  item.taskNo ?? '#${item.taskId}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted(context)),
                                const SizedBox(width: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted(context)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryTab(BuildContext context, AppStrings s, FinesOverviewData data, bool isDark) {
    double totalRewards = 0;
    double totalFines = 0;
    for (final f in data.fines) {
      final amt = double.tryParse(f.amount) ?? 0.0;
      if (f.type.toLowerCase() == 'reward') {
        totalRewards += amt;
      } else {
        totalFines += amt;
      }
    }
    final net = totalRewards - totalFines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatMetricCard(
              title: s.rewardLabel,
              amount: '+₹${totalRewards.toStringAsFixed(2)}',
              accentColor: AppColors.green600,
              isDark: isDark,
            ),
            _buildStatMetricCard(
              title: s.fineLabel,
              amount: '-₹${totalFines.toStringAsFixed(2)}',
              accentColor: AppColors.red600,
              isDark: isDark,
            ),
            _buildStatMetricCard(
              title: 'Net Balance',
              amount: '₹${net.toStringAsFixed(2)}',
              accentColor: net >= 0 ? AppColors.green600 : AppColors.red600,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildFinesHistoryList(context, s, data.fines, isDark),
      ],
    );
  }

  Widget _buildStatMetricCard({
    required String title,
    required String amount,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailTab(BuildContext context, AppStrings s, List<FineItemModel> fines, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.auditTrailTab,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 12),
        _buildFinesHistoryList(context, s, fines, isDark),
      ],
    );
  }
}
