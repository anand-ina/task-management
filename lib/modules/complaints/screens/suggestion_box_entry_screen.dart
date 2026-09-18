import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
 import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../models/batch_ticket_request.dart';
import '../models/batch_ticket_response.dart';
import '../models/lookup_models.dart';
import '../models/ticket_meta_model.dart';
import '../models/ticket_model.dart';
import '../repository/complaints_repository.dart';
import 'complaints_screen.dart';

class _SlipFormData {
  String type; // 'complaint', 'feedback', 'appreciation'
  final TextEditingController studentNameController;
  final TextEditingController classSectionController;
  String aboutKind; // 'general', 'staff', 'transport', 'facility'
  int? aboutUserId;
  String category;
  String visibility; // 'general', 'confidential'
  final TextEditingController descriptionController;
  final List<TicketAttachmentModel> attachments;
  bool isUploading;

  _SlipFormData({
    this.type = 'complaint',
    String studentName = '',
    String classSection = '',
    this.aboutKind = 'general',
    this.aboutUserId,
    this.category = 'Other',
    this.visibility = 'general',
    String description = '',
    List<TicketAttachmentModel>? attachments,
    this.isUploading = false,
  })  : studentNameController = TextEditingController(text: studentName),
        classSectionController = TextEditingController(text: classSection),
        descriptionController = TextEditingController(text: description),
        attachments = attachments ?? [];

  void dispose() {
    studentNameController.dispose();
    classSectionController.dispose();
    descriptionController.dispose();
  }
}

class SuggestionBoxEntryScreen extends StatefulWidget {
  const SuggestionBoxEntryScreen({super.key});

  @override
  State<SuggestionBoxEntryScreen> createState() => _SuggestionBoxEntryScreenState();
}

class _SuggestionBoxEntryScreenState extends State<SuggestionBoxEntryScreen> {
  final ComplaintsRepository _repository = ComplaintsRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime _boxOpenedDate = DateTime.now();
  int? _selectedBranchId;
  TicketMetaModel _meta = const TicketMetaModel();
  List<LookupBranchModel> _branches = [];
  List<LookupAssigneeModel> _assignees = [];

  final List<_SlipFormData> _slips = [];
  bool _isLoadingInitial = true;
  bool _isSaving = false;
  String? _warningMessage;
  List<CreatedTicketTaskItem> _createdTickets = [];

  @override
  void initState() {
    super.initState();
    _slips.add(_SlipFormData());
    _loadInitialData();
  }

  @override
  void dispose() {
    for (final slip in _slips) {
      slip.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    try {
      final meta = await _repository.getTicketMeta();
      final branches = await _repository.getBranches();
      final assignees = await _repository.getAssignees();

      if (mounted) {
        setState(() {
          _meta = meta;
          _branches = branches;
          _assignees = assignees;
          if (_branches.isNotEmpty && _selectedBranchId == null) {
            _selectedBranchId = _branches.first.id;
          }
          if (_meta.categories.isNotEmpty) {
            for (final slip in _slips) {
              if (slip.category == 'Other') {
                slip.category = _meta.categories.first;
              }
            }
          }
          _isLoadingInitial = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _onBranchChanged(int? branchId) async {
    if (branchId == null) return;
    setState(() {
      _selectedBranchId = branchId;
    });

    try {
      final meta = await _repository.getTicketMeta(branchId: branchId);
      if (mounted) {
        setState(() {
          _meta = meta;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _boxOpenedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() {
        _boxOpenedDate = picked;
      });
    }
  }

  void _addSlipRow() {
    setState(() {
      _slips.add(_SlipFormData(
        category: _meta.categories.isNotEmpty ? _meta.categories.first : 'Other',
      ));
    });
  }

  void _removeSlip(int index) {
    setState(() {
      if (_slips.length == 1) {
        _slips[0].dispose();
        _slips[0] = _SlipFormData(
          category: _meta.categories.isNotEmpty ? _meta.categories.first : 'Other',
        );
      } else {
        _slips[index].dispose();
        _slips.removeAt(index);
      }
    });
  }

  Future<void> _pickAndUploadPhoto(int slipIndex) async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    try {
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null) return;
      final List<dynamic> fileList = result is List ? result : (result.files as List);
      if (fileList.isEmpty) return;

      final dynamic file = fileList.first;
      final String? path = (file as dynamic).path?.toString();
      final String fileName = (file as dynamic).name?.toString() ?? 'attachment';
      if (path == null) return;

      setState(() {
        _slips[slipIndex].isUploading = true;
      });

      final uploaded = await _repository.uploadFile(
        filePath: path,
        filename: fileName,
      );

      if (mounted) {
        setState(() {
          _slips[slipIndex].attachments.add(uploaded);
          _slips[slipIndex].isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _slips[slipIndex].isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _saveRequests(AppStrings s) async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    final filledSlips = _slips.where((slip) => slip.descriptionController.text.trim().isNotEmpty).toList();

    if (filledSlips.isEmpty) {
      setState(() {
        _warningMessage = s.typeAtLeastOneSlipWarning;
      });
      return;
    }

    final missingPhotosCount = filledSlips.where((slip) => slip.attachments.isEmpty).length;
    if (missingPhotosCount > 0) {
      setState(() {
        _warningMessage = s.attachPhotoWarning(missingPhotosCount);
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _warningMessage = null;
    });

    try {
      final now = DateTime.now();
      final isToday = _boxOpenedDate.year == now.year &&
          _boxOpenedDate.month == now.month &&
          _boxOpenedDate.day == now.day;

      final DateTime effectiveDateTime;
      if (isToday || _boxOpenedDate.isAfter(now)) {
        // Safe against future date rejection and slight device clock skew ahead of server
        effectiveDateTime = now.subtract(const Duration(minutes: 2));
      } else {
        effectiveDateTime = DateTime(
          _boxOpenedDate.year,
          _boxOpenedDate.month,
          _boxOpenedDate.day,
          9,
          0,
          0,
        );
      }
      final receivedAt = effectiveDateTime.toUtc().toIso8601String();

      final requestRows = filledSlips.map((slip) {
        final studentName = slip.studentNameController.text.trim();
        return SuggestionSlipRowRequest(
          type: slip.type,
          studentName: studentName,
          classSection: slip.classSectionController.text.trim(),
          aboutKind: slip.aboutKind,
          aboutUserId: slip.aboutKind == 'staff' ? slip.aboutUserId : null,
          category: slip.category,
          description: slip.descriptionController.text.trim(),
          visibility: slip.visibility,
          attachments: slip.attachments,
          isAnonymous: studentName.isEmpty,
        );
      }).toList();

      final batchRequest = BatchTicketRequest(
        branchId: _selectedBranchId,
        receivedAt: receivedAt,
        rows: requestRows,
      );

      final response = await _repository.createBatchTickets(batchRequest);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _createdTickets = response.created;
          // Reset slips to 1 clean slip
          for (final slip in _slips) {
            slip.dispose();
          }
          _slips.clear();
          _slips.add(_SlipFormData(
            category: _meta.categories.isNotEmpty ? _meta.categories.first : 'Other',
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring('Exception: '.length);
        }
        setState(() {
          _isSaving = false;
          _warningMessage = msg;
        });
      }
    }
  }

  Color _getSlipColor(String type) {
    switch (type) {
      case 'complaint':
        return const Color(0xFFEF4444);
      case 'feedback':
        return const Color(0xFF3B82F6);
      case 'appreciation':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 750;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await ExitConfirmationDialog.show(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        drawer: const CustomLeftDrawer(currentRoute: '/complaints/suggestion-box'),
        appBar: const CustomAppBar(),
        body: _isLoadingInitial
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Back Button
                    _buildHeader(s, isDark, isMobile),
                    const SizedBox(height: 14),

                    // Controls Toolbar
                    _buildToolbar(s, isDark, isMobile),
                    const SizedBox(height: 12),

                    // Warning Alert
                    if (_warningMessage != null) ...[
                      _buildWarningBanner(_warningMessage!, isDark),
                      const SizedBox(height: 12),
                    ],

                    // Success Banner
                    if (_createdTickets.isNotEmpty) ...[
                      _buildSuccessBanner(s, isDark),
                      const SizedBox(height: 12),
                    ],

                    // Slip Cards List
                    ..._slips.asMap().entries.map((entry) {
                      final index = entry.key;
                      final slip = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSlipCard(slip, index, s, isDark, isMobile),
                      );
                    }),

                    // Footnote
                    const SizedBox(height: 8),
                    _buildFootnote(s, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(AppStrings s, bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                s.suggestionBoxEntryTitle,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(s.backToTracker, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          s.suggestionBoxSub,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(AppStrings s, bool isDark, bool isMobile) {
    final filledCount = _slips.where((slip) => slip.descriptionController.text.trim().isNotEmpty).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Box Opened Date
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${s.boxOpenedLabel}: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_boxOpenedDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.calendar_today_outlined, size: 14),
                ],
              ),
            ),
          ),

          // Branch Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedBranchId,
                hint: Text(s.branchPlaceholder, style: const TextStyle(fontSize: 12)),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                onChanged: _onBranchChanged,
                items: _branches.map((b) {
                  return DropdownMenuItem<int>(
                    value: b.id,
                    child: Text(b.name),
                  );
                }).toList(),
              ),
            ),
          ),

          // Add Row Button
          OutlinedButton(
            onPressed: _addSlipRow,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
              side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(s.addRowButton, style: const TextStyle(fontSize: 12)),
          ),

          // Save Requests Button
          ElevatedButton(
            onPressed: _isSaving ? null : () => _saveRequests(s),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              _isSaving ? s.savingRequests : s.saveRequestsButton(filledCount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(AppStrings s, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFF10B981), width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            s.registeredBannerTitle(_createdTickets.length),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _createdTickets.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${t.ticketNo}${t.taskNo != null ? " → ${t.taskNo}" : ""}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),))
    );
  }

  Widget _buildSlipCard(
    _SlipFormData slip,
    int index,
    AppStrings s,
    bool isDark,
    bool isMobile,
  ) {
    final slipColor = _getSlipColor(slip.type);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: slipColor, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Top: Slip number & Remove
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.slipTitle(index + 1),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _removeSlip(index),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(s.removeButton, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fields Grid / Column
              if (isMobile) ...[
                _buildTypeDropdown(slip, s, isDark),
                const SizedBox(height: 10),
                _buildStudentInput(slip, s, isDark),
                const SizedBox(height: 10),
                _buildClassInput(slip, s, isDark),
                const SizedBox(height: 10),
                _buildAboutDropdown(slip, s, isDark),
                if (slip.aboutKind == 'staff') ...[
                  const SizedBox(height: 10),
                  _buildStaffDropdown(slip, s, isDark),
                ],
                const SizedBox(height: 10),
                _buildCategoryDropdown(slip, s, isDark),
                const SizedBox(height: 10),
                _buildVisibilityDropdown(slip, s, isDark),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTypeDropdown(slip, s, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStudentInput(slip, s, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildClassInput(slip, s, isDark)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildAboutDropdown(slip, s, isDark)),
                    if (slip.aboutKind == 'staff') ...[
                      const SizedBox(width: 10),
                      Expanded(child: _buildStaffDropdown(slip, s, isDark)),
                    ],
                    const SizedBox(width: 10),
                    Expanded(child: _buildCategoryDropdown(slip, s, isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildVisibilityDropdown(slip, s, isDark)),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // What the slip says
              Text(
                s.whatSlipSays,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: slip.descriptionController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: s.typeSlipPlaceholder,
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),

              const SizedBox(height: 12),

              // Photo of the slip
              Text(
                s.photoOfSlip,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: slip.isUploading ? null : () => _pickAndUploadPhoto(index),
                    icon: slip.isUploading
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('📎', style: TextStyle(fontSize: 12)),
                    label: Text(
                      slip.isUploading ? s.uploadingPhoto : s.addPhotoButton,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                      side: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  ...slip.attachments.asMap().entries.map((attEntry) {
                    final attIdx = attEntry.key;
                    final att = attEntry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📄 ', style: TextStyle(fontSize: 11)),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              att.filename,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                slip.attachments.removeAt(attIdx);
                              });
                            },
                            child: const Icon(Icons.close, size: 12, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(_SlipFormData slip, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.typeLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: slip.type,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    slip.type = val;
                  });
                }
              },
              items: [
                DropdownMenuItem(value: 'complaint', child: Text(s.typeComplaint)),
                DropdownMenuItem(value: 'feedback', child: Text(s.typeFeedbackSuggestion)),
                DropdownMenuItem(value: 'appreciation', child: Text(s.typeAppreciation)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInput(_SlipFormData slip, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.studentBlankAnonymous,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: slip.studentNameController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: s.anonymousHint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildClassInput(_SlipFormData slip, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.classLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: slip.classSectionController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: s.classPlaceholder,
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutDropdown(_SlipFormData slip, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.aboutLabelSimple,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: slip.aboutKind,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    slip.aboutKind = val;
                  });
                }
              },
              items: [
                DropdownMenuItem(value: 'general', child: Text(s.generalOption)),
                DropdownMenuItem(value: 'staff', child: Text(s.staffMemberOption)),
                DropdownMenuItem(value: 'transport', child: Text(s.transportOption)),
                DropdownMenuItem(value: 'facility', child: Text(s.facilityOption)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffDropdown(_SlipFormData slip, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.staffMemberOption,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: slip.aboutUserId,
              hint: Text(s.notNamedOption, style: const TextStyle(fontSize: 12)),
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              onChanged: (val) {
                setState(() {
                  slip.aboutUserId = val;
                });
              },
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(s.notNamedOption),
                ),
                ..._assignees.map((a) {
                  return DropdownMenuItem<int?>(
                    value: a.id,
                    child: Text(a.name),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(_SlipFormData slip, AppStrings s, bool isDark) {
    final categories = _meta.categories.isNotEmpty ? _meta.categories : ['Other'];
    final validCategory = categories.contains(slip.category) ? slip.category : categories.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.categoryLabelSimple,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: validCategory,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    slip.category = val;
                  });
                }
              },
              items: categories.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityDropdown(_SlipFormData slip, AppStrings s, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.visibilityLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: slip.visibility,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    slip.visibility = val;
                  });
                }
              },
              items: [
                DropdownMenuItem(value: 'general', child: Text(s.visibilityGeneral)),
                DropdownMenuItem(value: 'confidential', child: Text(s.visibilityConfidential)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFootnote(AppStrings s, bool isDark) {
    final ownerName = _meta.owner?.name ?? 'the campus head';
    final points = _meta.appreciationPoints;

    return Text(
      s.suggestionBoxFootnote(ownerName, points),
      style: TextStyle(
        fontSize: 11.5,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        height: 1.4,
      ),
    );
  }
}
