import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../modules/approvals/bloc/approvals_bloc.dart';
import '../../modules/approvals/bloc/approvals_event.dart';
import '../../modules/approvals/models/indent_model.dart';
import '../../modules/approvals/repository/approvals_repository.dart';
import 'no_internet_dialog.dart';

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
      NoInternetDialog.show(context);
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

        widget.onCreated?.call();

        try {
          context.read<ApprovalsBloc>().add(FetchBudgetApprovalsDataEvent());
        } catch (_) {}

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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

                        // Line items table header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  s.descriptionColumn,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 55,
                                child: Text(
                                  s.qtyColumn,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  s.unitPriceColumn,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 75,
                                child: Text(
                                  s.amountColumn,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Line items list
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final qty = int.tryParse(item.qtyController.text.trim()) ?? 0;
                            final unit = double.tryParse(item.unitPriceController.text.trim()) ?? 0.0;
                            final amount = qty * unit;

                            return Row(
                              children: [
                                // Description
                                Expanded(
                                  flex: 5,
                                  child: TextFormField(
                                    controller: item.descriptionController,
                                    decoration: InputDecoration(
                                      hintText: s.itemHint,
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Qty
                                SizedBox(
                                  width: 55,
                                  child: TextFormField(
                                    controller: item.qtyController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Unit Price
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: item.unitPriceController,
                                    textAlign: TextAlign.center,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Amount
                                SizedBox(
                                  width: 75,
                                  child: Text(
                                    '₹${amount.toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: headerTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Delete Button
                                SizedBox(
                                  width: 28,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: _items.length > 1
                                          ? (isDark ? Colors.white60 : Colors.black45)
                                          : Colors.transparent,
                                    ),
                                    onPressed: _items.length > 1 ? () => _removeItem(index) : null,
                                  ),
                                ),
                              ],
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
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "You're at or above the required level — this indent will be ",
                                    ),
                                    const TextSpan(
                                      text: "auto-approved",
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: " and a voucher issued immediately.",
                                    ),
                                  ],
                                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
