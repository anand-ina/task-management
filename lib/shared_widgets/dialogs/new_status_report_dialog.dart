import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/reports/models/pull_tasks_model.dart';
import '../../../modules/reports/repository/reports_repository.dart';

class NewStatusReportDialog extends StatefulWidget {
  const NewStatusReportDialog({super.key});

  static Future<bool?> show(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NewStatusReportDialog(),
    );
  }

  @override
  State<NewStatusReportDialog> createState() => _NewStatusReportDialogState();
}

class _NewStatusReportDialogState extends State<NewStatusReportDialog> {
  final ReportsRepository _repository = ReportsRepository();
  bool _isLoadingPull = true;
  bool _isSaving = false;

  String _selectedType = 'dsr'; // 'dsr', 'wsr', 'msr'
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _workCompletedController = TextEditingController();
  final TextEditingController _workInProgressController = TextEditingController();
  final TextEditingController _pendingTasksController = TextEditingController();
  final TextEditingController _challengesController = TextEditingController();

  PullTasksResponseModel? _pulledTasks;

  @override
  void initState() {
    super.initState();
    _fetchPulledTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _workCompletedController.dispose();
    _workInProgressController.dispose();
    _pendingTasksController.dispose();
    _challengesController.dispose();
    super.dispose();
  }

  Future<void> _fetchPulledTasks() async {
    setState(() => _isLoadingPull = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final res = await _repository.pullTasks(type: _selectedType, date: dateStr);
    if (mounted) {
      setState(() {
        _pulledTasks = res;
        _isLoadingPull = false;
      });
    }
  }

  Future<void> _saveReport(String status) async {
    final workCompletedText = _workCompletedController.text.trim();

    if (status == 'submitted' && workCompletedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Work Completed details')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final pendingAutoLines = _pulledTasks?.pendingTasks
            .map((e) => {'taskId': e.taskId, 'line': e.line})
            .toList() ??
        [];

    final payload = {
      'type': _selectedType,
      'periodDate': dateStr,
      'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      'workCompleted': workCompletedText.isNotEmpty ? workCompletedText : 'N/A',
      'workInProgress': _workInProgressController.text.trim(),
      'pendingTasks': _pendingTasksController.text.trim(),
      'challenges': _challengesController.text.trim(),
      'status': status,
      'autoLines': {
        'work_completed': _pulledTasks?.workCompleted ?? [],
        'work_in_progress': _pulledTasks?.workInProgress ?? [],
        'pending_tasks': pendingAutoLines,
      },
    };

    final result = await _repository.submitReport(payload);

    if (mounted) {
      setState(() => _isSaving = false);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'submitted' ? 'Report submitted successfully!' : 'Report saved as draft!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit report. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTypeSubtitle(AppStrings s) {
    switch (_selectedType) {
      case 'wsr':
        return s.weeklyWsr;
      case 'msr':
        return s.monthlyMsr;
      case 'dsr':
      default:
        return s.dailyDsr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAutoLines = (_pulledTasks?.pendingTasks.length ?? 0) +
        (_pulledTasks?.workCompleted.length ?? 0) +
        (_pulledTasks?.workInProgress.length ?? 0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 580,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      s.newStatusReport,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTypeSubtitle(s),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type & Date Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.reportTypeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedType,
                                isDense: true,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'dsr', child: Text(s.dailyDsr, style: const TextStyle(fontSize: 11))),
                                  DropdownMenuItem(value: 'wsr', child: Text(s.weeklyWsr, style: const TextStyle(fontSize: 11))),
                                  DropdownMenuItem(value: 'msr', child: Text(s.monthlyMsr, style: const TextStyle(fontSize: 11))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedType = val);
                                    _fetchPulledTasks();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.periodDateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                    _fetchPulledTasks();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.periodDateHint,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Title (Optional)
                    const Text('Title (optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: s.enterDetailsPlaceholder,
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Auto-fill Yellow Banner matching Image 1 mockup
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                ),
                                children: [
                                  TextSpan(
                                    text: '$totalAutoLines ${s.autoFillBannerNote}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Work Completed *
                    Text(s.workCompletedLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _workCompletedController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: s.enterDetailsPlaceholder,
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Work in Progress
                    Text(s.workInProgressLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _workInProgressController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: s.enterDetailsPlaceholder,
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pending Tasks (With Locked Auto Pills)
                    Text(s.pendingTasksLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (_isLoadingPull)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_pulledTasks != null && _pulledTasks!.pendingTasks.isNotEmpty) ...[
                      Column(
                        children: _pulledTasks!.pendingTasks.map((t) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'auto ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    t.line,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                    ],
                    TextField(
                      controller: _pendingTasksController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: s.enterDetailsPlaceholder,
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Challenges / Blockers
                    Text(s.challengesBlockersLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _challengesController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: InputDecoration(
                        hintText: s.enterDetailsPlaceholder,
                        hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(s.cancelButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isSaving ? null : () => _saveReport('draft'),
                  child: Text(s.saveDraft, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isSaving ? null : () => _saveReport('submitted'),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(s.submitButton, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
