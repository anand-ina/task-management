import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../modules/approvals/constants/approvals_const_strings.dart';
import '../../modules/approvals/models/indent_model.dart';
import '../../modules/approvals/repository/approvals_repository.dart';
import '../../modules/approvals/utils/indent_flow_helper.dart';
import '../../modules/approvals/utils/indent_ui.dart';
import '../../modules/approvals/utils/indent_voucher_pdf.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/auth/models/user_profile.dart';
import '../animations/app_animations.dart';

/// Indent detail — same rules as the web portal:
///  * approver (Center Head / Director / Finance Manager) sees "Your decision" when their step is actionable
///  * Director always gets the "Executive Oversight & Override" card
///  * the raiser can cancel while pending
/// Pops `true` when something changed so the list can refresh.
class IndentDetailDialog extends StatefulWidget {
  final int indentId;
  final IndentItemModel? initialIndent;

  const IndentDetailDialog({
    super.key,
    required this.indentId,
    this.initialIndent,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int indentId,
    IndentItemModel? initialIndent,
  }) {
    return showSmoothDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => IndentDetailDialog(
        indentId: indentId,
        initialIndent: initialIndent,
      ),
    );
  }

  @override
  State<IndentDetailDialog> createState() => _IndentDetailDialogState();
}

class _IndentDetailDialogState extends State<IndentDetailDialog> {
  final ApprovalsRepository _repository = ApprovalsRepository();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = true;
  bool _busy = false;
  bool _changed = false;
  IndentItemModel? _indent;

  @override
  void initState() {
    super.initState();
    _indent = widget.initialIndent;
    _fetchDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final detail = await _repository.getIndentDetail(widget.indentId);
    if (mounted) {
      setState(() {
        if (detail != null) {
          _indent = detail;
        }
        _isLoading = false;
      });
    }
  }

  UserProfile? get _me {
    final st = context.read<AuthBloc>().state;
    return st is AuthenticatedState ? st.userProfile : null;
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.red600 : AppColors.green600,
      ),
    );
  }

  Future<void> _decide(String decision) async {
    final indent = _indent;
    if (indent == null) return;
    final comment = _commentController.text.trim();
    if (decision == 'reject' && comment.isEmpty) {
      _toast(ApprovalsConstStrings.rejectReasonRequired, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await _repository.decideIndent(indent.id, decision, comment: comment);
      _changed = true;
      _commentController.clear();
      if (r.status == 'approved') {
        _toast('${ApprovalsConstStrings.fullyApprovedPrefix} ${r.voucherNo ?? ''}');
      } else if (r.status == 'rejected') {
        _toast(ApprovalsConstStrings.indentRejected);
      } else {
        _toast('${ApprovalsConstStrings.approvedNowWith} ${r.nextLevel ?? ''}');
      }
      await _fetchDetail();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openOverride(String decision) async {
    final indent = _indent;
    if (indent == null) return;
    final comment = await showDialog<String>(
      context: context,
      builder: (_) => _OverrideDialog(indent: indent, decision: decision),
    );
    if (comment == null || comment.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await _repository.overrideIndent(indent.id, decision, comment);
      _changed = true;
      _toast(decision == 'approve'
          ? ApprovalsConstStrings.overrideApprovedToast
          : ApprovalsConstStrings.overrideRejectedToast);
      await _fetchDetail();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelIndent() async {
    final indent = _indent;
    if (indent == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(ApprovalsConstStrings.cancelIndentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(ApprovalsConstStrings.keep)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ApprovalsConstStrings.yesCancel, style: TextStyle(color: AppColors.badgeRedFg(ctx))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await _repository.cancelIndent(indent.id);
      _changed = true;
      _toast(ApprovalsConstStrings.indentCancelled);
      await _fetchDetail();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _pdfBusy = false;

  Future<void> _voucher(IndentItemModel indent, {required bool download}) async {
    if (_pdfBusy) return;
    setState(() => _pdfBusy = true);
    try {
      // always print from the latest server copy (GET /indents/{id})
      final fresh = await _repository.getIndentDetail(indent.id) ?? indent;
      if (download) {
        await IndentVoucherPdf.downloadVoucher(fresh);
      } else {
        await IndentVoucherPdf.printVoucher(fresh);
      }
    } catch (e) {
      _toast('Could not generate voucher: $e', error: true);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indent = _indent;
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: media.size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, indent),
              Divider(height: 1, color: AppColors.border(context)),
              Flexible(
                child: indent == null
                    ? _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: AnimatedCircleProgressIndicator(size: 40)),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(ApprovalsConstStrings.loadFailed,
                                style: TextStyle(color: AppColors.textSecondary(context))),
                          )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        child: _buildBody(context, indent),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IndentItemModel? indent) {
    final tone = IndentUi.toneForStatus(indent?.status ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  indent?.indentNo ?? 'Indent',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                ),
                if (indent != null)
                  IndentUi.pill(context, IndentUi.capitalize(indent.status),
                      fg: IndentUi.fg(context, tone), bg: IndentUi.bg(context, tone)),
                if (indent?.isOverridden == true)
                  IndentUi.pill(context, ApprovalsConstStrings.overriddenBadge,
                      fg: AppColors.badgeVioletFg(context), bg: AppColors.badgeVioletBg(context)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.textSecondary(context)),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.chipBg(context), borderRadius: BorderRadius.circular(6)),
          child: Text(text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
        ),
      );

  Widget _card(BuildContext context, {required Widget child, Color? accent, Color? background}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background ?? AppColors.subtleBg(context),
        borderRadius: BorderRadius.circular(10),
        border: accent != null
            ? Border(left: BorderSide(color: accent, width: 4))
            : Border.all(color: AppColors.border(context)),
      ),
      child: child,
    );
  }

  Widget _buildBody(BuildContext context, IndentItemModel indent) {
    final me = _me;
    final isDirector = IndentFlowHelper.isDirector(me);
    final isFinance = IndentFlowHelper.isFinanceManager(me);
    final isRaiser = IndentFlowHelper.isRaiser(indent, me);
    final signed = IndentFlowHelper.mySignedStep(indent, me);
    final actionable = IndentFlowHelper.actionableStep(indent, me);
    final faint = AppColors.textFaint(context);

    final meta = <InlineSpan>[
      TextSpan(text: '${ApprovalsConstStrings.raisedBy} '),
      TextSpan(
          text: indent.raisedBy ?? '—',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
    ];
    final extra = <String>[
      if ((indent.departmentName ?? '').isNotEmpty) '${ApprovalsConstStrings.deptPrefix}: ${indent.departmentName}',
      if ((indent.branchName ?? '').isNotEmpty) '${ApprovalsConstStrings.branchPrefix}: ${indent.branchName}',
      if ((indent.neededBy ?? '').isNotEmpty) '${ApprovalsConstStrings.neededBy} ${IndentUi.date(indent.neededBy)}',
      IndentUi.dateTime(indent.createdAt),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(indent.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
            ),
            const SizedBox(width: 8),
            Text(IndentUi.money(indent.amount),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
          ],
        ),
        if ((indent.purpose ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(indent.purpose!, style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
        ],
        const SizedBox(height: 8),
        Text.rich(TextSpan(children: meta), style: TextStyle(fontSize: 12, color: faint)),
        const SizedBox(height: 2),
        Text(extra.join('  ·  '), style: TextStyle(fontSize: 12, color: faint)),

        // Line items (cards instead of a table on mobile)
        if (indent.items.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionLabel(context, ApprovalsConstStrings.lineItems),
          ...indent.items.map((it) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.subtleBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.description,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                          const SizedBox(height: 2),
                          Text('${ApprovalsConstStrings.qty} ${it.qty} × ${IndentUi.money(it.unitPrice)}',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(context))),
                        ],
                      ),
                    ),
                    Text(IndentUi.money(it.amount),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${ApprovalsConstStrings.total}  ${IndentUi.money(indent.amount)}',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
          ),
        ],

        if (indent.isOverridden) _buildOverrideSummary(context, indent),

        // Approval chain
        const SizedBox(height: 16),
        _sectionLabel(context, ApprovalsConstStrings.sequentialChain),
        if (indent.steps.isEmpty)
          Text(ApprovalsConstStrings.noStepsConfigured, style: TextStyle(fontSize: 12, color: faint))
        else
          ...indent.steps.map((st) => _buildStep(context, indent, st)),

        if (signed != null && indent.status == 'pending')
          _card(
            context,
            background: AppColors.badgeGreenBg(context),
            child: Text(
              '✓ ${ApprovalsConstStrings.youSignedOff} ${ApprovalsConstStrings.step} ${signed.stepNo}: ${signed.displayLabel}.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.badgeGreenFg(context)),
            ),
          ),

        if (indent.status == 'pending' && isFinance && actionable == null && signed == null)
          _card(
            context,
            child: Text(
              'ℹ ${indent.amount <= IndentFlowHelper.tierTwoLimit ? ApprovalsConstStrings.awaitingChOnly : ApprovalsConstStrings.awaitingChAndDirector}',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(context)),
            ),
          ),

        if (indent.audits.isNotEmpty) ...[
          const SizedBox(height: 18),
          _sectionLabel(context, ApprovalsConstStrings.auditHistory),
          ...indent.audits.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(a.actorName ?? ApprovalsConstStrings.system,
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                        IndentUi.pill(context, a.action.replaceAll('_', ' '),
                            fg: AppColors.textSecondary(context), bg: AppColors.chipBg(context)),
                        Text(IndentUi.dateTime(a.createdAt), style: TextStyle(fontSize: 10.5, color: faint)),
                      ],
                    ),
                    if ((a.comment ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text('“${a.comment}”',
                          style: TextStyle(
                              fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textSecondary(context))),
                    ],
                  ],
                ),
              )),
        ],

        if (indent.status == 'approved' && (indent.voucherNo ?? '').isNotEmpty)
          _card(
            context,
            accent: AppColors.badgeGreenFg(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${ApprovalsConstStrings.fullyApprovedVoucher} '),
                    TextSpan(
                        text: indent.voucherNo,
                        style: TextStyle(
                            fontFamily: 'monospace', fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
                  ]),
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pdfBusy ? null : () => _voucher(indent, download: false),
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print voucher (PDF)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary(context),
                        foregroundColor: AppColors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pdfBusy ? null : () => _voucher(indent, download: true),
                      icon: _pdfBusy
                          ? const SizedBox(width: 14, height: 14, child: AnimatedCircleProgressIndicator(size: 14))
                          : const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (actionable != null) _buildDecisionCard(context, actionable),

        if (isDirector) _buildDirectorOverride(context, indent),

        if (indent.status == 'pending' && isRaiser)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: _busy ? null : _cancelIndent,
              child: Text(ApprovalsConstStrings.cancelIndent,
                  style: TextStyle(color: AppColors.badgeRedFg(context), fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _buildOverrideSummary(BuildContext context, IndentItemModel indent) {
    final ok = indent.overrideDecision == 'approved';
    final c = ok ? AppColors.badgeGreenFg(context) : AppColors.badgeRedFg(context);
    return _card(
      context,
      accent: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${ApprovalsConstStrings.directorOverridePrefix} ${ok ? 'Approved' : 'Rejected'}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
              ),
              Text(IndentUi.dateTime(indent.overriddenAt),
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
            ],
          ),
          const SizedBox(height: 4),
          Text('${ApprovalsConstStrings.actionTakenBy} ${indent.overrideByName ?? 'Director'}',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary(context))),
          if ((indent.overrideComment ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('“${indent.overrideComment}”',
                style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: AppColors.textPrimary(context))),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, IndentItemModel indent, IndentStepModel st) {
    final status = IndentFlowHelper.stepStatus(indent, st);
    final color = IndentUi.fg(context, status.tone);
    final kind = IndentFlowHelper.stepKind(st);
    final kindTone = st.isFinanceStep
        ? (AppColors.badgeGreenFg(context), AppColors.badgeGreenBg(context))
        : st.isOptional
            ? (AppColors.badgeBlueFg(context), AppColors.badgeBlueBg(context))
            : (AppColors.badgeYellowFg(context), AppColors.badgeYellowBg(context));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.subtleBg(context), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${ApprovalsConstStrings.step} ${st.stepNo}: ${st.displayLabel}',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                    IndentUi.pill(context, kind, fg: kindTone.$1, bg: kindTone.$2),
                  ],
                ),
                const SizedBox(height: 3),
                Text(status.text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
                if ((status.actor ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('${status.actor} · ${IndentUi.dateTime(status.at)}',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(context))),
                ],
                if ((status.comment ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('“${status.comment}”',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary(context))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(BuildContext context, IndentStepModel step) {
    final kind = step.isFinanceStep
        ? 'Final Approval'
        : step.isOptional
            ? 'Optional Review'
            : ApprovalsConstStrings.mandatoryApproval;
    return _card(
      context,
      background: AppColors.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, '${ApprovalsConstStrings.yourDecision} (${step.displayLabel} · $kind)'),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: ApprovalsConstStrings.commentHint,
              hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textFaint(context)),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _decide('approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '✓ ${step.isFinanceStep ? ApprovalsConstStrings.approveAndIssueVoucher : ApprovalsConstStrings.approveAction}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _decide('reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.badgeRedFg(context),
                    side: BorderSide(color: AppColors.badgeRedFg(context)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(ApprovalsConstStrings.rejectAction, style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorOverride(BuildContext context, IndentItemModel indent) {
    final violet = AppColors.badgeVioletFg(context);
    final info = indent.status == 'rejected'
        ? ApprovalsConstStrings.overrideRejectedInfo
        : indent.status == 'approved'
            ? ApprovalsConstStrings.overrideApprovedInfo
            : ApprovalsConstStrings.overridePendingInfo;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.badgeVioletBg(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: violet.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ApprovalsConstStrings.directorOversight,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: violet)),
          const SizedBox(height: 2),
          Text('(${ApprovalsConstStrings.directorOversightSub})',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
          const SizedBox(height: 6),
          Text(info, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
          const SizedBox(height: 10),
          if (indent.status != 'approved')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : () => _openOverride('approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  indent.status == 'rejected'
                      ? ApprovalsConstStrings.overrideRejectionApprove
                      : ApprovalsConstStrings.directorOverrideApprove,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (indent.status != 'approved' && indent.status != 'rejected') const SizedBox(height: 8),
          if (indent.status != 'rejected')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : () => _openOverride('reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.badgeRedFg(context),
                  side: BorderSide(color: AppColors.badgeRedFg(context)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  indent.status == 'approved'
                      ? ApprovalsConstStrings.revokeAndReject
                      : ApprovalsConstStrings.directorRejectNotNecessary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Director override justification sheet. Pops the comment (or null when cancelled).
class _OverrideDialog extends StatefulWidget {
  final IndentItemModel indent;
  final String decision;

  const _OverrideDialog({required this.indent, required this.decision});

  @override
  State<_OverrideDialog> createState() => _OverrideDialogState();
}

class _OverrideDialogState extends State<_OverrideDialog> {
  final TextEditingController _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approve = widget.decision == 'approve';
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        approve ? ApprovalsConstStrings.overrideApproveTitle : ApprovalsConstStrings.overrideRejectTitle,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: approve ? AppColors.badgeGreenFg(context) : AppColors.badgeRedFg(context),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approve
                  ? 'You are overriding earlier rejection(s) to approve ${widget.indent.indentNo} under Director authority. A purchase voucher will be generated.'
                  : 'You are rejecting ${widget.indent.indentNo} as not necessary. Any previous approvals/vouchers will be revoked.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 12),
            Text(
              approve ? ApprovalsConstStrings.overrideApproveLabel : ApprovalsConstStrings.overrideRejectLabel,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _c,
              minLines: 3,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: approve ? ApprovalsConstStrings.overrideApproveHint : ApprovalsConstStrings.overrideRejectHint,
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textFaint(context)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(ApprovalsConstStrings.cancel)),
        ElevatedButton(
          onPressed: _c.text.trim().isEmpty ? null : () => Navigator.pop(context, _c.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: approve ? AppColors.green600 : AppColors.red600,
            foregroundColor: AppColors.white,
          ),
          child: Text(approve ? ApprovalsConstStrings.confirmOverrideApprove : ApprovalsConstStrings.confirmRejection),
        ),
      ],
    );
  }
}
