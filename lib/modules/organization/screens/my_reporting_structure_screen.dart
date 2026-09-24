import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../bloc/my_reporting_bloc.dart';
import '../bloc/my_reporting_event.dart';
import '../bloc/my_reporting_state.dart';
import '../models/my_reporting_model.dart';

class MyReportingStructureScreen extends StatelessWidget {
  const MyReportingStructureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyReportingBloc()..add(FetchMyReportingEvent()),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (!didPop) await ExitConfirmationDialog.show(context);
        },
        child: const Scaffold(
          floatingActionButton: TodoFloatingActionButton(),
          drawer: CustomLeftDrawer(currentRoute: '/my-reporting'),
          appBar: CustomAppBar(),
          body: AnnouncementBannerWrapper(
            child: _MyReportingBody(),
          ),
        ),
      ),
    );
  }
}

class _MyReportingBody extends StatelessWidget {
  const _MyReportingBody();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<MyReportingBloc, MyReportingState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async => context.read<MyReportingBloc>().add(FetchMyReportingEvent()),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Subtitle
                Text(
                  s.myReportingStructure,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.myReportingSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 24),

                if (state is MyReportingLoadingState)
                  Padding(
                    padding: const EdgeInsets.all(60),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is MyReportingErrorState)
                  Center(
                    child: Column(
                      children: [
                        Text(state.message, style: TextStyle(color: AppColors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => context.read<MyReportingBloc>().add(FetchMyReportingEvent()),
                          child: Text(s.retryButton),
                        ),
                      ],
                    ),
                  )
                else if (state is MyReportingLoadedState) ...[
                  // Section: Me
                  if (state.data.me != null) ...[
                    _buildSectionHeader(context, s.meSectionTitle, isDark),
                    const SizedBox(height: 10),
                    _buildPersonCard(
                      context: context,
                      person: state.data.me!,
                      isMe: true,
                      isDark: isDark,
                      s: s,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Section: I report to
                  _buildSectionHeader(
                    context,
                    s.iReportToSectionTitle,
                    isDark,
                    tag: s.primarySolidLegend,
                  ),
                  const SizedBox(height: 10),
                  if (state.data.managers.isEmpty && state.data.dotted.isEmpty)
                    _buildEmptyText(s.noneText, isDark)
                  else ...[
                    if (state.data.managers.isNotEmpty)
                      Column(
                        children: state.data.managers
                            .map((m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildPersonCard(
                                    context: context,
                                    person: m,
                                    isMe: false,
                                    isDark: isDark,
                                    s: s,
                                  ),
                                ))
                            .toList(),
                      ),
                    if (state.data.dotted.isNotEmpty) ...[
                      if (state.data.managers.isNotEmpty) const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          s.secondaryDottedLegend,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context)),
                        ),
                      ),
                      Column(
                        children: state.data.dotted
                            .map((m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildPersonCard(
                                    context: context,
                                    person: m,
                                    isMe: false,
                                    isDark: isDark,
                                    s: s,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),

                  // Section: Reports to me
                  _buildSectionHeader(
                    context,
                    s.reportsToMeSectionTitle,
                    isDark,
                    countBadge: state.data.reports.length + state.data.dottedReports.length,
                  ),
                  const SizedBox(height: 10),
                  if (state.data.reports.isEmpty && state.data.dottedReports.isEmpty)
                    _buildEmptyText(s.noneText, isDark)
                  else ...[
                    if (state.data.reports.isNotEmpty)
                      Column(
                        children: state.data.reports
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildPersonCard(
                                    context: context,
                                    person: r,
                                    isMe: false,
                                    isDark: isDark,
                                    s: s,
                                  ),
                                ))
                            .toList(),
                      ),
                    if (state.data.dottedReports.isNotEmpty) ...[
                      if (state.data.reports.isNotEmpty) const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          s.secondaryDottedLegend,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary(context)),
                        ),
                      ),
                      Column(
                        children: state.data.dottedReports
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildPersonCard(
                                    context: context,
                                    person: r,
                                    isMe: false,
                                    isDark: isDark,
                                    s: s,
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 28),

                  // Section: Peers
                  _buildSectionHeader(
                    context,
                    s.peersSectionTitle,
                    isDark,
                    tag: s.shareManagerSubtitle,
                  ),
                  const SizedBox(height: 10),
                  if (state.data.peers.isEmpty)
                    _buildEmptyText(s.noneText, isDark)
                  else
                    Column(
                      children: state.data.peers
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildPersonCard(
                                  context: context,
                                  person: p,
                                  isMe: false,
                                  isDark: isDark,
                                  s: s,
                                ),
                              ))
                          .toList(),
                    ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDark, {
    String? tag,
    int? countBadge,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(context),
          ),
        ),
        if (countBadge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.subtleBg(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$countBadge',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
        ],
        if (tag != null) ...[
          const SizedBox(width: 8),
          Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPersonCard({
    required BuildContext context,
    required MyReportingPersonModel person,
    required bool isMe,
    required bool isDark,
    required AppStrings s,
  }) {
    String subtitle = person.designation;
    if (person.responsibility != null && person.responsibility!.isNotEmpty) {
      subtitle = '$subtitle · ${person.responsibility}';
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border(context),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _hexToColor(person.avatarColor),
            child: Text(
              person.initials,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
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
                        person.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.subtleBorder(context),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }

  Widget _buildEmptyText(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey,
        ),
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return AppColors.navyDark;
    try {
      String h = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (h.length == 6) h = 'FF$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return AppColors.navyDark;
    }
  }
}
