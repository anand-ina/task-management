import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/localization/app_strings.dart';
import '../../modules/reports/models/status_report_model.dart';
import '../../modules/reports/repository/reports_repository.dart';
import '../status_report_pdf_service.dart';

/// Read-only dialog for viewing a status report + Save PDF action.
/// Shown when user taps a report card in the Status Reports screen.
class StatusReportViewDialog extends StatefulWidget {
  final StatusReportItemModel report;

  const StatusReportViewDialog({super.key, required this.report});

  static Future<void> show(BuildContext context, StatusReportItemModel report) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StatusReportViewDialog(report: report),
    );
  }

  @override
  State<StatusReportViewDialog> createState() => _StatusReportViewDialogState();
}

class _StatusReportViewDialogState extends State<StatusReportViewDialog> {
  final ReportsRepository _repository = ReportsRepository();
  bool _isSavingPdf = false;

  StatusReportItemModel get _report => widget.report;

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String _typeFull() {
    switch (_report.type.toLowerCase()) {
      case 'wsr':
        return 'Weekly (WSR)';
      case 'msr':
        return 'Monthly (MSR)';
      default:
        return 'Daily (DSR)';
    }
  }

  Future<void> _savePdf() async {
    if (_isSavingPdf) return;
    setState(() => _isSavingPdf = true);
    try {
      // Fetch fresh detail from API for the most up-to-date data
      final detail = await _repository.getReportDetail(_report.id);
      final reportToUse = detail ?? _report;
      if (mounted) {
        await StatusReportPdfService.generateAndPrint(context, reportToUse);
      }
    } finally {
      if (mounted) setState(() => _isSavingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSubmitted = _report.status.toLowerCase() == 'submitted';
    final periodStr = _formatDate(_report.periodDate);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_typeFull()} ${s.statusReportPdfTitle}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s.periodDateLabel}: $periodStr  ·  ${s.statusLabel}: ${_report.status}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Save PDF header button
                  _buildSavePdfButton(s, compact: true),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildReadOnlyField(
                      context,
                      '1. ${s.workCompletedLabel.toUpperCase()}',
                      _report.workCompleted ?? '—',
                      isDark,
                      labelColor: const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      context,
                      '2. ${s.workInProgressLabel.toUpperCase()}',
                      _report.workInProgress ?? '—',
                      isDark,
                      labelColor: const Color(0xFF0891B2),
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      context,
                      '3. ${s.pendingTasksLabel.toUpperCase()}',
                      _report.pendingTasks ?? '—',
                      isDark,
                      labelColor: const Color(0xFFB45309),
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      context,
                      '4. ${s.challengesBlockersLabel.toUpperCase()}',
                      _report.challenges ?? '—',
                      isDark,
                      labelColor: const Color(0xFFB91C1C),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_report.isLocked)
                    OutlinedButton(
                      onPressed: null, // Unlock API not yet available — UI only
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(s.unlockReportButton, style: const TextStyle(fontSize: 12)),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                    ),
                    child: Text(s.closeButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  _buildSavePdfButton(s, compact: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavePdfButton(AppStrings s, {required bool compact}) {
    if (_isSavingPdf) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (compact) {
      return OutlinedButton.icon(
        onPressed: _savePdf,
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
        label: Text(s.savePdfButton, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: _savePdf,
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
      label: Text(s.savePdfButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    Color? labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: labelColor ?? (isDark ? Colors.white70 : const Color(0xFF475569)),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
