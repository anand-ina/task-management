import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/org_chart_bloc.dart';
import '../bloc/org_chart_event.dart';
import '../bloc/org_chart_state.dart';
import '../models/org_chart_model.dart';

class AdminOrgChartScreen extends StatelessWidget {
  const AdminOrgChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgChartBloc()..add(FetchOrgChartEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: const Scaffold(
          floatingActionButton: TodoFloatingActionButton(),
          drawer: CustomLeftDrawer(currentRoute: '/org-chart'),
          appBar: CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: _OrgChartBody(),
          ),
        ),
      ),
    );
  }
}

class _OrgChartBody extends StatelessWidget {
  const _OrgChartBody();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final authState = context.watch<AuthBloc>().state;
    String currentUserName = '';
    int currentUserId = 0;
    if (authState is AuthenticatedState) {
      currentUserName = authState.userProfile.name.toLowerCase();
      currentUserId = authState.userProfile.id;
    }

    return BlocBuilder<OrgChartBloc, OrgChartState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async => context.read<OrgChartBloc>().add(FetchOrgChartEvent()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Total People
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      s.adminOrgChart,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    if (state is OrgChartLoadedState) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.subtleBg(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.peopleCount(state.orgChart.total),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.adminOrgChartSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 12),

                // Legend row
                Row(
                  children: [
                    Container(width: 16, height: 2, color: isDark ? AppColors.white : AppColors.textSecondary(context)),
                    const SizedBox(width: 6),
                    Text(
                      s.primaryReportingLegend,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '- - - -',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.secondaryReportingLegend,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (state is OrgChartLoadingState)
                  Padding(
                    padding: const EdgeInsets.all(60),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is OrgChartErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message, style: TextStyle(color: AppColors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<OrgChartBloc>().add(FetchOrgChartEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  )
                else if (state is OrgChartLoadedState)
                  _buildOrgChartCard(
                    context,
                    s,
                    state.orgChart,
                    currentUserName,
                    currentUserId,
                    isDark,
                  )
                else
                  const SizedBox.shrink(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrgChartCard(
    BuildContext context,
    AppStrings s,
    OrgChartResponseModel orgChart,
    String currentUserName,
    int currentUserId,
    bool isDark,
  ) {
    if (orgChart.levels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            s.noOrgChartDataFound,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < orgChart.levels.length; i++) ...[
            _buildLevelRow(
              context,
              s,
              orgChart.levels[i],
              currentUserName,
              currentUserId,
              isDark,
            ),
            if (i < orgChart.levels.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(
                  height: 1,
                  color: AppColors.border(context),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelRow(
    BuildContext context,
    AppStrings s,
    OrgChartLevelModel levelModel,
    String currentUserName,
    int currentUserId,
    bool isDark,
  ) {
    Color labelColor = _getLevelColor(levelModel.level);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final levelHeader = SizedBox(
          width: isWide ? 170 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelModel.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                s.peopleCount(levelModel.people.length),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary(context),
                ),
              ),
              if (!isWide) const SizedBox(height: 12),
            ],
          ),
        );

        final peopleGrid = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: levelModel.people.map((person) {
            final isCurrent = (person.id != 0 && person.id == currentUserId) ||
                (currentUserName.isNotEmpty && person.name.toLowerCase().contains(currentUserName));
            return _buildPersonCard(context, s, person, isCurrent, isDark);
          }).toList(),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              levelHeader,
              Expanded(child: peopleGrid),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              levelHeader,
              peopleGrid,
            ],
          );
        }
      },
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    AppStrings s,
    OrgChartPersonModel person,
    bool isCurrent,
    bool isDark,
  ) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? AppColors.blue
              : AppColors.border(context),
          width: isCurrent ? 2.0 : 1.0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name + You Badge
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _hexToColor(person.avatarColor),
                child: Text(
                  person.initials,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            person.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.subtleBg(context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.youBadge,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      person.designation.isNotEmpty ? person.designation : person.roleLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Responsibility Tag
          if (person.responsibility != null && person.responsibility!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.subtleBg(context),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                person.responsibility!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Reports To Row
          if (person.managers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '↳ ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${s.reportsToPrefix} ',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Expanded(
                  child: Text(
                    person.managers.map((m) => m.toString()).join(', '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Dotted Row
          if (person.dotted.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⇢ ',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Text(
                  '${s.dottedPrefix} ',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                Expanded(
                  child: Text(
                    person.dotted.map((d) => d.toString()).join(', '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 5:
        return AppColors.blue;
      case 4:
        return AppColors.cyan;
      case 3:
        return AppColors.green;
      case 2:
        return AppColors.amber;
      case 1:
        return AppColors.slate500;
      default:
        return AppColors.slate600;
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return AppColors.primaryNavy;
    try {
      String h = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return AppColors.primaryNavy;
    }
  }
}
