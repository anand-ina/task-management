import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';
import '../models/announcement_model.dart';

class DeleteAnnouncementDialog extends StatelessWidget {
  final AnnouncementModel announcement;

  const DeleteAnnouncementDialog({
    super.key,
    required this.announcement,
  });

  static Future<bool> show(
    BuildContext context, {
    required AnnouncementModel announcement,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteAnnouncementDialog(announcement: announcement),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      title: Text(
        s.delete,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      content: Text(
        s.deleteAnnouncementConfirmation(announcement.title),
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white70 : const Color(0xFF334155),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            s.cancelButton,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            s.delete,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
