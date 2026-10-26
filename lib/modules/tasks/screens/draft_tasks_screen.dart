import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/create_task_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../dashboard/models/branch_model.dart';
import '../models/task_draft_model.dart';
import '../repository/task_repository.dart';

class DraftTasksScreen extends StatefulWidget {
  const DraftTasksScreen({super.key});

  @override
  State<DraftTasksScreen> createState() => _DraftTasksScreenState();
}

class _DraftTasksScreenState extends State<DraftTasksScreen> {
  final TaskRepository _repository = TaskRepository();
  final DioClient _dioClient = DioClient();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<TaskDraftModel> _drafts = [];
  List<TaskDraftModel> _filteredDrafts = [];
  Map<int, BranchModel> _branchesMap = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDrafts = List.from(_drafts);
      } else {
        _filteredDrafts = _drafts.where((d) {
          final title = (d.payload.title.isNotEmpty ? d.payload.title : d.label).toLowerCase();
          final desc = d.payload.description.toLowerCase();
          final assignees = d.payload.assigneeNames.join(' ').toLowerCase();
          return title.contains(query) || desc.contains(query) || assignees.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _fetchDrafts().catchError((e) {
          debugPrint('[DraftTasksScreen] Drafts error: $e');
        }),
        _fetchBranches().catchError((e) {
          debugPrint('[DraftTasksScreen] Branches error: $e');
        }),
      ]);
    } catch (e) {
      debugPrint('[DraftTasksScreen] Load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDrafts() async {
    try {
      final list = await _repository.getTaskDrafts();
      if (mounted) {
        setState(() {
          _drafts = list;
          _onSearchChanged();
        });
      }
    } catch (e) {
      debugPrint('[DraftTasksScreen] Error loading drafts: $e');
      if (mounted) {
        setState(() {
          _drafts = [];
          _filteredDrafts = [];
        });
      }
    }
  }

  Future<void> _fetchBranches() async {
    const url = ApiConstants.branches;
    debugPrint('==================== API REQUEST ====================');
    debugPrint('URL: [GET] $url');
    debugPrint('=====================================================');

    try {
      final response = await _dioClient.dio.get(url);

      debugPrint('==================== API RESPONSE ====================');
      debugPrint('URL: [GET] $url');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      debugPrint('======================================================');

      dynamic rawData = response.data;
      if (rawData is String) {
        try {
          rawData = jsonDecode(rawData);
        } catch (_) {}
      }

      final Map<int, BranchModel> map = {};
      if (rawData is List) {
        for (final item in rawData) {
          try {
            if (item is Map<String, dynamic>) {
              final branch = BranchModel.fromJson(item);
              map[branch.id] = branch;
            } else if (item is Map) {
              final branch = BranchModel.fromJson(Map<String, dynamic>.from(item));
              map[branch.id] = branch;
            }
          } catch (_) {}
        }
      }
      if (mounted) {
        setState(() {
          _branchesMap = map;
        });
      }
    } catch (e) {
      debugPrint('[DraftTasksScreen] Error loading branches: $e');
    }
  }

  Future<void> _discardDraft(TaskDraftModel draft) async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.slate800 : Colors.white,
          title: Text(
            s.discardDraftConfirmTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          content: Text(
            s.discardDraftConfirmMessage,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.slate300 : AppColors.slate600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                MaterialLocalizations.of(dialogCtx).cancelButtonLabel,
                style: TextStyle(color: isDark ? AppColors.slate400 : AppColors.slate600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(s.discardDraftButton),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final ok = await _repository.deleteTaskDraft(draft.id);
        if (ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${s.discardDraftButton} successful'),
              backgroundColor: AppColors.red600,
            ),
          );
          _loadInitialData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to discard draft: $e'),
              backgroundColor: AppColors.red600,
            ),
          );
        }
      }
    }
  }

  Widget _buildPriorityBadge(String priority) {
    final pLower = priority.toLowerCase();
    String label = 'High ★★★';
    Color textColor = AppColors.amber700;
    Color bgColor = AppColors.yellow200;

    if (pLower.contains('emergency')) {
      label = 'Emergency ★★★★';
      textColor = AppColors.red700;
      bgColor = AppColors.red100;
    } else if (pLower.contains('top') || pLower.contains('top_most')) {
      label = 'Top Most ★★★★';
      textColor = AppColors.red600;
      bgColor = AppColors.red50;
    } else if (pLower.contains('medium')) {
      label = 'Medium ★★';
      textColor = AppColors.blue700;
      bgColor = AppColors.blue50;
    } else if (pLower.contains('low')) {
      label = 'Low ★';
      textColor = AppColors.slate600;
      bgColor = AppColors.slate100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatSavedTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTargetDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No due date';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const CustomLeftDrawer(currentRoute: '/drafts'),
      appBar: const CustomAppBar(),
      body: AnnouncementBannerWrapper(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadInitialData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Title, Count badge, Subtitle & "+ New Task" button
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isSmall = constraints.maxWidth < 600;
                              final titleRow = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.draftTasksTitle,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal:10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                                      ),
                                    ),
                                    child: Text(
                                      s.draftsCountBadge(_drafts.length),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                                      ),
                                    ),
                                  ),
                                ],
                              );

                              final newBtn = ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                 label: Text(
                                  ' ${s.createNewTaskTitle}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                onPressed: () {
                                  CreateTaskDialog.show(context).then((_) => _loadInitialData());
                                },
                              );

                              if (isSmall) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        titleRow,
                                        newBtn,
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.draftsSubtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        titleRow,
                                        const SizedBox(height: 6),
                                        Text(
                                          s.draftsSubtitle,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? AppColors.slate400 : AppColors.slate500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  newBtn,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 18),

                          // Auto-Draft Protection Callout Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: s.autoDraftProtectionTitle,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: s.autoDraftProtectionSubtitle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Search Bar & Count Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final searchField = SizedBox(
                                width: constraints.maxWidth < 600 ? double.infinity : 360,
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : AppColors.slate900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: s.searchDraftsPlaceholder,
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.slate400 : AppColors.slate400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      size: 18,
                                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    filled: true,
                                    fillColor: isDark ? AppColors.slate800 : Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                  ),
                                ),
                              );

                              final countText = Text(
                                'Showing ${_filteredDrafts.length} of ${_drafts.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                                ),
                              );

                              if (constraints.maxWidth < 600) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    searchField,
                                    const SizedBox(height: 10),
                                    countText,
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  searchField,
                                  countText,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Draft Cards List
                          if (_filteredDrafts.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.slate800 : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? AppColors.slate700 : AppColors.slate200,
                                ),
                              ),
                              child: Text(
                                s.noDraftsAvailable,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredDrafts.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final draft = _filteredDrafts[index];
                                return _buildDraftCard(context, draft, isDark);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, TaskDraftModel draft, bool isDark) {
    final s = AppStrings.of(context);
    final p = draft.payload;
    final titleText = p.title.isNotEmpty ? p.title : (draft.label.isNotEmpty ? draft.label : 'Untitled Draft');
    final descText = p.description;

    // Branch code & name resolution
    String branchLabel = '';
    if (p.branchId != null && _branchesMap.containsKey(p.branchId)) {
      final b = _branchesMap[p.branchId]!;
      branchLabel = '${b.code} - ${b.name}';
    } else if (p.branchId != null) {
      branchLabel = 'Branch #${p.branchId}';
    }

    // Assignees resolution
    String assigneesLabel = s.noAssigneesChosen;
    if (p.assigneeNames.isNotEmpty) {
      assigneesLabel = p.assigneeNames.join(', ');
    } else if (p.assigneeIds.isNotEmpty) {
      assigneesLabel = '${p.assigneeIds.length} assignee(s)';
    }

    final savedTimeStr = _formatSavedTime(draft.updatedAt ?? draft.createdAt);
    final targetDateStr = _formatTargetDate(p.dueDate);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row: Draft status, Category, and Priority
          Row(
            children: [
              // Badge 1: Draft - No Task ID Assigned
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Text(
                      s.draftNoTaskIdAssigned,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),

              // Badge 2: Category
              if (p.category.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate700 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? AppColors.slate600 : AppColors.slate200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏷️', style: TextStyle(fontSize: 9)),
                      const SizedBox(width: 2),
                      Text(
                        p.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.slate200 : AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
              _buildPriorityBadge(p.priority),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            titleText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),

          // Description
          if (descText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              descText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Meta Info Row (Target, Assignees, Branch)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Target Date
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                  const SizedBox(width: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                      ),
                      children: [
                        TextSpan(
                          text: '${s.targetPrefix}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: targetDateStr),
                      ],
                    ),
                  ),
                ],
              ),

              // Assignees
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    assigneesLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                    ),
                  ),
                ],
              ),

              // Branch
              if (branchLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate700 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏫', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Text(
                        branchLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.slate300 : AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Divider
          Divider(
            height: 1,
            color: isDark ? AppColors.slate700 : AppColors.slate200,
          ),
          const SizedBox(height: 12),

          // Footer Row: Saved timestamp & Action buttons
          Row(
            children: [
              // Saved Time
              if (savedTimeStr.isNotEmpty) ...[
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: isDark ? AppColors.slate400 : AppColors.slate400,
                ),
                const SizedBox(width: 3),
                Text(
                  '${s.savedPrefix} $savedTimeStr',
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ),
              ],

              // Discard Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red600,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: isDark
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                      : const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 10, color: Color(0xFFDC2626)),
                label: Text(
                  s.discardDraftButton,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
                onPressed: () => _discardDraft(draft),
              ),
SizedBox(width: 5,),
              // Resume & Create Task Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  CreateTaskDialog.show(context, initialDraft: draft).then((_) {
                    _loadInitialData();
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.resumeAndCreateTaskButton,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
