import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../../modules/tasks/models/task_model.dart';
import '../../../modules/tasks/repository/task_repository.dart';

class ReviewTaskDialog extends StatefulWidget {
  final int taskId;
  final String taskNo;
  final String title;
  final String? assigneeNote;

  const ReviewTaskDialog({
    super.key,
    required this.taskId,
    required this.taskNo,
    required this.title,
    this.assigneeNote,
  });

  static Future<TaskDetailModel?> show(
    BuildContext context, {
    required int taskId,
    required String taskNo,
    required String title,
    String? assigneeNote,
  }) {
    return showDialog<TaskDetailModel?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ReviewTaskDialog(
        taskId: taskId,
        taskNo: taskNo,
        title: title,
        assigneeNote: assigneeNote,
      ),
    );
  }

  @override
  State<ReviewTaskDialog> createState() => _ReviewTaskDialogState();
}

class _ReviewTaskDialogState extends State<ReviewTaskDialog> {
  final TaskRepository _repository = TaskRepository();
  final TextEditingController _noteController = TextEditingController();

  String _decision = 'approve'; // 'approve' or 'return'
  int _pointsDelta = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final note = _noteController.text.trim();
    if (_decision == 'return' && note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note * is required when sending back'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updatedTask = await _repository.reviewTask(
        taskId: widget.taskId,
        decision: _decision,
        pointsDelta: _decision == 'approve' ? _pointsDelta : 0,
        note: note,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _decision == 'approve'
                  ? 'Task approved and completed successfully!'
                  : 'Task sent back successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updatedTask);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isApprove = _decision == 'approve';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header with Close Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Review Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 16),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Identifier — Title
                    Text(
                      '${widget.taskNo} — ${widget.title}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assignee's note
                    const Text(
                      "Assignee's note",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (widget.assigneeNote != null && widget.assigneeNote!.isNotEmpty)
                          ? widget.assigneeNote!
                          : 'No note provided',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Decision
                    const Text(
                      'Decision',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Approve & Complete Button
                        InkWell(
                          onTap: () => setState(() => _decision = 'approve'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isApprove
                                  ? const Color(0xFF132A50)
                                  : (isDark ? const Color(0xFF0F172A) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isApprove
                                    ? const Color(0xFF132A50)
                                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: isApprove ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Approve & Complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isApprove ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Send back Button
                        InkWell(
                          onTap: () => setState(() => _decision = 'return'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: !isApprove
                                  ? const Color(0xFF132A50)
                                  : (isDark ? const Color(0xFF0F172A) : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !isApprove
                                    ? const Color(0xFF132A50)
                                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sync_alt_rounded,
                                  size: 15,
                                  color: !isApprove ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Send back',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !isApprove ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Points adjustment (only when Approve & Complete is selected)
                    if (isApprove) ...[
                      Text(
                        'Points adjustment (base 10 pts): ${_pointsDelta >= 0 ? "+$_pointsDelta" : "$_pointsDelta"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: const Color(0xFF3B82F6),
                          inactiveTrackColor: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                          thumbColor: const Color(0xFF3B82F6),
                        ),
                        child: Slider(
                          value: _pointsDelta.toDouble(),
                          min: -10,
                          max: 10,
                          divisions: 20,
                          onChanged: (val) {
                            setState(() {
                              _pointsDelta = val.round();
                            });
                          },
                        ),
                      ),
                      Text(
                        'Award extra for great work, or reduce for issues. Total: ${10 + _pointsDelta} pts.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Note field
                    Row(
                      children: [
                        Text(
                          isApprove ? 'Note (optional)' : 'Note ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                        if (!isApprove)
                          const Text(
                            '*',
                            style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        hintText: isApprove
                            ? 'Add an optional note about this decision...'
                            : 'Explain what needs to be changed or fixed...',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF132A50), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.button(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isApprove ? 'Complete & award points' : 'Send back',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
