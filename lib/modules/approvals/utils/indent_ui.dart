import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'indent_flow_helper.dart';

/// Small formatting / colour helpers shared by the Budget Indents screen and dialogs.
class IndentUi {
  IndentUi._();

  static final NumberFormat _inr = NumberFormat.decimalPattern('en_IN');

  static String money(num? value) {
    final v = (value ?? 0).toDouble();
    final hasFraction = v != v.roundToDouble();
    return '₹${hasFraction ? _inr.format(double.parse(v.toStringAsFixed(2))) : _inr.format(v.round())}';
  }

  static String dateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM, HH:mm').format(dt.toLocal());
  }

  static String date(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy').format(dt.toLocal());
  }

  static IndentTone toneForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return IndentTone.approved;
      case 'rejected':
        return IndentTone.rejected;
      case 'pending':
        return IndentTone.pending;
      default:
        return IndentTone.muted;
    }
  }

  static Color fg(BuildContext context, IndentTone tone) {
    switch (tone) {
      case IndentTone.approved:
        return AppColors.badgeGreenFg(context);
      case IndentTone.rejected:
        return AppColors.badgeRedFg(context);
      case IndentTone.pending:
        return AppColors.badgeYellowFg(context);
      case IndentTone.muted:
        return AppColors.textFaint(context);
    }
  }

  static Color bg(BuildContext context, IndentTone tone) {
    switch (tone) {
      case IndentTone.approved:
        return AppColors.badgeGreenBg(context);
      case IndentTone.rejected:
        return AppColors.badgeRedBg(context);
      case IndentTone.pending:
        return AppColors.badgeYellowBg(context);
      case IndentTone.muted:
        return AppColors.chipBg(context);
    }
  }

  static String capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static Widget pill(BuildContext context, String text, {required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
