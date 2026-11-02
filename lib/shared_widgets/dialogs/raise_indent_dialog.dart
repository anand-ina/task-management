import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../modules/approvals/utils/indent_flow_helper.dart';
import '../../modules/approvals/models/indent_model.dart';
import '../../modules/approvals/repository/approvals_repository.dart';
import '../../core/utils/app_toast.dart';

class _LineItemRow {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: '1');
  final TextEditingController unitPriceController = TextEditingController(text: '0');

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
    unitPriceController.dispose();
  }
}

class RaiseIndentDialog extends StatefulWidget {
  final VoidCallback? onCreated;

  const RaiseIndentDialog({super.key, this.onCreated});

  static Future<void> show(BuildContext context, {VoidCallback? onCreated}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => RaiseIndentDialog(onCreated: onCreated),
    );
  }

  @override
  State<RaiseIndentDialog> createState() => _RaiseIndentDialogState();
}

class _RaiseIndentDialogState extends State<RaiseIndentDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  final List<_LineItemRow> _items = [];
  DateTime? _neededByDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _purposeController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final item = _LineItemRow();
      item.qtyController.addListener(() => setState(() {}));
      item.unitPriceController.addListener(() => setState(() {}));
      _items.add(item);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  double get _totalAmount {
    double sum = 0.0;
    for (final item in _items) {
      final qty = int.tryParse(item.qtyController.text.trim()) ?? 0;
      final unit = double.tryParse(item.unitPriceController.text.trim()) ?? 0.0;
      sum += (qty * unit);
    }
    return sum;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededByDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _neededByDate = picked;
      });
    }
  }

  Future<void> _submitIndent() async {
    if (!_formKey.currentState!.validate()) return;

    final isOnline = await NetworkConnectivityService().checkConnection();
    if (!isOnline && mounted) {
      AppToast.showInternetToast(message: 'Internet not available');
      return;
    }

    final s = AppStrings.of(context);
    final title = _titleController.text.trim();
    final purpose = _purposeController.text.trim();

    final lineItemsPayload = <Map<String, dynamic>>[];
    for (final item in _items) {
      final desc = item.descriptionController.text.trim();
      final qty = int.tryParse(item.qtyController.text.trim()) ?? 1;
      final unitPrice = double.tryParse(item.unitPriceController.text.trim()) ?? 0.0;
      final amount = qty * unitPrice;
      lineItemsPayload.add({
        'description': desc.isNotEmpty ? desc : 'Item',
        'qty': qty,
        'unitPrice': unitPrice,
        'amount': amount,
      });
    }

    final payload = <String, dynamic>{
      'title': title,
      if (purpose.isNotEmpty) 'purpose': purpose,
      if (_neededByDate != null)
        'neededBy': DateFormat('yyyy-MM-dd').format(_neededByDate!),
      'items': lineItemsPayload,
    };

    setState(() => _isSubmitting = true);

    try {
      final repo = ApprovalsRepository();
      final result = await repo.createIndent(payload);

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop();

        // The Budget Indents screen refreshes its tabs through onCreated.
        widget.onCreated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null && result.indentNo.isNotEmpty
                  ? '${s.indentCreatedSuccess} (${result.indentNo})'
                  : s.indentCreatedSuccess,
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit indent: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final headerTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyTextColor = isDark ? Colors.white70 : const Color(0xFF334155);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: bgColor,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  children: [
                    Text(
                      '₹ ${s.raisePurchaseIndent}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: headerTextColor,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: borderColor),

              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          s.indentTitleLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: headerTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: s.indentTitleHint,
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Purpose / Justification
                        Text(
                          s.purposeJustificationLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: headerTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _purposeController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: s.purposeJustificationHint,
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Line Items
                        Text(
                          s.lineItemsLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: headerTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Line items — one stacked card per item (mobile friendly, no wide table)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final qty = int.tryParse(item.qtyController.text.trim()) ?? 0;
                            final unit = double.tryParse(item.unitPriceController.text.trim()) ?? 0.0;
                            final amount = qty * unit;

                            InputDecoration deco({String? hint, String? label}) => InputDecoration(
                                  hintText: hint,
                                  labelText: label,
                                  isDense: true,
                                  labelStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textFaint(context)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                );

                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.subtleBg(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${s.descriptionColumn} ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_items.length > 1)
                                        InkWell(
                                          onTap: () => _removeItem(index),
                                          child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary(context)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: item.descriptionController,
                                    style: TextStyle(fontSize: 13, color: headerTextColor),
                                    decoration: deco(hint: s.itemHint),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: item.qtyController,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(fontSize: 13, color: headerTextColor),
                                          decoration: deco(label: s.qtyColumn),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: item.unitPriceController,
                                          textAlign: TextAlign.center,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: TextStyle(fontSize: 13, color: headerTextColor),
                                          decoration: deco(label: s.unitPriceColumn),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              s.amountColumn,
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                                            ),
                                            Text(
                                              '₹${amount.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: headerTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // + Add Item Button
                        OutlinedButton(
                          onPressed: _addItem,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            s.addItem,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: headerTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Needed by (optional)
                        Text(
                          s.neededByOptional,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: headerTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _neededByDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_neededByDate!)
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _neededByDate != null
                                        ? headerTextColor
                                        : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Total Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${s.totalLabel}  ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    '₹${_totalAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: headerTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Approval chain for this amount (same tiers as the web portal)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: 'Approval chain for ₹${_totalAmount.toStringAsFixed(0)}: '),
                                    for (final entry in IndentFlowHelper.chainFor(_totalAmount).asMap().entries) ...[
                                      TextSpan(
                                        text: entry.value.label,
                                        style: TextStyle(fontWeight: FontWeight.w700, color: headerTextColor),
                                      ),
                                      if (entry.key < IndentFlowHelper.chainFor(_totalAmount).length - 1)
                                        const TextSpan(text: ' → '),
                                    ],
                                  ],
                                ),
                                style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary(context)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                IndentFlowHelper.chainNote(_totalAmount),
                                style: TextStyle(fontSize: 11, color: AppColors.textFaint(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Divider(height: 1, thickness: 1, color: borderColor),

              // Bottom Actions: Cancel & Submit indent
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        s.cancelButton,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: headerTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitIndent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.submitIndentButton,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
