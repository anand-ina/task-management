import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/dio_client.dart';
import '../../modules/dashboard/models/branch_model.dart';
import '../../modules/tasks/models/lookup_models.dart';
import '../../modules/tasks/repository/all_tasks_repository.dart';

class NewRecurringTaskDialog extends StatefulWidget {
  const NewRecurringTaskDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const NewRecurringTaskDialog(),
    );
  }

  @override
  State<NewRecurringTaskDialog> createState() => _NewRecurringTaskDialogState();
}

class _NewRecurringTaskDialogState extends State<NewRecurringTaskDialog> {
  final AllTasksRepository _repository = AllTasksRepository();
  bool _isLoading = true;
  String? _errorMessage;

  List<BranchModel> _branches = [];
  List<LookupAssigneeModel> _assignees = [];

  BranchModel? _selectedBranch;
  String _selectedFrequency = 'Daily';
  String _assignedBy = 'Vamsi';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();

  final Set<LookupAssigneeModel> _selectedUsers = {};
  String _userSearchQuery = '';
  bool _isCreating = false;

  Future<void> _submitRecurringTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Title * is required')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final hourStr = _selectedTime.hour.toString().padLeft(2, '0');
      final minStr = _selectedTime.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minStr';

      final assignee = _selectedUsers.isNotEmpty ? _selectedUsers.first : null;

      final payload = {
        'title': title,
        'branchId': _selectedBranch?.id ?? 1,
        'frequency': _selectedFrequency.toLowerCase(),
        'recurTime': timeStr,
        'weekday': 1,
        'monthday': 1,
        'assigneeId': assignee?.id ?? 30,
        'assigneeText': assignee?.name ?? 'test_TL',
        'remarks': _remarksController.text.isNotEmpty ? _remarksController.text : 'no',
      };

      await DioClient().dio.post(
        '${ApiConstants.baseUrl}/recurring',
        data: payload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recurring task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create recurring task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final data = await _repository.getRecurringLookups();
      if (mounted) {
        setState(() {
          _branches = data.branches;
          _assignees = data.assignees;
          _selectedBranch = _branches.isNotEmpty ? _branches.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header with Close Icon
            Row(
              children: [
                const Icon(Icons.autorenew_rounded, color: Color(0xFF0F172A), size: 20),
                const SizedBox(width: 8),
                Text(
                  'New Recurring Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Failed to load options: $_errorMessage', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loadLookups, child: Text(s.retryButton)),
                  ],
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title *
                      _buildFieldLabel('Task Title *'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Prepare admissions data sheet',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 14),

                      // Assigned By & School Branch Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Assigned By'),
                                const SizedBox(height: 4),
                                TextField(
                                  onChanged: (val) => _assignedBy = val,
                                  controller: TextEditingController(text: _assignedBy),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('School Branch'),
                                const SizedBox(height: 4),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<BranchModel>(
                                      value: _selectedBranch,
                                      isExpanded: true,
                                      items: _branches.map((b) {
                                        return DropdownMenuItem(
                                          value: b,
                                          child: Text(b.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedBranch = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Frequency & Time Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Frequency'),
                                const SizedBox(height: 4),
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedFrequency,
                                      isExpanded: true,
                                      items: ['Daily', 'Weekly', 'Monthly', 'Bi-Monthly', 'Quarterly', 'Half-Yearly', 'Yearly'].map((f) {
                                        return DropdownMenuItem(
                                          value: f,
                                          child: Text(f, style: const TextStyle(fontSize: 12)),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => _selectedFrequency = val ?? 'Daily'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Time'),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                                    if (picked != null) {
                                      setState(() => _selectedTime = picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(_selectedTime.format(context), style: const TextStyle(fontSize: 12)),
                                        const Spacer(),
                                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Assigned To Section
                      _buildFieldLabel('Assigned To'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _userSearchController,
                        onChanged: (val) => setState(() => _userSearchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),

                      // Groups Chips
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildGroupChip('Administration', 25),
                          _buildGroupChip('Admission Counselling', 1),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Dual List Picker Layout (Available Users vs Selected Users)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left List: Available Users
                          Expanded(
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _buildAvailableUsersList(isDark),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Right List: SELECTED (Count)
                          Expanded(
                            child: Container(
                              height: 180,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SELECTED (${_selectedUsers.length})',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _selectedUsers.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Pick users or a group from the left',
                                              style: TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: _selectedUsers.length,
                                            itemBuilder: (context, index) {
                                              final user = _selectedUsers.elementAt(index);
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 10,
                                                      backgroundColor: _hexToColor(user.avatarColor),
                                                      child: Text(
                                                        user.initials,
                                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(user.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        setState(() => _selectedUsers.remove(user));
                                                      },
                                                      icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Remarks
                      _buildFieldLabel('Remarks'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Any additional remarks (optional)...',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      // Footer Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(s.cancelButton),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isCreating ? null : _submitRecurringTask,
                            icon: _isCreating
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_rounded, size: 14),
                            label: const Text('Create Recurring'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildGroupChip(String groupName, int count) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 12, color: Color(0xFF2563EB)),
      label: Text(
        '$groupName ($count)',
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
      ),
      backgroundColor: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
      ),
      onPressed: () {
        setState(() {
          final groupUsers = _assignees.where((a) => a.department.toLowerCase().contains(groupName.toLowerCase()));
          _selectedUsers.addAll(groupUsers);
        });
      },
    );
  }

  Widget _buildAvailableUsersList(bool isDark) {
    final filtered = _assignees.where((a) {
      if (_userSearchQuery.isEmpty) return true;
      return a.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          a.department.toLowerCase().contains(_userSearchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No matching users', style: TextStyle(fontSize: 11, color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        final isSelected = _selectedUsers.contains(user);

        return ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: CircleAvatar(
            radius: 11,
            backgroundColor: _hexToColor(user.avatarColor),
            child: Text(
              user.initials,
              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            user.name,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          trailing: isSelected ? const Icon(Icons.check_circle, size: 16, color: Color(0xFF2563EB)) : null,
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedUsers.remove(user);
              } else {
                _selectedUsers.add(user);
              }
            });
          },
        );
      },
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return const Color(0xFFD98A04);
    try {
      String cleanHex = hex.replaceAll('#', '').replaceAll('0x', '').trim();
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFFD98A04);
    }
  }
}
