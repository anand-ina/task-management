import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../modules/staff/models/staff_model.dart';

enum RemoveStaffAction { reassign, orphan }

class RemoveStaffDialog extends StatefulWidget {
  final StaffModel staff;
  final List<StaffModel> staffList;

  const RemoveStaffDialog({
    super.key,
    required this.staff,
    required this.staffList,
  });

  static Future<bool?> show(
    BuildContext context, {
    required StaffModel staff,
    required List<StaffModel> staffList,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => RemoveStaffDialog(
        staff: staff,
        staffList: staffList,
      ),
    );
  }

  @override
  State<RemoveStaffDialog> createState() => _RemoveStaffDialogState();
}

class _RemoveStaffDialogState extends State<RemoveStaffDialog> {
  RemoveStaffAction _action = RemoveStaffAction.reassign;
  int? _selectedReplacementId;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final openTasks = (widget.staff.assigned - widget.staff.done) > 0
        ? (widget.staff.assigned - widget.staff.done)
        : (widget.staff.assigned > 0 ? widget.staff.assigned : 0);

    final replacementCandidates =
        widget.staffList.where((s) => s.id != widget.staff.id).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title and Close (X) button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Remove ${widget.staff.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 16),

              // Info Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: '${widget.staff.name} has '),
                      TextSpan(
                        text: '$openTasks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const TextSpan(text: ' open task(s). What should happen to them?'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Option 1: Reassign open tasks
              GestureDetector(
                onTap: () => setState(() => _action = RemoveStaffAction.reassign),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _action == RemoveStaffAction.reassign
                        ? (isDark
                            ? const Color(0xFF7F1D1D).withOpacity(0.18)
                            : const Color(0xFFFEF2F2))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _action == RemoveStaffAction.reassign
                          ? const Color(0xFF991B1B)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: _action == RemoveStaffAction.reassign ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildRadioIndicator(_action == RemoveStaffAction.reassign, isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reassign their open tasks to a replacement',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dropdown for replacement staff (shown when reassign is selected)
              if (_action == RemoveStaffAction.reassign) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF2563EB),
                      width: 2,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedReplacementId,
                      hint: Text(
                        'Select replacement staff...',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                      items: replacementCandidates.map((s) {
                        final role = s.roleLabel.isNotEmpty
                            ? s.roleLabel
                            : (s.designation ?? s.roleName);
                        return DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(
                            '${s.name} ($role)',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedReplacementId = val),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Option 2: Keep as orphan
              GestureDetector(
                onTap: () => setState(() => _action = RemoveStaffAction.orphan),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _action == RemoveStaffAction.orphan
                        ? (isDark
                            ? const Color(0xFF7F1D1D).withOpacity(0.18)
                            : const Color(0xFFFEF2F2))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _action == RemoveStaffAction.orphan
                          ? const Color(0xFF991B1B)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      width: _action == RemoveStaffAction.orphan ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildRadioIndicator(_action == RemoveStaffAction.orphan, isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep as orphan (old name shown; reassign later)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Footer Buttons: Cancel and Remove staff
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isDeleting ? null : _onConfirmRemove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF991B1B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Remove staff',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected, bool isDark) {
    if (isSelected) {
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF991B1B), width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF991B1B),
          ),
        ),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          width: 2,
        ),
      ),
    );
  }

  Future<void> _onConfirmRemove() async {
    final openTasks = (widget.staff.assigned - widget.staff.done) > 0
        ? (widget.staff.assigned - widget.staff.done)
        : (widget.staff.assigned > 0 ? widget.staff.assigned : 0);

    if (_action == RemoveStaffAction.reassign &&
        openTasks > 0 &&
        _selectedReplacementId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a replacement staff member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final dio = DioClient().dio;
      Map<String, dynamic>? data;
      Map<String, dynamic>? queryParams;

      if (_action == RemoveStaffAction.reassign && _selectedReplacementId != null) {
        data = {
          'reassignTo': _selectedReplacementId,
          'replacementStaffId': _selectedReplacementId,
        };
        queryParams = {
          'reassignTo': _selectedReplacementId,
          'replacementStaffId': _selectedReplacementId,
        };
      }

      await dio.delete(
        '${ApiConstants.staff}/${widget.staff.id}',
        data: data,
        queryParameters: queryParams,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove staff: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
