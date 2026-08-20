import 'package:flutter/material.dart';
import '../../core/localization/app_strings.dart';
import '../../modules/dashboard/models/branch_model.dart';
import '../../modules/meetings/models/availability_model.dart';
import '../../modules/meetings/repository/meetings_repository.dart';

class ScheduleOneOnOneDialog extends StatefulWidget {
  final String? initialStaffName;

  const ScheduleOneOnOneDialog({super.key, this.initialStaffName});

  static Future<void> show(BuildContext context, {String? staffName}) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ScheduleOneOnOneDialog(initialStaffName: staffName),
    );
  }

  @override
  State<ScheduleOneOnOneDialog> createState() => _ScheduleOneOnOneDialogState();
}

class _ScheduleOneOnOneDialogState extends State<ScheduleOneOnOneDialog> {
  final MeetingsRepository _repository = MeetingsRepository();
  bool _isLoading = true;
  String? _errorMessage;

  List<BranchModel> _branches = [];
  List<MeetingAvailabilityModel> _availability = [];
  BranchModel? _selectedBranch;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String _selectedDuration = '30 min';
  bool _isMandatoryOneOnOne = false;
  final TextEditingController _titleController = TextEditingController();
  final Set<int> _selectedInviteeIds = {};

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final formattedTime = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}T${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final data = await _repository.getScheduleLookups(atTime: formattedTime);
      if (mounted) {
        setState(() {
          _branches = data.branches;
          _availability = data.availability;
          _selectedBranch = _branches.isNotEmpty ? _branches.first : null;
          if (widget.initialStaffName != null) {
            for (var a in _availability) {
              if (a.name.toLowerCase() == widget.initialStaffName!.toLowerCase()) {
                _selectedInviteeIds.add(a.id);
              }
            }
          }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header & Close Button
            Row(
              children: [
                Text(
                  s.scheduleAMeetingTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loadLookups, child: Text(s.retryButton)),
                  ],
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meeting Title Field
                      Text(s.meetingTitleLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: s.meetingTitleHint,
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),

                      // Mandatory 1:1 Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _isMandatoryOneOnOne,
                              onChanged: (val) => setState(() => _isMandatoryOneOnOne = val ?? false),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.mandatoryOneOnOneDirectorLabel,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date, Time, Duration Row
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.dateLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setState(() => _selectedDate = picked);
                                      _loadLookups();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Time Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.timeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                                    if (picked != null) {
                                      setState(() => _selectedTime = picked);
                                      _loadLookups();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(_selectedTime.format(context), style: const TextStyle(fontSize: 12)),
                                        const Spacer(),
                                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Duration Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.durationLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                                      value: _selectedDuration,
                                      isExpanded: true,
                                      items: ['15 min', '30 min', '45 min', '60 min'].map((d) {
                                        return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedDuration = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Branch Dropdown
                      Text(s.branchLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                            hint: const Text('—', style: TextStyle(fontSize: 12)),
                            items: _branches.map((b) {
                              return DropdownMenuItem(
                                value: b,
                                child: Text(b.name, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedBranch = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Invitees & Availability Section
                      Text(
                        s.inviteesAvailabilityHeader,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _availability.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final item = _availability[index];
                            final isSelected = _selectedInviteeIds.contains(item.id);
                            final isFree = item.status.toLowerCase() == 'free';

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedInviteeIds.add(item.id);
                                          } else {
                                            _selectedInviteeIds.remove(item.id);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: _hexToColor(item.avatarColor),
                                    child: Text(
                                      item.initials,
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isFree ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isFree ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isFree ? s.freeStatus : s.busyStatus,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isFree ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
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
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(s.cancelButton),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Meeting request sent successfully!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B132B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(s.sendRequestButton, style: const TextStyle(fontWeight: FontWeight.bold)),
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
