import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';

class IssueFineRewardDialog extends StatefulWidget {
  const IssueFineRewardDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const IssueFineRewardDialog(),
    );
  }

  @override
  State<IssueFineRewardDialog> createState() => _IssueFineRewardDialogState();
}

class _IssueFineRewardDialogState extends State<IssueFineRewardDialog> {
  final DioClient _dioClient = DioClient();
  bool _isReward = true; // true = Reward, false = Fine
  List<Map<String, dynamic>> _assignees = [];
  int? _selectedAssigneeId;
  final TextEditingController _pointsController = TextEditingController(text: '50');
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignees();
  }

  Future<void> _fetchAssignees() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.assignees);
      dynamic data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is List) {
        setState(() {
          _assignees = List<Map<String, dynamic>>.from(data.whereType<Map<String, dynamic>>());
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Issue Fine / Reward',
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
              const SizedBox(height: 16),

              // Type Toggle
              const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => _isReward = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isReward ? const Color(0xFF1E3A8A) : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆 ', style: TextStyle(fontSize: 13)),
                          Text(
                            'Reward',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isReward ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => setState(() => _isReward = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isReward ? const Color(0xFF991B1B) : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('₹ ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(
                            'Fine',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !_isReward ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Team Member Dropdown
              const Text('Team member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _isLoading
                  ? const LinearProgressIndicator()
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedAssigneeId,
                          hint: const Text('Select...', style: TextStyle(fontSize: 13)),
                          items: _assignees.map((a) {
                            return DropdownMenuItem<int>(
                              value: a['id'] as int,
                              child: Text(a['name'] as String? ?? 'Member', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAssigneeId = val),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),

              // Points Field
              const Text('Points', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),

              // Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip('Early completion · ₹50.00', '50'),
                    const SizedBox(width: 6),
                    _buildChip('Top performer · ₹150.00', '150'),
                    const SizedBox(width: 6),
                    _buildChip('Zero overdue (month) · ₹200.00', '200'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason Field
              const Text('Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(s.cancelButton),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Issue', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _pointsController.text = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
      ),
    );
  }
}
