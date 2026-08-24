import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class ScheduleMeetingDialog extends StatefulWidget {
  const ScheduleMeetingDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ScheduleMeetingDialog(),
    );
  }

  @override
  State<ScheduleMeetingDialog> createState() => _ScheduleMeetingDialogState();
}

class _ScheduleMeetingDialogState extends State<ScheduleMeetingDialog> {
  final DioClient _dioClient = DioClient();
  bool _isLoading = true;
  bool _isSaving = false;

  List<dynamic> _branches = [];
  List<dynamic> _invitees = [];
  int? _selectedBranchId;

  bool _isMandatory1on1 = false;
  String _selectedDuration = '30 min';
  String _selectedLocation = 'In person';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);

  // Map of userId -> required (true for Mandatory, false for Optional)
  final Map<int, bool> _selectedInvitees = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _agendaController.dispose();
    super.dispose();
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

  Future<void> _loadData() async {
    try {
      final branchesRes = await _dioClient.dio.get(ApiConstants.branches);

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final availabilityUrl = '${ApiConstants.meetingsAvailability}?at=${formattedDate}T$formattedTime';

      final availRes = await _dioClient.dio.get(availabilityUrl);

      final branchesData = _safeParse(branchesRes.data);
      final availData = _safeParse(availRes.data);

      if (mounted) {
        setState(() {
          if (branchesData is List) _branches = branchesData;
          if (_branches.isNotEmpty) {
            _selectedBranchId = _branches.first['id'] as int? ?? 1;
          }
          if (availData is List) {
            _invitees = availData;
            // Pre-select first 2 as default
            for (int i = 0; i < _invitees.length; i++) {
              final id = _invitees[i]['id'] as int? ?? 0;
              if (i < 2) _selectedInvitees[id] = true;
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitMeeting() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final endsAtStr = '${dateStr}T$timeStr';

      final inviteesList = _selectedInvitees.entries.map((e) {
        return {
          'userId': e.key,
          'required': e.value,
        };
      }).toList();

      final payload = {
        'title': title,
        'date': dateStr,
        'time': timeStr,
        'endsAt': endsAtStr,
        'branchId': _selectedBranchId ?? 1,
        'agenda': _agendaController.text.trim().isNotEmpty ? _agendaController.text.trim() : 'test',
        'location': _selectedLocation,
        'isOneOnOne': _isMandatory1on1,
        'invitees': inviteesList.isNotEmpty ? inviteesList : [{'userId': 6, 'required': true}, {'userId': 10, 'required': true}],
      };

      await _dioClient.dio.post(ApiConstants.meetings, data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule meeting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            // Title Header with Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Schedule a Meeting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      const Text('Title', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'e.g., Fee reconciliation review',
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mandatory 1:1 Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 22,
                            width: 22,
                            child: Checkbox(
                              value: _isMandatory1on1,
                              activeColor: const Color(0xFF0F172A),
                              onChanged: (val) => setState(() => _isMandatory1on1 = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                ),
                                children: const [
                                  TextSpan(text: 'Mandatory '),
                                  TextSpan(
                                    text: 'monthly 1:1 with the Director',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: ' — the Director is added automatically; mark it completed once done.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Date, Time, Duration Row
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _selectedDate = picked);
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
                                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _selectedTime,
                                    );
                                    if (picked != null) setState(() => _selectedTime = picked);
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
                                          _selectedTime.format(context),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Duration', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedDuration,
                                  isDense: true,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                  ),
                                  items: ['15 min', '30 min', '45 min', '60 min'].map((d) {
                                    return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 11)));
                                  }).toList(),
                                  onChanged: (val) => setState(() => _selectedDuration = val ?? '30 min'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Branch Dropdown
                      const Text('Branch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedBranchId,
                        isDense: true,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        items: _branches.map((b) {
                          final id = b['id'] as int? ?? 1;
                          final name = b['name']?.toString() ?? 'Head Office';
                          return DropdownMenuItem<int>(value: id, child: Text(name, style: const TextStyle(fontSize: 11)));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedBranchId = val),
                      ),
                      const SizedBox(height: 12),

                      // Invitees & Availability Section (Matching Image 1)
                      const Text(
                        'Invitees & availability — set each as mandatory or optional',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          itemCount: _invitees.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final inv = _invitees[index];
                            final id = inv['id'] as int? ?? 0;
                            final name = inv['name']?.toString() ?? 'User';
                            final initials = inv['initials']?.toString() ?? 'US';
                            final avatarColor = _parseAvatarColor(inv['avatar_color']?.toString());
                            final status = inv['status']?.toString() ?? 'free';

                            final isSelected = _selectedInvitees.containsKey(id);
                            final isRequired = _selectedInvitees[id] ?? true;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFF0F172A),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedInvitees[id] = true;
                                          } else {
                                            _selectedInvitees.remove(id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: avatarColor,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                  // Mandatory / Optional Segmented Buttons
                                  if (isSelected)
                                    Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => setState(() => _selectedInvitees[id] = true),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isRequired ? const Color(0xFF0F172A) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Mandatory',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isRequired ? Colors.white : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() => _selectedInvitees[id] = false),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: !isRequired ? const Color(0xFF0F172A) : Colors.transparent,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Optional',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: !isRequired ? Colors.white : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),

                                  // Free Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status == 'free' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(status == 'free' ? '🟢 ' : '🔴 ', style: const TextStyle(fontSize: 8)),
                                        Text(
                                          status == 'free' ? 'Free' : 'Busy',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'free' ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Agenda Text Area
                      const Text('Agenda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _agendaController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Enter agenda...',
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location Toggle (In person vs Online)
                      const Text('Location', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            label: const Text('In person', style: TextStyle(fontSize: 11)),
                            selected: _selectedLocation == 'In person',
                            selectedColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: _selectedLocation == 'In person' ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            ),
                            onSelected: (val) => setState(() => _selectedLocation = 'In person'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            visualDensity: VisualDensity.compact,
                            label: const Text('Online', style: TextStyle(fontSize: 11)),
                            selected: _selectedLocation == 'Online',
                            selectedColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: _selectedLocation == 'Online' ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            ),
                            onSelected: (val) => setState(() => _selectedLocation = 'Online'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isSaving ? null : _submitMeeting,
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
