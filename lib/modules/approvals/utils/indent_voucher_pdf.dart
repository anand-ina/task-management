import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/indent_model.dart';

/// Purchase Indent Voucher PDF — same layout as the web voucher (/voucher/{id}),
/// built only from the indent returned by GET /indents/{id}.
class IndentVoucherPdf {
  IndentVoucherPdf._();

  // PDF palette (pdf package colours, not Flutter theme colours)
  static final _navy = PdfColor.fromHex('#0F2342');
  static final _teal = PdfColor.fromHex('#0F766E');
  static final _tealSoft = PdfColor.fromHex('#EEF7F5');
  static final _gold = PdfColor.fromHex('#C9A24A');
  static final _text = PdfColor.fromHex('#0F172A');
  static final _muted = PdfColor.fromHex('#64748B');
  static final _faint = PdfColor.fromHex('#94A3B8');
  static final _line = PdfColor.fromHex('#E2E8F0');
  static final _headBg = PdfColor.fromHex('#F1F5F9');
  static final _green = PdfColor.fromHex('#15803D');
  static final _greenSoft = PdfColor.fromHex('#ECFDF3');
  static final _red = PdfColor.fromHex('#B91C1C');
  static final _redSoft = PdfColor.fromHex('#FEF2F2');

  static final NumberFormat _inr = NumberFormat('#,##,##0.00', 'en_IN');

  static String _money(num v) => '₹${_inr.format(v)}';

  static String _date(String? raw) {
    final d = DateTime.tryParse(raw ?? '');
    return d == null ? '—' : DateFormat('dd MMM yyyy').format(d.toLocal());
  }

  static String _dateTime(String? raw) {
    final d = DateTime.tryParse(raw ?? '');
    return d == null ? '' : DateFormat('dd MMM yyyy, HH:mm').format(d.toLocal());
  }

  static String _fileName(IndentItemModel i) => 'Voucher_${(i.voucherNo ?? i.indentNo).replaceAll('/', '-')}.pdf';

  static Future<Uint8List> build(IndentItemModel indent) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    pw.MemoryImage? logo;
    try {
      logo = pw.MemoryImage((await rootBundle.load('assets/images/banner.png')).buffer.asUint8List());
    } catch (_) {}

    final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));

    pw.Widget label(String t) => pw.Text(t.toUpperCase(),
        style: pw.TextStyle(fontSize: 6.5, color: _faint, letterSpacing: 0.6));
    pw.Widget value(String t) =>
        pw.Text(t, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _text));
    pw.Widget field(String l, String v) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 9),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [label(l), pw.SizedBox(height: 1.5), value(v)]),
        );
    pw.Widget section(String t) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(t.toUpperCase(),
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _teal, letterSpacing: 1)),
            pw.SizedBox(height: 4),
            pw.Container(height: 0.6, color: _line),
            pw.SizedBox(height: 9),
          ],
        );

    // ---------- Approvals: steps that were actually signed, plus a Director override ----------
    final approvals = <(String role, String name, String at)>[];
    for (final s in indent.steps) {
      if (s.decision == 'approved' || s.decision == 'rejected') {
        final role = s.isPrincipalStep ? 'Centre Head' : s.displayLabel;
        approvals.add((role, s.decidedBy ?? '—', _dateTime(s.decidedAt)));
      }
    }
    if (indent.isOverridden) {
      approvals.add(('Director (Override)', indent.overrideByName ?? 'Director', _dateTime(indent.overriddenAt)));
    }

    final status = indent.status.toLowerCase();
    final isApproved = status == 'approved';
    final statusColor = isApproved ? _green : (status == 'rejected' ? _red : _muted);
    final statusBg = isApproved ? _greenSoft : (status == 'rejected' ? _redSoft : _headBg);

    final printedAt = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ---------- Header ----------
              pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: pw.BoxDecoration(
                  color: _navy,
                  borderRadius: const pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: logo != null
                          ? pw.Image(logo, fit: pw.BoxFit.contain)
                          : pw.Text('SAMSKAR',
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _navy)),
                    ),
                    pw.Spacer(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: _teal,
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                          ),
                          child: pw.Text('PURCHASE INDENT VOUCHER',
                              style: pw.TextStyle(
                                  fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 0.8)),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('VOUCHER NO', style: pw.TextStyle(fontSize: 6, color: _faint, letterSpacing: 0.6)),
                        pw.Text(indent.voucherNo ?? '—',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 3),
                        pw.Text('INDENT NO', style: pw.TextStyle(fontSize: 6, color: _faint, letterSpacing: 0.6)),
                        pw.Text(indent.indentNo,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Container(height: 2.5, color: _gold),

              // ---------- Body ----------
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(22, 18, 22, 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    section('Voucher Details'),
                    field('Title', indent.title),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              field('Raised by', indent.raisedBy ?? '—'),
                              field('Branch', indent.branchName ?? '—'),
                              field('Needed by', _date(indent.neededBy)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              field('Department', indent.departmentName ?? '—'),
                              field('Raised on', _date(indent.createdAt)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if ((indent.purpose ?? '').isNotEmpty) field('Purpose', indent.purpose!),
                    pw.SizedBox(height: 6),

                    section('Items'),
                    pw.Table(
                      columnWidths: const {
                        0: pw.FixedColumnWidth(24),
                        1: pw.FlexColumnWidth(5),
                        2: pw.FixedColumnWidth(36),
                        3: pw.FixedColumnWidth(80),
                        4: pw.FixedColumnWidth(80),
                      },
                      children: [
                        pw.TableRow(
                          decoration: pw.BoxDecoration(color: _headBg),
                          children: [
                            _cell('#', head: true),
                            _cell('DESCRIPTION', head: true),
                            _cell('QTY', head: true, right: true),
                            _cell('UNIT PRICE', head: true, right: true),
                            _cell('AMOUNT', head: true, right: true),
                          ],
                        ),
                        ...indent.items.asMap().entries.map((e) => pw.TableRow(
                              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))),
                              children: [
                                _cell('${e.key + 1}', muted: true),
                                _cell(e.value.description),
                                _cell('${e.value.qty}', right: true, muted: true),
                                _cell(_money(e.value.unitPrice), right: true),
                                _cell(_money(e.value.amount), right: true),
                              ],
                            )),
                      ],
                    ),
                    pw.Container(
                      color: _tealSoft,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('Grand Total',
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _text)),
                          pw.SizedBox(width: 30),
                          pw.Text(_money(indent.amount),
                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _teal)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),

                    section('Approvals'),
                    if (approvals.isEmpty)
                      pw.Text('No approvals recorded yet.', style: pw.TextStyle(fontSize: 8.5, color: _muted))
                    else
                      pw.Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: approvals
                            .map((a) => pw.SizedBox(
                                  width: 160,
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Container(height: 0.6, color: _line),
                                      pw.SizedBox(height: 5),
                                      pw.Text(a.$1.toUpperCase(),
                                          style: pw.TextStyle(
                                              fontSize: 7, fontWeight: pw.FontWeight.bold, color: _text, letterSpacing: 0.5)),
                                      pw.Text(a.$2, style: pw.TextStyle(fontSize: 8.5, color: _text)),
                                      if (a.$3.isNotEmpty) pw.Text(a.$3, style: pw.TextStyle(fontSize: 7, color: _faint)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    pw.SizedBox(height: 12),
                    pw.Row(children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: statusBg,
                          border: pw.Border.all(color: statusColor),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
                          if (isApproved) ...[
                            pw.SvgImage(
                              svg: '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M4 12.5l5 5L20 6.5" fill="none" stroke="#15803D" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>',
                              width: 8,
                              height: 8,
                            ),
                            pw.SizedBox(width: 4),
                          ],
                          pw.Text(status.toUpperCase(),
                              style: pw.TextStyle(
                                  fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: statusColor, letterSpacing: 1)),
                        ]),
                      ),
                    ]),
                    pw.SizedBox(height: 14),
                    // dashed divider
                    pw.Row(
                      children: List.generate(
                        90,
                        (i) => pw.Expanded(
                          child: pw.Container(height: 0.6, color: i.isEven ? _line : PdfColors.white),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('This is a computer-generated voucher · no physical signature is required.',
                                  style: pw.TextStyle(fontSize: 6.5, color: _faint)),
                              pw.SizedBox(height: 2),
                              pw.Text('Samskar Educational Society · ${indent.indentNo} · printed $printedAt',
                                  style: pw.TextStyle(fontSize: 6.5, color: _faint)),
                            ],
                          ),
                        ),
                        pw.Container(
                          width: 120,
                          padding: const pw.EdgeInsets.fromLTRB(10, 7, 10, 7),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _line),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                          ),
                          child: pw.Column(children: [
                            pw.Text('FOR OFFICE USE ONLY',
                                style: pw.TextStyle(fontSize: 5.5, color: _faint, letterSpacing: 0.5)),
                            pw.SizedBox(height: 14),
                            pw.Container(height: 0.6, color: _line),
                            pw.SizedBox(height: 4),
                            pw.Text('Authorised Signatory',
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _text)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )]),
      ),
    );
    return doc.save();
  }

  static pw.Widget _cell(String t, {bool head = false, bool right = false, bool muted = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          t,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: head ? 6.5 : 8.5,
            fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: head ? _muted : (muted ? _faint : _text),
            letterSpacing: head ? 0.5 : 0,
          ),
        ),
      );

  /// Opens the system print dialog (also lets the user "Save as PDF").
  static Future<void> printVoucher(IndentItemModel indent) async {
    await Printing.layoutPdf(onLayout: (_) => build(indent), name: _fileName(indent));
  }

  /// Download / share the voucher PDF (Files, WhatsApp, Drive …).
  static Future<void> downloadVoucher(IndentItemModel indent) async {
    final bytes = await build(indent);
    await Printing.sharePdf(bytes: bytes, filename: _fileName(indent));
  }
}
