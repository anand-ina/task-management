import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../modules/auth/bloc/auth_bloc.dart';
import '../../modules/auth/bloc/auth_state.dart';
import '../../modules/tasks/bloc/create_task_bloc.dart';
import '../../modules/tasks/models/task_draft_model.dart';
import '../../modules/tasks/repository/task_repository.dart';
import '../animations/app_animations.dart';

class CreateTaskDialog extends StatefulWidget {
  final TaskDraftModel? initialDraft;
  const CreateTaskDialog({super.key, this.initialDraft});

  static Future<void> show(BuildContext context, {TaskDraftModel? initialDraft}) async {
    return showSmoothDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlocProvider(
        create: (_) => CreateTaskBloc(repository: TaskRepository())..add(FetchTaskDraftsEvent()),
        child: CreateTaskDialog(initialDraft: initialDraft),
      ),
    );
  }

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final DioClient _dioClient = DioClient();
  final TaskRepository _taskRepository = TaskRepository();
  bool _isLoadingLookups = true;
  bool _isSaving = false;

  List<dynamic> _branches = [];
  List<dynamic> _assignees = [];
  List<dynamic> _filteredAssignees = [];
  List<TaskDraftModel> _availableDrafts = [];

  int? _selectedBranchId;
  String? _nextTaskId;
  int? _currentDraftId;
  int? _assignedOnBehalfOfId;
  bool _isDismissedDraftBanner = false;
  Timer? _autoSaveDebounceTimer;

  String _selectedPriority = 'high';
  String _selectedCategory = 'General';
  bool _isRecurring = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _searchAssigneeController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();

  final DateTime _selectedDate = DateTime.now();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 7));

  final List<int> _selectedAssigneeIds = [];
  final List<Map<String, dynamic>> _checklistItems = [];
  final List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onFieldChanged);
    _descController.addListener(_onFieldChanged);

    if (widget.initialDraft != null) {
      _currentDraftId = widget.initialDraft!.id;
      _loadDraftData(widget.initialDraft!);
    }
    _loadLookups();
    _fetchNextTaskId();
  }

  @override
  void dispose() {
    _autoSaveDebounceTimer?.cancel();
    _titleController.removeListener(_onFieldChanged);
    _descController.removeListener(_onFieldChanged);
    _titleController.dispose();
    _descController.dispose();
    _remarksController.dispose();
    _searchAssigneeController.dispose();
    _checklistController.dispose();
    super.dispose();
  }

  Color _parseAvatarColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFFD97706);
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFD97706);
  }

  dynamic _safeParse(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  Future<void> _loadLookups() async {
    try {
      await Future.wait([
        _dioClient.dio.get(ApiConstants.branches).then((branchesRes) {
          final branchesData = _safeParse(branchesRes.data);
          if (branchesData is List && branchesData.isNotEmpty) {
            _branches = branchesData;
            if (_selectedBranchId == null) {
              _selectedBranchId = int.tryParse(_branches.first['id']?.toString() ?? '1') ?? 1;
              _fetchNextTaskId(branchId: _selectedBranchId);
            }
          }
        }).catchError((_) => null),
        _dioClient.dio.get(ApiConstants.assignees).then((assigneesRes) {
          final assigneesData = _safeParse(assigneesRes.data);
          if (assigneesData is List) {
            _assignees = assigneesData;
            _filteredAssignees = List.from(assigneesData);
          }
        }).catchError((_) => null),
        _dioClient.dio.get(ApiConstants.enums).catchError((_) => null),
      ]);
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingLookups = false);
    }
  }

  Future<void> _fetchNextTaskId({int? branchId}) async {
    try {
      final taskNo = await _taskRepository.getNextTaskId(branchId: branchId);
      if (mounted && taskNo != null) {
        setState(() {
          _nextTaskId = taskNo;
        });
      }
    } catch (e) {
      debugPrint('[CreateTaskDialog] fetchNextTaskId error: $e');
    }
  }

  void _onFieldChanged() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty && desc.isEmpty) return;

    _autoSaveDebounceTimer?.cancel();
    _autoSaveDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty && desc.isEmpty) return;

    final assigneeNames = _selectedAssigneeIds.map((id) {
      final match = _assignees.firstWhere((a) => a['id'] == id, orElse: () => {'name': ''});
      return match['name']?.toString() ?? '';
    }).where((n) => n.isNotEmpty).toList();

    final draftPayload = {
      'title': title,
      'description': desc,
      'branchId': _selectedBranchId,
      'priority': _selectedPriority,
      'category': _selectedCategory,
      'dueDate': DateFormat('yyyy-MM-dd').format(_targetDate),
      'remarks': _remarksController.text.trim(),
      'isRecurring': _isRecurring,
      'frequency': 'daily',
      'recurTime': '18:00',
      'weekday': 1,
      'monthday': 1,
      'specificDate': '',
      'splitPerAssignee': true,
      'assignedById': _assignedOnBehalfOfId != null ? _assignedOnBehalfOfId.toString() : '',
      'assigneeIds': _selectedAssigneeIds,
      'assigneeNames': assigneeNames,
      'checklist': _checklistItems,
      'attachments': _attachments,
    };

    final Map<String, dynamic> data = {
      if (_currentDraftId != null) 'id': _currentDraftId,
      'kind': 'task',
      'label': title.isNotEmpty ? title : 'Untitled Draft',
      'payload': draftPayload,
    };

    try {
      final newId = await _taskRepository.saveTaskDraft(data);
      if (newId != null && mounted) {
        setState(() {
          _currentDraftId = newId;
        });
      }
    } catch (e) {
      debugPrint('[CreateTaskDialog] Auto-save draft error: $e');
    }
  }

  void _filterAssignees(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAssignees = List.from(_assignees);
      } else {
        _filteredAssignees = _assignees.where((a) {
          final name = a['name']?.toString().toLowerCase() ?? '';
          final dept = a['department']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || dept.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _loadDraftData(TaskDraftModel draft) {
    final p = draft.payload;
    setState(() {
      _currentDraftId = draft.id;
      _titleController.text = p.title;
      _descController.text = p.description;
      if (p.branchId != null) _selectedBranchId = p.branchId;
      _selectedPriority = p.priority;
      _selectedCategory = p.category;
      if (p.dueDate != null && p.dueDate!.isNotEmpty) {
        _targetDate = DateTime.tryParse(p.dueDate!) ?? _targetDate;
      }
      _remarksController.text = p.remarks;
      _isRecurring = p.isRecurring;
      _assignedOnBehalfOfId = int.tryParse(p.assignedById);
      _selectedAssigneeIds.clear();
      _selectedAssigneeIds.addAll(p.assigneeIds);
      _checklistItems.clear();
      _checklistItems.addAll(p.checklist);
      _attachments.clear();
      _attachments.addAll(p.attachments);
      _isDismissedDraftBanner = true;
    });
    _fetchNextTaskId(branchId: _selectedBranchId);
  }

  Future<void> _saveDraft() async {
    _autoSaveDebounceTimer?.cancel();
    final s = AppStrings.of(context);
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    final assigneeNames = _selectedAssigneeIds.map((id) {
      final match = _assignees.firstWhere((a) => a['id'] == id, orElse: () => {'name': ''});
      return match['name']?.toString() ?? '';
    }).where((n) => n.isNotEmpty).toList();

    final draftPayload = {
      'title': title,
      'description': desc,
      'branchId': _selectedBranchId,
      'priority': _selectedPriority,
      'category': _selectedCategory,
      'dueDate': DateFormat('yyyy-MM-dd').format(_targetDate),
      'remarks': _remarksController.text.trim(),
      'isRecurring': _isRecurring,
      'frequency': 'daily',
      'recurTime': '18:00',
      'weekday': 1,
      'monthday': 1,
      'specificDate': '',
      'splitPerAssignee': true,
      'assignedById': _assignedOnBehalfOfId != null ? _assignedOnBehalfOfId.toString() : '',
      'assigneeIds': _selectedAssigneeIds,
      'assigneeNames': assigneeNames,
      'checklist': _checklistItems,
      'attachments': _attachments,
    };

    final Map<String, dynamic> data = {
      if (_currentDraftId != null) 'id': _currentDraftId,
      'kind': 'task',
      'label': title.isNotEmpty ? title : 'Untitled Draft',
      'payload': draftPayload,
    };

    setState(() => _isSaving = true);
    try {
      await _taskRepository.saveTaskDraft(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.draftSavedSuccess),
            backgroundColor: const Color(0xFF0F766E),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _submitTask() {
    _autoSaveDebounceTimer?.cancel();
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Task Title and Description')),
      );
      return;
    }

    final payload = {
      'title': title,
      'description': desc,
      'branchId': _selectedBranchId ?? 1,
      'priority': _selectedPriority,
      'category': _selectedCategory,
      'dueDate': DateFormat('yyyy-MM-dd').format(_targetDate),
      'remarks': _remarksController.text.isNotEmpty ? _remarksController.text.trim() : 'no',
      'assigneeIds': _selectedAssigneeIds.isNotEmpty ? _selectedAssigneeIds : [20],
      'checklist': _checklistItems,
      'attachments': _attachments,
      'isRecurring': _isRecurring,
    };

    context.read<CreateTaskBloc>().add(CreateTaskSubmitEvent(payload));
  }

  Future<void> _showUploadFileDialog() async {
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

              String? path;
              try {
                path = (file as dynamic).path?.toString();
              } catch (_) {}

              int fileSize = 0;
              try {
                fileSize = (file as dynamic).size is int ? (file as dynamic).size as int : 0;
              } catch (_) {}

              final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
              _attachments.add({
                'filename': fileName,
                'url': path ?? '/uploads/${DateTime.now().millisecondsSinceEpoch}-$fileName',
                'mime': _getMimeType(ext),
                'size': fileSize,
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[CreateTaskDialog] File pick error: $e');
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String hintText,
    Widget? prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8), // Light grey, never black
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CreateTaskBloc, CreateTaskState>(
      listener: (context, state) {
        if (state is CreateTaskSubmittingState || state is DraftSavingState) {
          setState(() => _isSaving = true);
        } else {
          setState(() => _isSaving = false);
        }

        if (state is CreateTaskSuccessState) {
          if (_currentDraftId != null) {
            _taskRepository.deleteTaskDraft(_currentDraftId!).catchError((_) => false);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is DraftSavedSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.draftSavedSuccess),
              backgroundColor: const Color(0xFF0F766E),
            ),
          );
          context.read<CreateTaskBloc>().add(FetchTaskDraftsEvent());
        } else if (state is CreateTaskErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is DraftsLoadedState) {
          setState(() {
            _availableDrafts = state.drafts;
          });
        }
      },
      builder: (context, state) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: 700,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [

                        Text(
                          s.createNewTaskTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _autoSaveDebounceTimer?.cancel();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                // Top Draft Resume Banner (when available, not dismissed, and not currently resuming)
                if (_availableDrafts.isNotEmpty && !_isDismissedDraftBanner && _currentDraftId == null) ...[
                  _buildSavedDraftBanner(context, _availableDrafts.first, isDark),
                  const SizedBox(height: 10),
                ],

                Expanded(
                  child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Task ID & Date Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Task ID (auto-generated)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: TextEditingController(
                                          text: _nextTaskId ?? 'SS03-0011/10-26'),
                                      readOnly: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.confirmedWhenYouSaveSubtext,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: TextEditingController(
                                        text: '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                      ),
                                      readOnly: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Task Title
                          const Text('Task Title *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 12),
                            decoration: _buildInputDecoration(
                              context,
                              hintText: s.taskTitlePlaceholder,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Task Description
                          const Text('Task Description *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _descController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 12),
                            decoration: _buildInputDecoration(
                              context,
                              hintText: s.taskDescriptionPlaceholder,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Assigned By & Subtext
                          Builder(
                            builder: (context) {
                              final authState = context.watch<AuthBloc>().state;
                              final userName = authState is AuthenticatedState ? authState.userProfile.name : 'Test_TL';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Assigned By', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: TextEditingController(text: '$userName (me)'),
                                    enabled: false,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.assignedBySubtext,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Assigning on Behalf of & School Branch
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Assigning on Behalf of (optional)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<int?>(
                                      value: _assignedOnBehalfOfId,
                                      isDense: true,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      ),
                                      hint: Text(
                                        s.selectUserOptional,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem<int?>(
                                          value: null,
                                          child: Text(
                                            s.selectUserOptional,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                        ..._assignees.map((a) {
                                          final id = a['id'] as int? ?? 0;
                                          final name = a['name']?.toString() ?? 'User';
                                          final role = a['role']?.toString() ?? '';
                                          return DropdownMenuItem<int?>(
                                            value: id,
                                            child: Text(
                                              role.isNotEmpty ? '$name ($role)' : name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (val) {
                                        setState(() => _assignedOnBehalfOfId = val);
                                        _onFieldChanged();
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.assigningOnBehalfOfSubtext,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('School Branch',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<int>(
                                      value: _selectedBranchId,
                                      isDense: true,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      ),
                                      items: _branches.isEmpty
                                          ? [
                                              DropdownMenuItem<int>(
                                                value: _selectedBranchId ?? 1,
                                                child: const Text('Head Office', style: TextStyle(fontSize: 11)),
                                              ),
                                            ]
                                          : _branches.map((b) {
                                              final id = int.tryParse(b['id']?.toString() ?? '1') ?? 1;
                                              final name = b['name']?.toString() ?? 'Head Office';
                                              return DropdownMenuItem<int>(
                                                value: id,
                                                child: Text(
                                                  name,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11),
                                                ),
                                              );
                                            }).toList(),
                                      onChanged: (val) {
                                        setState(() => _selectedBranchId = val);
                                        _fetchNextTaskId(branchId: val);
                                        _onFieldChanged();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Priority Chips
                          const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildPriorityChip('emergency', s.priorityActNow, const Color(0xFFDC2626)),
                              _buildPriorityChip('top_most', s.priorityActToday, const Color(0xFFD97706)),
                              _buildPriorityChip('high', s.priorityActThisWeek, const Color(0xFF0F172A)),
                              _buildPriorityChip('medium', s.priorityScheduleToAct, const Color(0xFF7C3AED)),
                              _buildPriorityChip('low', s.priorityWhenTimePermits, const Color(0xFF64748B)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Target Date
                          const Text('Target Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    '${_targetDate.day.toString().padLeft(2, '0')}/${_targetDate.month.toString().padLeft(2, '0')}/${_targetDate.year}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.calendar_month_rounded, size: 20),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _targetDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) setState(() => _targetDate = picked);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Category Cards (Confidential vs General) — Soft, elegant styling
                          const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = 'Confidential'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == 'Confidential'
                                          ? (isDark ? const Color(0xFF3B1E1E) : const Color(0xFFFEF2F2))
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedCategory == 'Confidential'
                                            ? const Color(0xFFEF4444)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: _selectedCategory == 'Confidential' ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('🔒', style: TextStyle(fontSize: 18)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Confidential',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _selectedCategory == 'Confidential'
                                                ? const Color(0xFFDC2626)
                                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = 'General'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _selectedCategory == 'General'
                                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedCategory == 'General'
                                            ? const Color(0xFF3B82F6)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: _selectedCategory == 'General' ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('📄', style: TextStyle(fontSize: 18)),
                                        const SizedBox(height: 4),
                                        Text(
                                          'General',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _selectedCategory == 'General'
                                                ? const Color(0xFF2563EB)
                                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Make this a recurring task Checkbox
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _isRecurring,
                                  activeColor: const Color(0xFF0F172A),
                                  onChanged: (val) => setState(() => _isRecurring = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('Make this a recurring task', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Assigned To Section (with Search & Light Grey Placeholders)
                          const Text('Assigned To', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _searchAssigneeController,
                            onChanged: _filterAssignees,
                            style: const TextStyle(fontSize: 11),
                            decoration: _buildInputDecoration(
                              context,
                              hintText: s.searchPeopleHint,
                              prefixIcon: const Icon(Icons.search, size: 16),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dynamic Groups Chips
                          const Text('GROUPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (context) {
                              final Map<String, List<int>> groupDeptMap = {};
                              for (var a in _assignees) {
                                final dept = a['department']?.toString() ?? 'Other';
                                final id = a['id'] as int? ?? 0;
                                if (id != 0) {
                                  groupDeptMap.putIfAbsent(dept, () => []).add(id);
                                }
                              }

                              return Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: groupDeptMap.entries.map((entry) {
                                  final deptName = entry.key;
                                  final memberIds = entry.value;
                                  final count = memberIds.length;

                                  return ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    label: Text('+ $deptName ($count)', style: const TextStyle(fontSize: 10)),
                                    onPressed: () {
                                      setState(() {
                                        for (var id in memberIds) {
                                          if (!_selectedAssigneeIds.contains(id)) {
                                            _selectedAssigneeIds.add(id);
                                          }
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 8),

                          // Split Columns for Pick Users & Selected Users
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left User Picker List
                              Expanded(
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: ListView.builder(
                                    itemCount: _filteredAssignees.length,
                                    itemBuilder: (context, index) {
                                      final user = _filteredAssignees[index];
                                      final id = user['id'] as int? ?? 0;
                                      final name = user['name']?.toString() ?? 'User';
                                      final initials = user['initials']?.toString() ?? 'US';
                                      final isSelected = _selectedAssigneeIds.contains(id);

                                      return Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          leading: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: _parseAvatarColor(user['avatar_color']?.toString()),
                                            child: Text(
                                              initials,
                                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          title: Text(name, style: const TextStyle(fontSize: 11)),
                                          selected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedAssigneeIds.remove(id);
                                              } else {
                                                _selectedAssigneeIds.add(id);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Right Selected Card with Scrolling
                              Expanded(
                                child: Container(
                                  height: 160,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SELECTED (${_selectedAssigneeIds.length})',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 6),
                                      Expanded(
                                        child: _selectedAssigneeIds.isEmpty
                                            ? Center(
                                                child: Text(
                                                  s.pickUsersFromLeft,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              )
                                            : SingleChildScrollView(
                                                physics: const AlwaysScrollableScrollPhysics(),
                                                child: Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: _selectedAssigneeIds.map((id) {
                                                    final match = _assignees.firstWhere((a) => a['id'] == id, orElse: () => {'name': 'User #$id'});
                                                    return Chip(
                                                      visualDensity: VisualDensity.compact,
                                                      padding: const EdgeInsets.all(2),
                                                      label: Text(match['name']?.toString() ?? '$id', style: const TextStyle(fontSize: 9)),
                                                      deleteIcon: const Icon(Icons.close, size: 10),
                                                      onDeleted: () {
                                                        setState(() => _selectedAssigneeIds.remove(id));
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Attachments Section
                          const Text('Attachments (image, video, document — any file)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                ),
                                icon: const Icon(Icons.attach_file, size: 15),
                                label: const Text('Add files', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: _showUploadFileDialog,
                              ),
                              ..._attachments.map((att) {
                                final fname = att['filename']?.toString() ?? 'File';
                                final ext = fname.contains('.') ? fname.split('.').last.toLowerCase() : '';
                                final size = att['size'] is int ? att['size'] as int : 0;
                                final sizeText = _formatFileSize(size);

                                IconData iconData = Icons.insert_drive_file_rounded;
                                Color iconColor = Colors.blue;
                                if (ext == 'pdf') {
                                  iconData = Icons.picture_as_pdf_rounded;
                                  iconColor = Colors.red;
                                } else if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
                                  iconData = Icons.image_rounded;
                                  iconColor = Colors.blue;
                                } else if (['doc', 'docx', 'txt'].contains(ext)) {
                                  iconData = Icons.description_rounded;
                                  iconColor = Colors.indigo;
                                } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
                                  iconData = Icons.table_chart_rounded;
                                  iconColor = Colors.green;
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(iconData, color: iconColor, size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        sizeText.isNotEmpty ? '$fname ($sizeText)' : fname,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => _attachments.remove(att));
                                        },
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // TO-DO Checklist Section
                          const Text('TO-DO Checklist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _checklistController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _buildInputDecoration(
                                    context,
                                    hintText: s.addChecklistItemHint,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                ),
                                onPressed: () {
                                  final text = _checklistController.text.trim();
                                  if (text.isNotEmpty) {
                                    setState(() {
                                      _checklistItems.add({
                                        'text': text,
                                        'done': false,
                                        'sort': _checklistItems.length,
                                      });
                                      _checklistController.clear();
                                    });
                                  }
                                },
                                child: const Text('+ Add item', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          if (_checklistItems.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Column(
                              children: _checklistItems.map((item) {
                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: const Icon(Icons.check_box_outline_blank, size: 18),
                                  title: Text(item['text']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() => _checklistItems.remove(item));
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Remarks Section with Light Grey Placeholder
                          const Text('Remarks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _remarksController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                            decoration: _buildInputDecoration(
                              context,
                              hintText: s.anyAdditionalRemarksPlaceholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),

                // Bottom Action Buttons: Cancel, Save Draft, and Save Task
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                        side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      ),
                      onPressed: () {
                        _autoSaveDebounceTimer?.cancel();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        s.cancelButton,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Save Draft Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        foregroundColor: const Color(0xFF0F766E),
                      ),
                      icon: const Icon(Icons.bookmark_outline_rounded, size: 16),
                      label: Text(
                        s.saveDraftButton,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _saveDraft,
                    ),
                    const SizedBox(width: 6),
                    // Save Task Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        _isSaving ? 'Saving...' : s.saveTaskButton,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isSaving ? null : _submitTask,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedDraftBanner(BuildContext context, TaskDraftModel draft, bool isDark) {
    final s = AppStrings.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Text(
                s.savedDraftsBannerTitle(_availableDrafts.length),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              InkWell(
                onTap: () => _loadDraftData(draft),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.subdirectory_arrow_right_rounded,
                          size: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      const SizedBox(width: 4),
                      Text(
                        s.resumeButton,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  draft.label.trim().isNotEmpty
                      ? draft.label.trim()
                      : (draft.payload.title.trim().isNotEmpty ? draft.payload.title.trim() : 'Saved Task Draft'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (draft.formattedDisplayDate.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  draft.formattedDisplayDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              InkWell(
                onTap: () => setState(() => _isDismissedDraftBanner = true),
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String key, String label, Color chipColor) {
    final isSelected = _selectedPriority == key;
    return ChoiceChip(
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        color: isSelected ? Colors.white : chipColor,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: chipColor,
      backgroundColor: chipColor.withValues(alpha: 0.12),
      onSelected: (val) {
        setState(() => _selectedPriority = key);
        _onFieldChanged();
      },
    );
  }
}
