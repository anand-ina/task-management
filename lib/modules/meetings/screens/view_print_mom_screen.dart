import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/localization/app_strings.dart';
import '../models/meeting_model.dart';
import '../models/minutes_of_meeting_model.dart';
import '../repository/meetings_repository.dart';

class ViewPrintMomScreen extends StatefulWidget {
  final MeetingItemModel meeting;

  const ViewPrintMomScreen({
    super.key,
    required this.meeting,
  });

  static Future<void> show(BuildContext context, MeetingItemModel meeting) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViewPrintMomScreen(meeting: meeting),
      ),
    );
  }

  @override
  State<ViewPrintMomScreen> createState() => _ViewPrintMomScreenState();
}

class _ViewPrintMomScreenState extends State<ViewPrintMomScreen> {
  final MeetingsRepository _repository = MeetingsRepository();

  bool _isLoading = true;
  MinutesOfMeetingModel? _momModel;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMomData();
  }

  Future<void> _fetchMomData() async {
    final meetingId = widget.meeting.rawId ?? widget.meeting.id;
    try {
      final res = await _repository.getMeetingMom(meetingId);
      if (mounted) {
        setState(() {
          _momModel = res;
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

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatDateOnly(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Future<void> _exportAndPrintPdf() async {
    final s = AppStrings.of(context);
    final meeting = _momModel?.meeting ??
        MomMeetingDetails(
          id: widget.meeting.id,
          title: widget.meeting.title,
          startsAt: widget.meeting.startsAt,
          endsAt: widget.meeting.endsAt,
          location: widget.meeting.location,
          agenda: widget.meeting.agenda,
          status: widget.meeting.status,
          organizer: widget.meeting.organizer,
        );

    final mom = _momModel?.mom;
    final invitees = _momModel?.invitees ?? [];

    final presentInvitees = invitees.where((i) => i.attended).toList();
    final absentInvitees = invitees.where((i) => !i.attended).toList();

    try {
      final doc = pw.Document();

      // Load banner.png
      pw.MemoryImage? bannerImage;
      try {
        final byteData = await rootBundle.load('assets/images/banner.png');
        bannerImage = pw.MemoryImage(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint('[ViewPrintMomScreen] Error loading banner image: $e');
      }

      const navyBg = PdfColor.fromInt(0xFF132A50);
      const goldStripe = PdfColor.fromInt(0xFFC28B1E);
      const tealHeader = PdfColor.fromInt(0xFF0F766E);
      const lightBorder = PdfColor.fromInt(0xFFE2E8F0);
      const darkText = PdfColor.fromInt(0xFF0F172A);
      const greyText = PdfColor.fromInt(0xFF64748B);
      const lightGreyText = PdfColor.fromInt(0xFF94A3B8);
      const tableHeaderBg = PdfColor.fromInt(0xFFF1F5F9);

      final now = DateTime.now();
      final printTimestamp = DateFormat('d MMM yyyy, HH:mm').format(now);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context ctx) {
            return [
              // Top Navy Header Banner
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: navyBg,
                  borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Banner Image / Logo
                    if (bannerImage != null)
                      pw.Container(
                        height: 38,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Image(bannerImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Text(
                        'SAMSKAR THE LIFE SCHOOL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                    // Badge + Meeting #
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFF0D5C58),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'MINUTES OF MEETING',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'MEETING #${meeting.id}',
                          style: const pw.TextStyle(
                            color: lightGreyText,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Gold Accent Bar
              pw.Container(
                height: 3.5,
                color: goldStripe,
              ),

              pw.SizedBox(height: 16),

              // Section: MEETING DETAILS
              _buildPdfSectionHeader('MEETING DETAILS', tealHeader, lightBorder),
              pw.SizedBox(height: 8),

              // Title
              pw.Text('TITLE', style: const pw.TextStyle(fontSize: 7.5, color: greyText)),
              pw.SizedBox(height: 2),
              pw.Text(
                meeting.title,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: darkText),
              ),
              pw.SizedBox(height: 8),

              // Date & Venue
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DATE & TIME', style: const pw.TextStyle(fontSize: 7.5, color: greyText)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _formatDateTime(meeting.startsAt),
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VENUE', style: const pw.TextStyle(fontSize: 7.5, color: greyText)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          mom?.venue?.isNotEmpty == true ? mom!.venue! : (meeting.location ?? 'In person'),
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Organizer & Recorded By
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ORGANIZER', style: const pw.TextStyle(fontSize: 7.5, color: greyText)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          meeting.organizer ?? '—',
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('RECORDED BY', style: const pw.TextStyle(fontSize: 7.5, color: greyText)),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          mom?.recordedBy?.isNotEmpty == true
                              ? mom!.recordedBy!
                              : (presentInvitees.isNotEmpty ? presentInvitees.first.name : (invitees.isNotEmpty ? invitees.first.name : '—')),
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Section: ATTENDANCE
              _buildPdfSectionHeader('ATTENDANCE', tealHeader, lightBorder),
              pw.SizedBox(height: 8),

              if (mom?.attendeesText.isNotEmpty == true) ...[
                pw.Text(mom!.attendeesText, style: const pw.TextStyle(fontSize: 9.5, color: darkText)),
                pw.SizedBox(height: 8),
              ],

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Present (X)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PRESENT (${presentInvitees.length})',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF16A34A),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (presentInvitees.isEmpty)
                          pw.Text('—', style: const pw.TextStyle(fontSize: 9, color: greyText))
                        else
                          pw.Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: presentInvitees.map((p) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: const PdfColor.fromInt(0xFFDCFCE7),
                                  borderRadius: pw.BorderRadius.circular(3),
                                ),
                                child: pw.Text(
                                  p.name,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFF166534),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  // Absent (Y)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ABSENT (${absentInvitees.length})',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFDC2626),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (absentInvitees.isEmpty)
                          pw.Text('—', style: const pw.TextStyle(fontSize: 9, color: greyText))
                        else
                          pw.Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: absentInvitees.map((a) {
                              return pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: const PdfColor.fromInt(0xFFFEE2E2),
                                  borderRadius: pw.BorderRadius.circular(3),
                                ),
                                child: pw.Text(
                                  a.name,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: const PdfColor.fromInt(0xFF991B1B),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Section: AGENDA
              _buildPdfSectionHeader('AGENDA', tealHeader, lightBorder),
              pw.SizedBox(height: 6),
              pw.Text(
                mom?.agenda.isNotEmpty == true ? mom!.agenda : (meeting.agenda ?? '—'),
                style: const pw.TextStyle(fontSize: 9.5, color: darkText),
              ),
              pw.SizedBox(height: 16),

              // Section: DISCUSSION
              _buildPdfSectionHeader('DISCUSSION', tealHeader, lightBorder),
              pw.SizedBox(height: 6),
              pw.Text(
                mom?.discussion.isNotEmpty == true ? mom!.discussion : '—',
                style: const pw.TextStyle(fontSize: 9.5, color: darkText, lineSpacing: 2),
              ),
              pw.SizedBox(height: 16),

              // Section: DECISIONS TAKEN
              _buildPdfSectionHeader('DECISIONS TAKEN', tealHeader, lightBorder),
              pw.SizedBox(height: 6),
              pw.Text(
                mom?.decisions.isNotEmpty == true ? mom!.decisions : '—',
                style: const pw.TextStyle(fontSize: 9.5, color: darkText),
              ),
              pw.SizedBox(height: 16),

              // Section: ACTION ITEMS
              _buildPdfSectionHeader('ACTION ITEMS', tealHeader, lightBorder),
              pw.SizedBox(height: 8),

              pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(26),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: tableHeaderBg,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    children: [
                      _buildPdfTableCell('#', isHeader: true),
                      _buildPdfTableCell('ACTION', isHeader: true),
                      _buildPdfTableCell('OWNER', isHeader: true),
                      _buildPdfTableCell('DUE', isHeader: true),
                    ],
                  ),
                  if (mom?.actionItems.isNotEmpty == true)
                    ...mom!.actionItems.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final item = entry.value;
                      return pw.TableRow(
                        children: [
                          _buildPdfTableCell('$idx'),
                          _buildPdfTableCell(item.item),
                          _buildPdfTableCell(item.owner),
                          _buildPdfTableCell(_formatDateOnly(item.due)),
                        ],
                      );
                    })
                  else
                    pw.TableRow(
                      children: [
                        _buildPdfTableCell('—'),
                        _buildPdfTableCell('No action items recorded'),
                        _buildPdfTableCell('—'),
                        _buildPdfTableCell('—'),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Dashed Line
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: lightBorder, width: 0.8, style: pw.BorderStyle.dashed),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  // Left Disclaimer
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'This is a computer-generated record of the minutes - no physical signature is required.',
                        style: const pw.TextStyle(fontSize: 7.5, color: lightGreyText),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Samskar Educational Society · Meeting #${meeting.id} · printed $printTimestamp',
                        style: const pw.TextStyle(fontSize: 7.5, color: lightGreyText),
                      ),
                    ],
                  ),

                  // Right Chairperson Office Box
                  pw.Container(
                    width: 140,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: lightBorder, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'FOR OFFICE USE ONLY',
                          style: const pw.TextStyle(fontSize: 6.5, color: lightGreyText, letterSpacing: 0.5),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          'Chairperson',
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'MOM_Meeting_${meeting.id}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf',
      );
    } catch (e, stack) {
      debugPrint('[ViewPrintMomScreen] Error exporting PDF: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _buildPdfSectionHeader(String title, PdfColor color, PdfColor dividerColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          height: 0.6,
          color: dividerColor,
        ),
      ],
    );
  }

  static pw.Widget _buildPdfTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? const PdfColor.fromInt(0xFF475569) : const PdfColor.fromInt(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F766E),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final meeting = _momModel?.meeting ??
        MomMeetingDetails(
          id: widget.meeting.id,
          title: widget.meeting.title,
          startsAt: widget.meeting.startsAt,
          endsAt: widget.meeting.endsAt,
          location: widget.meeting.location,
          agenda: widget.meeting.agenda,
          status: widget.meeting.status,
          organizer: widget.meeting.organizer,
        );

    final mom = _momModel?.mom;
    final invitees = _momModel?.invitees ?? [];

    final presentInvitees = invitees.where((i) => i.attended).toList();
    final absentInvitees = invitees.where((i) => !i.attended).toList();

    final now = DateTime.now();
    final printTimestamp = DateFormat('d MMM yyyy, HH:mm').format(now);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar matching screenshot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _exportAndPrintPdf,
                    icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                    label: Text(
                      s.printSavePdfButton,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      s.closeButton,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Document Scrollable Container
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 760),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Navy Header Banner matching screenshot
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF132A50),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Logo Container
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Image.asset(
                                        'assets/images/banner.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Text(
                                          'SAMSKAR THE LIFE SCHOOL',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),

                                    // Badge & Meeting ID
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D5C58),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'MINUTES OF MEETING',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'MEETING #${meeting.id}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Gold Accent Bar
                              Container(
                                height: 3.5,
                                color: const Color(0xFFC28B1E),
                              ),

                              // Document Body
                              Padding(
                                padding: const EdgeInsets.all(26),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section: MEETING DETAILS
                                    _buildSectionHeader(s.meetingDetailsHeader, isDark),
                                    const SizedBox(height: 12),

                                    Text(
                                      s.titleLabel,
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      meeting.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 12),

                                    // Row 1: Date & Venue
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.dateAndTimeLabel,
                                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatDateTime(meeting.startsAt),
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.venueLabel,
                                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                mom?.venue?.isNotEmpty == true ? mom!.venue! : (meeting.location ?? 'In person'),
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Row 2: Organizer & Recorded By
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.organizerLabel,
                                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                meeting.organizer ?? '—',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.recordedByLabel,
                                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                mom?.recordedBy?.isNotEmpty == true
                                                    ? mom!.recordedBy!
                                                    : (presentInvitees.isNotEmpty
                                                        ? presentInvitees.first.name
                                                        : (invitees.isNotEmpty ? invitees.first.name : '—')),
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),

                                    // Section: ATTENDANCE
                                    _buildSectionHeader(s.attendanceHeader, isDark),
                                    const SizedBox(height: 10),

                                    if (mom?.attendeesText.isNotEmpty == true) ...[
                                      Text(
                                        mom!.attendeesText,
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                      ),
                                      const SizedBox(height: 10),
                                    ],

                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Present
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${s.presentLabel} (${presentInvitees.length})',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (presentInvitees.isEmpty)
                                                const Text('—', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                                              else
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: presentInvitees.map((p) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFDCFCE7),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        p.name,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF166534),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Absent
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${s.absentLabel} (${absentInvitees.length})',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFDC2626),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (absentInvitees.isEmpty)
                                                const Text('—', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
                                              else
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: absentInvitees.map((a) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFFEE2E2),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        a.name,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF991B1B),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 22),

                                    // Section: AGENDA
                                    _buildSectionHeader(s.agendaMomLabel, isDark),
                                    const SizedBox(height: 8),
                                    Text(
                                      mom?.agenda.isNotEmpty == true ? mom!.agenda : (meeting.agenda ?? '—'),
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 22),

                                    // Section: DISCUSSION
                                    _buildSectionHeader(s.discussionPointsLabel, isDark),
                                    const SizedBox(height: 8),
                                    Text(
                                      mom?.discussion.isNotEmpty == true ? mom!.discussion : '—',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.5),
                                    ),
                                    const SizedBox(height: 22),

                                    // Section: DECISIONS TAKEN
                                    _buildSectionHeader(s.decisionsTakenLabel, isDark),
                                    const SizedBox(height: 8),
                                    Text(
                                      mom?.decisions.isNotEmpty == true ? mom!.decisions : '—',
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                    ),
                                    const SizedBox(height: 22),

                                    // Section: ACTION ITEMS
                                    _buildSectionHeader(s.actionItemsLabel, isDark),
                                    const SizedBox(height: 10),

                                    // Action Items Table
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Column(
                                        children: [
                                          // Table Header
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(
                                                  width: 32,
                                                  child: Text(
                                                    '#',
                                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    s.actionItemCol,
                                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    s.ownerCol,
                                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    s.dueCol,
                                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Table Rows
                                          if (mom?.actionItems.isNotEmpty == true)
                                            ...mom!.actionItems.asMap().entries.map((entry) {
                                              final idx = entry.key + 1;
                                              final item = entry.value;
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(color: Colors.grey.shade200, width: 0.8),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 32,
                                                      child: Text(
                                                        '$idx',
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        item.item,
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        item.owner,
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        _formatDateOnly(item.due),
                                                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            })
                                          else
                                            const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Text(
                                                'No action items recorded',
                                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Dashed Divider
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        const dashWidth = 5.0;
                                        const dashSpace = 3.0;
                                        final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: List.generate(dashCount, (_) {
                                            return SizedBox(
                                              width: dashWidth,
                                              height: 1,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(color: Colors.grey.shade300),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 18),

                                    // Footer Row: Disclaimer + Chairperson Box
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                s.computerGeneratedNotice,
                                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Samskar Educational Society · Meeting #${meeting.id} · printed $printTimestamp',
                                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          width: 140,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                s.forOfficeUseOnly,
                                                style: const TextStyle(
                                                  fontSize: 7.5,
                                                  color: Color(0xFF94A3B8),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 18),
                                              Text(
                                                s.chairpersonLabel,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
