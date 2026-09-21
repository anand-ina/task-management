import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../modules/tasks/models/task_model.dart';
import '../../../modules/tasks/repository/task_repository.dart';
import '../dropdowns/searchable_filter_dropdown.dart';

class ChangeStatusDialog extends StatefulWidget {
  final TaskItemModel task;

  const ChangeStatusDialog({
    super.key,
    required this.task,
  });

  static Future<bool?> show(BuildContext context, {required TaskItemModel task}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => ChangeStatusDialog(task: task),
    );
  }

  @override
  State<ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<ChangeStatusDialog> {
  final TaskRepository _repository = TaskRepository();
  final TextEditingController _commentController = TextEditingController();
  final List<String> _attachedFileNames = [];

  late String _selectedStatus;
  late String _selectedPriority;
  late double _progress;
  bool _isSaving = false;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    // Normalize status for backend
    final rawStatus = widget.task.status.toLowerCase();
    if (rawStatus.contains('done') || rawStatus.contains('review')) {
      _selectedStatus = 'done';
    } else if (rawStatus.contains('progress')) {
      _selectedStatus = 'in_progress';
    } else if (rawStatus.contains('completed')) {
      _selectedStatus = 'completed';
    } else if (rawStatus.contains('dropped')) {
      _selectedStatus = 'dropped';
    } else if (rawStatus.contains('block')) {
      _selectedStatus = 'blocked';
    } else {
      _selectedStatus = 'to_be_started';
    }

    // Normalize priority
    final rawPriority = widget.task.priority.toLowerCase();
    if (rawPriority.contains('emergency')) {
      _selectedPriority = 'emergency';
    } else if (rawPriority.contains('top')) {
      _selectedPriority = 'top_most';
    } else if (rawPriority.contains('medium')) {
      _selectedPriority = 'medium';
    } else if (rawPriority.contains('low')) {
      _selectedPriority = 'low';
    } else {
      _selectedPriority = 'high';
    }

    _progress = widget.task.progress.toDouble().clamp(0.0, 100.0);
    if (_selectedStatus == 'done' && _progress < 100) {
      _progress = 100.0;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final dynamic result = await FilePicker.pickFiles(type: FileType.any);
      if (result != null) {
        final List<dynamic> fileList = result is List ? result : (result.files as List);
        if (fileList.isNotEmpty) {
          setState(() {
            for (final dynamic file in fileList) {
              String fileName = 'attachment';
              try {
                fileName = (file as dynamic).name?.toString() ?? 'attachment';
              } catch (_) {}
              if (!_attachedFileNames.contains(fileName)) {
                _attachedFileNames.add(fileName);
              }
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSave() async {
    final comment = _commentController.text.trim();
    final s = AppStrings.of(context);

    if (comment.isEmpty) {
      setState(() {
        _commentError = s.commentRequiredError;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _commentError = null;
    });

    try {
      final attachments = _attachedFileNames.map((name) => {'name': name}).toList();
      await _repository.updateTaskStatus(
        taskId: widget.task.id,
        status: _selectedStatus,
        priority: _selectedPriority,
        progress: _progress.round(),
        blockReason: '',
        comment: comment,
        mentionIds: const [],
        attachments: attachments,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.taskUpdatedSuccess),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _statusLabel(AppStrings s, String st) {
    switch (st) {
      case 'done':
        return 'Done (in review)';
      case 'to_be_started':
        return s.toBeStarted;
      case 'in_progress':
        return s.inProgress;
      case 'completed':
        return s.completed;
      case 'dropped':
        return s.dropped;
      case 'blocked':
        return s.blockedStatus;
      default:
        return st;
    }
  }


  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusOptions = [
      SearchableDropdownItem<String?>(value: 'done', label: 'Done (in review)'),
      SearchableDropdownItem<String?>(value: 'to_be_started', label: s.toBeStarted),
      SearchableDropdownItem<String?>(value: 'in_progress', label: s.inProgress),
      SearchableDropdownItem<String?>(value: 'completed', label: s.completed),
      SearchableDropdownItem<String?>(value: 'dropped', label: s.dropped),
      SearchableDropdownItem<String?>(value: 'blocked', label: s.blockedStatus),
    ];

    final priorityOptions = [
      SearchableDropdownItem<String?>(value: 'emergency', label: s.priorityEmergency),
      SearchableDropdownItem<String?>(value: 'top_most', label: s.priorityTopMost),
      SearchableDropdownItem<String?>(value: 'high', label: s.priorityHigh),
      SearchableDropdownItem<String?>(value: 'medium', label: s.priorityMedium),
      SearchableDropdownItem<String?>(value: 'low', label: s.priorityLow),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Title, Status Badge, Close button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    s.changeStatusTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(s, _selectedStatus),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Subtitle: Task ID & Title
              Text(
                '${s.taskNoPrefix} ${widget.task.taskNo} — ${widget.task.title}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),

              // Field 1: New Status
              Text(
                s.newStatusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              SearchableFilterDropdown<String?>(
                value: _selectedStatus,
                hint: s.newStatusLabel,
                isExpanded: true,
                items: statusOptions,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                      if (val == 'done' || val == 'completed') {
                        _progress = 100;
                      } else if (val == 'to_be_started') {
                        _progress = 0;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Field 2: Priority
              Text(
                s.priorityLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              SearchableFilterDropdown<String?>(
                value: _selectedPriority,
                hint: s.priorityLabel,
                isExpanded: true,
                items: priorityOptions,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPriority = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Field 3: Completion % Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.completionLabel}: ${_progress.round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF2563EB),
                  inactiveTrackColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  thumbColor: const Color(0xFF2563EB),
                  overlayColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _progress,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_progress.round()}%',
                  onChanged: (val) {
                    setState(() {
                      _progress = val;
                      if (_progress == 100 && _selectedStatus == 'to_be_started') {
                        _selectedStatus = 'done';
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Field 4: Comment * (required for every update)
              Text(
                s.commentRequiredLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: s.commentPlaceholder,
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  errorText: _commentError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Field 5: Attachments
              Text(
                s.attachmentsLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file_rounded, size: 16),
                label: Text(s.addFiles, style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
              ),
              if (_attachedFileNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _attachedFileNames.map((name) {
                    return Chip(
                      label: Text(name, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() {
                          _attachedFileNames.remove(name);
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons: Cancel and Save
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: Text(s.cancelButton, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(s.saveButton, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
