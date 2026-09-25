import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_strings.dart';
import '../../modules/approvals/models/indent_model.dart';
import '../../modules/approvals/repository/approvals_repository.dart';

class IndentDetailDialog extends StatefulWidget {
  final int indentId;
  final IndentItemModel? initialIndent;

  const IndentDetailDialog({
    super.key,
    required this.indentId,
    this.initialIndent,
  });

  static Future<void> show(
    BuildContext context, {
    required int indentId,
    IndentItemModel? initialIndent,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => IndentDetailDialog(
        indentId: indentId,
        initialIndent: initialIndent,
      ),
    );
  }

  @override
  State<IndentDetailDialog> createState() => _IndentDetailDialogState();
}

class _IndentDetailDialogState extends State<IndentDetailDialog> {
  final ApprovalsRepository _repository = ApprovalsRepository();
  bool _isLoading = true;
  IndentItemModel? _indent;

  @override
  void initState() {
    super.initState();
    _indent = widget.initialIndent;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final detail = await _repository.getIndentDetail(widget.indentId);
    if (mounted) {
      setState(() {
        if (detail != null) {
          _indent = detail;
        }
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _printVoucherPdf(IndentItemModel indent) async {
    final pdf = pw.Document();

    // Load Samskar banner image
    Uint8List? bannerImageBytes;
    try {
      final byteData = await rootBundle.load('assets/images/banner.png');
      bannerImageBytes = byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to load banner.png for PDF: $e');
    }

    final currencySymbol = indent.currency == 'INR' ? 'Rs.' : indent.currency;
    final totalAmountStr = indent.amount.toStringAsFixed(2);
    final voucherNoStr = indent.voucherNo ?? 'VCH-2026-0001';
    final indentNoStr = indent.indentNo.isNotEmpty ? indent.indentNo : 'IND-2026-0001';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Top Header Card with banner and voucher numbers
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (bannerImageBytes != null)
                      pw.Image(
                        pw.MemoryImage(bannerImageBytes),
                        width: 170,
                        height: 50,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SAMSKAR',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#0F1E36'),
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'THE LIFE SCHOOL',
                            style: const pw.TextStyle(
                              color: PdfColors.grey700,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#0E7490'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'PURCHASE INDENT VOUCHER',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'VOUCHER NO: $voucherNoStr',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#0F1E36'),
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'INDENT NO: $indentNoStr',
                          style: const pw.TextStyle(
                            color: PdfColors.grey700,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),
              pw.Container(height: 3, color: PdfColor.fromHex('#D97706')),
              pw.SizedBox(height: 16),

              // VOUCHER DETAILS HEADER
              pw.Text(
                'VOUCHER DETAILS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0E7490'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Title
              pw.Text(
                'TITLE',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
              pw.Text(
                indent.title,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // 2-column info grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RAISED BY', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(indent.raisedBy ?? 'Swapnika', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text('BRANCH', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(indent.branchName ?? 'Moti Nagar & Sanath Nagar', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text('NEEDED BY', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(_formatDate(indent.neededBy), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DEPARTMENT', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(indent.departmentName ?? 'Admission Counselling', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 8),
                        pw.Text('RAISED ON', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.Text(_formatDate(indent.createdAt), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Purpose
              if (indent.purpose != null && indent.purpose!.isNotEmpty) ...[
                pw.Text('PURPOSE', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                pw.Text(indent.purpose!, style: const pw.TextStyle(fontSize: 9.5)),
                pw.SizedBox(height: 14),
              ],

              // ITEMS TABLE
              pw.Text(
                'ITEMS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0E7490'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 6),

              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(6),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(2.5),
                  4: const pw.FlexColumnWidth(2.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('#', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('DESCRIPTION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('QTY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('UNIT PRICE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  for (int i = 0; i < indent.items.length; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(indent.items[i].description, style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${indent.items[i].qty}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$currencySymbol ${indent.items[i].unitPrice.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$currencySymbol ${indent.items[i].amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Grand Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$currencySymbol $totalAmountStr', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#15803D')), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // APPROVALS SECTION
              pw.Text(
                'APPROVALS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0E7490'),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (final step in indent.steps)
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              step.approverLevel == 4 ? 'CENTRE HEAD' : (step.approverLevel == 5 ? 'DIRECTOR' : 'APPROVER (L${step.approverLevel})'),
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              step.decidedBy ?? 'Approver',
                              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              _formatDateTime(step.decidedAt),
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                            ),
                            if (step.comment != null && step.comment!.isNotEmpty) ...[
                              pw.SizedBox(height: 3),
                              pw.Text(
                                '"${step.comment}"',
                                style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Approved Badge
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#16A34A')),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  '✓ APPROVED',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#16A34A'),
                  ),
                ),
              ),

              pw.Spacer(),

              // FOOTER DISCLAIMER & SIGNATORY BOX
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'This is a computer-generated voucher · no physical signature is required.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'Samskar Educational Society · $indentNoStr · printed ${_formatDateTime(DateTime.now().toIso8601String())}',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 140,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'FOR OFFICE USE ONLY',
                          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'Authorised Signatory',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Voucher_${indent.voucherNo ?? indent.indentNo}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.of(context);
    final indent = _indent;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.all(20),
        child: _isLoading && indent == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : indent == null
                ? const Center(child: Text('Indent not found'))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Header with Indent No, Status Badge and Close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  indent.indentNo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    indent.status.capitalize(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          indent.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Purpose
                        if (indent.purpose != null && indent.purpose!.isNotEmpty) ...[
                          Text(
                            indent.purpose!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Metadata: Raised by Swapnika  Dept: Admission Counselling  Branch: Moti Nagar
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                                children: [
                                  const TextSpan(text: 'Raised by '),
                                  TextSpan(
                                    text: indent.raisedBy ?? 'Swapnika',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (indent.departmentName != null)
                              Text(
                                'Dept: ${indent.departmentName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                              ),
                            if (indent.branchName != null)
                              Text(
                                'Branch: ${indent.branchName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Needed by date and Created date
                        Row(
                          children: [
                            Text(
                              '${s.neededBy} ${_formatDate(indent.neededBy)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatDateTime(indent.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Items Table Container
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        s.itemHeader,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        s.qtyHeader,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'UNIT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        s.amountHeader,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Line Items
                              for (final line in indent.items) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          line.description,
                                          style: const TextStyle(fontSize: 11.5),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${line.qty}',
                                          style: const TextStyle(fontSize: 11.5),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '₹${line.unitPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 11.5),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '₹${line.amount.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                              ],

                              // Total Row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                ),
                                child: Row(
                                  children: [
                                    const Spacer(flex: 7),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '₹${indent.amount.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Approval chain section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.approvalChain,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Approval chain steps
                        for (final step in indent.steps) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🟢 ', style: TextStyle(fontSize: 10)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: step.approverLevel == 4
                                                  ? 'Centre Head · '
                                                  : (step.approverLevel == 5 ? 'Director · ' : 'Approver (L${step.approverLevel}) · '),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: step.decision.capitalize(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${step.decidedBy ?? "Approver"} · ${_formatDateTime(step.decidedAt)}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                                        ),
                                      ),
                                      if (step.comment != null && step.comment!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '"${step.comment}"',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        const SizedBox(height: 14),

                        // Fully approved voucher banner and Print voucher (PDF) button
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fully approved — voucher ${indent.voucherNo ?? "VCH-2026-0001"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _printVoucherPdf(indent),
                                icon: const Icon(Icons.print_rounded, size: 16),
                                label: Text(
                                  s.printVoucherPdf,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F172A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
