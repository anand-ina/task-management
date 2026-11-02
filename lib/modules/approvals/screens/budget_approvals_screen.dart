import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared_widgets/animations/app_animations.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/indent_detail_dialog.dart';
import '../../../shared_widgets/dialogs/raise_indent_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/models/user_profile.dart';
import '../bloc/approvals_bloc.dart';
import '../bloc/approvals_event.dart';
import '../bloc/approvals_state.dart';
import '../constants/approvals_const_strings.dart';
import '../models/indent_model.dart';
import '../utils/indent_flow_helper.dart';
import '../utils/indent_ui.dart';

enum _IndentTab { all, inbox, mine, approved, rejected }

/// Budget Indents — mirrors dev-task.srivyn.in/budget for every role:
///  * All requests (Director / Center Head / Finance Manager / Manager only) → /indents/all
///  * To approve → /indents/inbox
///  * My indents → /indents/mine
///  * Approved / Rejected → filtered from the "all" bucket (/indents/all or /indents/mine)
class BudgetApprovalsScreen extends StatefulWidget {
  const BudgetApprovalsScreen({super.key});

  @override
  State<BudgetApprovalsScreen> createState() => _BudgetApprovalsScreenState();
}

class _BudgetApprovalsScreenState extends State<BudgetApprovalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  _IndentTab? _tab;
  String _query = '';

  UserProfile? get _me {
    final s = context.read<AuthBloc>().state;
    return s is AuthenticatedState ? s.userProfile : null;
  }

  bool get _canViewAll => IndentFlowHelper.canViewAll(_me);

  @override
  void initState() {
    super.initState();
    _tab = _canViewAll ? _IndentTab.all : _IndentTab.inbox;
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent(canViewAll: _canViewAll));
  }

  void _selectTab(_IndentTab tab) {
    setState(() {
      _tab = tab;
      _query = '';
      _searchController.clear();
    });
  }

  List<IndentItemModel> _itemsFor(ApprovalsLoadedState st) {
    switch (_tab!) {
      case _IndentTab.inbox:
        return st.indentsInbox;
      case _IndentTab.mine:
        return st.indentsMine;
      case _IndentTab.approved:
        return st.indentsAll.where((e) => e.status == 'approved').toList();
      case _IndentTab.rejected:
        return st.indentsAll.where((e) => e.status == 'rejected').toList();
      case _IndentTab.all:
        return st.indentsAll;
    }
  }

  List<IndentItemModel> _applySearch(List<IndentItemModel> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    bool has(String? v) => v != null && v.toLowerCase().contains(q);
    return list
        .where((r) =>
            has(r.indentNo) ||
            has(r.title) ||
            has(r.purpose) ||
            has(r.raisedBy) ||
            has(r.departmentName) ||
            has(r.branchName) ||
            has(r.voucherNo))
        .toList();
  }

  String _emptyText() {
    switch (_tab!) {
      case _IndentTab.inbox:
        return ApprovalsConstStrings.emptyInbox;
      case _IndentTab.mine:
        return ApprovalsConstStrings.emptyMine;
      case _IndentTab.approved:
        return ApprovalsConstStrings.emptyApproved;
      case _IndentTab.rejected:
        return ApprovalsConstStrings.emptyRejected;
      case _IndentTab.all:
        return ApprovalsConstStrings.emptyAll;
    }
  }

  Future<void> _openRaiseIndent() async {
    await RaiseIndentDialog.show(context, onCreated: _refresh);
  }

  Future<void> _openDetail(IndentItemModel item) async {
    final changed = await IndentDetailDialog.show(context, indentId: item.id, initialIndent: item);
    if (changed == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthBloc>(); // rebuild if the profile changes

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
          child: BlocBuilder<ApprovalsBloc, ApprovalsState>(
            builder: (context, state) {
              final loaded = state is ApprovalsLoadedState ? state : null;
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(child: _buildHeader(context)),
                    ),
                    SliverToBoxAdapter(child: _buildTabs(context, loaded)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(child: _buildSearch(context)),
                    ),
                    ..._buildBody(context, state),
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ApprovalsConstStrings.budgetIndentsTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _openRaiseIndent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                ApprovalsConstStrings.raiseIndentButton,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ApprovalsConstStrings.budgetIndentsSubtitle,
          style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary(context)),
        ),
      ],
    );
  }

  Widget _buildTabs(BuildContext context, ApprovalsLoadedState? st) {
    final tabs = <(_IndentTab, String, int?, IndentTone?)>[
      if (_canViewAll) (_IndentTab.all, ApprovalsConstStrings.tabAllRequests, st?.indentsAll.length, null),
      (_IndentTab.inbox, ApprovalsConstStrings.tabToApprove,
          (st?.indentsInbox.isNotEmpty ?? false) ? st!.indentsInbox.length : null, null),
      (_IndentTab.mine, ApprovalsConstStrings.tabMyIndents,
          (st?.indentsMine.isNotEmpty ?? false) ? st!.indentsMine.length : null, null),
      (_IndentTab.approved, ApprovalsConstStrings.tabApproved,
          st?.indentsAll.where((e) => e.status == 'approved').length, IndentTone.approved),
      (_IndentTab.rejected, ApprovalsConstStrings.tabRejected,
          () {
            final n = st?.indentsAll.where((e) => e.status == 'rejected').length ?? 0;
            return n > 0 ? n : null;
          }(),
          IndentTone.rejected),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border(context))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: tabs.map((t) {
            final selected = _tab == t.$1;
            final accent = t.$4 == null ? AppColors.primary(context) : IndentUi.fg(context, t.$4!);
            final labelColor = selected
                ? (t.$4 == null ? AppColors.textPrimary(context) : accent)
                : AppColors.textSecondary(context);
            return InkWell(
              onTap: () => _selectTab(t.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: selected ? accent : AppColors.transparent, width: 2.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      t.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    if (t.$3 != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: t.$4 == null ? AppColors.chipBg(context) : IndentUi.bg(context, t.$4!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${t.$3}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: t.$4 == null ? AppColors.textSecondary(context) : accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
        decoration: InputDecoration(
          hintText: ApprovalsConstStrings.searchIndentsHint,
          hintStyle: TextStyle(fontSize: 13, color: AppColors.textFaint(context)),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary(context)),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary(context)),
                  onPressed: () => setState(() {
                    _query = '';
                    _searchController.clear();
                  }),
                ),
          filled: true,
          fillColor: AppColors.surface(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border(context)),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, ApprovalsState state) {
    if (state is ApprovalsErrorState) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary(context))),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _refresh, child: const Text(ApprovalsConstStrings.retry)),
              ],
            ),
          ),
        ),
      ];
    }
    if (state is! ApprovalsLoadedState) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: AnimatedCircleProgressIndicator(size: 44)),
          ),
        ),
      ];
    }

    final source = _itemsFor(state);
    final items = _applySearch(source);

    if (source.isEmpty) {
      return [SliverToBoxAdapter(child: _emptyView(context, _emptyText()))];
    }
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _emptyView(
            context,
            '${ApprovalsConstStrings.noIndentsMatch} "$_query"',
            action: TextButton(
              onPressed: () => setState(() {
                _query = '';
                _searchController.clear();
              }),
              child: const Text(ApprovalsConstStrings.clearSearch),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => StaggeredSlideFade(
            delay: Duration(milliseconds: 30 * (index < 10 ? index : 10)),
            child: _IndentCard(item: items[index], onTap: () => _openDetail(items[index])),
          ),
        ),
      ),
    ];
  }

  Widget _emptyView(BuildContext context, String text, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: 44, color: AppColors.textFaint(context)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}

class _IndentCard extends StatelessWidget {
  final IndentItemModel item;
  final VoidCallback onTap;

  const _IndentCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tone = IndentUi.toneForStatus(item.status);
    final statusColor = IndentUi.fg(context, tone);
    final meta = <String>[
      'by ${item.raisedBy ?? '—'}',
      if (item.departmentName != null && item.departmentName!.isNotEmpty) item.departmentName!,
      if (item.branchName != null && item.branchName!.isNotEmpty) item.branchName!,
      IndentUi.dateTime(item.createdAt),
    ].join(' · ');

    String? footer;
    Color? footerColor;
    if (item.status == 'pending') {
      footer = IndentFlowHelper.pendingSummary(item);
      footerColor = IndentUi.fg(context, IndentTone.pending);
    } else if (item.status == 'approved' && (item.voucherNo ?? '').isNotEmpty) {
      footer = '${ApprovalsConstStrings.voucherPrefix} ${item.voucherNo} ${ApprovalsConstStrings.voucherReadySuffix}';
      footerColor = IndentUi.fg(context, IndentTone.approved);
    } else if (item.status == 'rejected') {
      footer = ApprovalsConstStrings.requestRejected + (item.isOverridden ? ApprovalsConstStrings.byDirectorOverride : '');
      footerColor = IndentUi.fg(context, IndentTone.rejected);
    }

    return ScaleTap(
      child: Material(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.chipBg(context),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        item.indentNo,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ),
                                    IndentUi.pill(context, IndentUi.capitalize(item.status),
                                        fg: statusColor, bg: IndentUi.bg(context, tone)),
                                    if (item.isOverridden)
                                      IndentUi.pill(context, ApprovalsConstStrings.overriddenBadge,
                                          fg: AppColors.badgeVioletFg(context), bg: AppColors.badgeVioletBg(context)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                IndentUi.money(item.amount),
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          if ((item.purpose ?? '').isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              item.purpose!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(context)),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(meta, style: TextStyle(fontSize: 11, color: AppColors.textFaint(context))),
                          if (footer != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              footer,
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: footerColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
