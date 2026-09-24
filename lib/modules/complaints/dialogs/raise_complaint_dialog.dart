import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../bloc/complaints_bloc.dart';
import '../bloc/complaints_event.dart';
import '../bloc/complaints_state.dart';
import '../models/create_ticket_request.dart';
import '../models/lookup_models.dart';
import '../models/ticket_meta_model.dart';
import '../models/ticket_model.dart';
import '../repository/complaints_repository.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import 'complaint_registered_dialog.dart';

class RaiseComplaintDialog extends StatefulWidget {
  final VoidCallback? onTicketCreated;

  const RaiseComplaintDialog({super.key, this.onTicketCreated});

  static Future<void> show(BuildContext context, {VoidCallback? onTicketCreated}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: BlocProvider.of<ComplaintsBloc>(context),
        child: RaiseComplaintDialog(onTicketCreated: onTicketCreated),
      ),
    );
  }

  @override
  State<RaiseComplaintDialog> createState() => _RaiseComplaintDialogState();
}

class _RaiseComplaintDialogState extends State<RaiseComplaintDialog> {
  final ComplaintsRepository _repository = ComplaintsRepository();

  // Form State
  String _selectedType = 'complaint'; // 'complaint', 'feedback', 'appreciation'
  String _selectedSource = 'parent'; // 'parent', 'student'
  String _selectedChannel = 'whatsapp_group';
  final TextEditingController _channelDetailController = TextEditingController();
  DateTime _receivedAt = DateTime.now();

  int? _selectedBranchId;
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _classSectionController = TextEditingController();
  final TextEditingController _admissionNoController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentMobileController = TextEditingController();
  bool _isAnonymous = true;

  String _selectedAboutKind = 'staff'; // 'staff', 'department', 'transport', 'facility', 'general'
  int? _selectedAboutUserId;
  int? _selectedAboutDepartmentId;

  String _selectedCategory = 'Other';
  String _selectedPriority = 'medium'; // 'emergency', 'top_most', 'high', 'medium', 'low'
  String _selectedVisibility = 'general'; // 'general', 'confidential'
  final TextEditingController _descriptionController = TextEditingController();

  List<TicketAttachmentModel> _attachments = [];
  bool _isUploadingFile = false;
  String? _uploadError;

  TicketMetaModel _meta = const TicketMetaModel();
  List<LookupDepartmentModel> _departments = [];
  List<LookupBranchModel> _branches = [];
  List<LookupAssigneeModel> _assignees = [];
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _loadInitialLookups();
  }

  @override
  void dispose() {
    _channelDetailController.dispose();
    _studentNameController.dispose();
    _classSectionController.dispose();
    _admissionNoController.dispose();
    _parentNameController.dispose();
    _parentMobileController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLookups() async {
    final state = context.read<ComplaintsBloc>().state;
    if (state is ComplaintsLoadedState) {
      setState(() {
        _meta = state.meta;
        _departments = state.departments;
        _branches = state.branches;
        _assignees = state.assignees;
        if (_branches.isNotEmpty) {
          _selectedBranchId = _branches.first.id;
        }
        if (_meta.channels.isNotEmpty) {
          _selectedChannel = _meta.channels.first.value;
        }
        if (_meta.categories.isNotEmpty) {
          _selectedCategory = _meta.categories.contains('Transport')
              ? 'Transport'
              : _meta.categories.first;
        }
        _isLoadingInitial = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        _repository.getTicketMeta(),
        _repository.getDepartments(),
        _repository.getBranches(),
        _repository.getAssignees(),
      ]);

      if (mounted) {
        setState(() {
          _meta = results[0] as TicketMetaModel;
          _departments = results[1] as List<LookupDepartmentModel>;
          _branches = results[2] as List<LookupBranchModel>;
          _assignees = results[3] as List<LookupAssigneeModel>;

          if (_branches.isNotEmpty) {
            _selectedBranchId = _branches.first.id;
          }
          if (_meta.channels.isNotEmpty) {
            _selectedChannel = _meta.channels.first.value;
          }
          if (_meta.categories.isNotEmpty) {
            _selectedCategory = _meta.categories.contains('Transport')
                ? 'Transport'
                : _meta.categories.first;
          }
          _isLoadingInitial = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _onBranchChanged(int? newBranchId) async {
    if (newBranchId == null || newBranchId == _selectedBranchId) return;
    setState(() {
      _selectedBranchId = newBranchId;
    });

    try {
      final updatedMeta = await _repository.getTicketMeta(branchId: newBranchId);
      if (mounted) {
        setState(() {
          _meta = updatedMeta;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadFile() async {
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
        _isUploadingFile = true;
        _uploadError = null;
      });

      final uploaded = await _repository.uploadFile(
        filePath: path,
        filename: fileName,
      );

      if (mounted) {
        setState(() {
          _attachments.add(uploaded);
          _isUploadingFile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _uploadError = e.toString();
        });
      }
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _receivedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_receivedAt),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _receivedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submitComplaint() async {
    final s = AppStrings.of(context);
    final studentName = _studentNameController.text.trim();
    final classSection = _classSectionController.text.trim();
    final description = _descriptionController.text.trim();

    if (studentName.isEmpty || classSection.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.fillRequiredFieldsError), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    final mobile = _parentMobileController.text.trim();
    if (mobile.isNotEmpty && mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invalidMobileNumberError), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    DateTime safeReceivedAt = _receivedAt;
    final now = DateTime.now();
    if (safeReceivedAt.isAfter(now)) {
      safeReceivedAt = now.subtract(const Duration(minutes: 1));
    }
    final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm").format(safeReceivedAt);

    final request = CreateTicketRequest(
      type: _selectedType,
      source: _selectedSource,
      channel: _selectedChannel,
      channelDetail: _channelDetailController.text.trim(),
      receivedAt: formattedDate,
      branchId: _selectedBranchId ?? 1,
      studentName: studentName,
      classSection: classSection,
      admissionNo: _admissionNoController.text.trim(),
      parentName: _parentNameController.text.trim(),
      parentMobile: mobile,
      isAnonymous: _isAnonymous,
      visibility: _selectedVisibility,
      aboutKind: _selectedAboutKind,
      aboutUserId: _selectedAboutKind == 'staff' ? _selectedAboutUserId : null,
      aboutDepartmentId: _selectedAboutKind == 'department' ? _selectedAboutDepartmentId : null,
      aboutText: '',
      category: _selectedCategory,
      priority: _selectedPriority,
      description: description,
      attachments: _attachments,
    );

    context.read<ComplaintsBloc>().add(CreateComplaintEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slaDays = _meta.getSlaDaysForPriority(_selectedPriority);
    final formattedReceivedDate = DateFormat('dd/MM/yyyy, hh:mm a').format(_receivedAt);

    return BlocListener<ComplaintsBloc, ComplaintsState>(
      listener: (context, state) {
        if (state is ComplaintsLoadedState) {
          if (state.submittedTicket != null) {
            final submittedTicket = state.submittedTicket!;
            Navigator.of(context).pop(); // Close raise dialog
            ComplaintRegisteredDialog.show(context, ticket: submittedTicket);
            if (widget.onTicketCreated != null) {
              widget.onTicketCreated!();
            }
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red.shade700),
            );
          }
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 640,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: _isLoadingInitial
              ? const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    // Dialog Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('🎫', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                s.raiseARequestTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(context).pop(),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Scrollable Form Body
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        children: [
                          // Type Selector
                          _buildLabel(s.typeLabel),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildPillButton(
                                title: s.typeComplaint,
                                isSelected: _selectedType == 'complaint',
                                onTap: () => setState(() => _selectedType = 'complaint'),
                              ),
                              const SizedBox(width: 3),
                              _buildPillButton(
                                title: s.typeFeedbackSuggestion,
                                isSelected: _selectedType == 'feedback',
                                onTap: () => setState(() => _selectedType = 'feedback'),
                              ),
                              const SizedBox(width: 3),
                              _buildPillButton(
                                title: s.typeAppreciation,
                                isSelected: _selectedType == 'appreciation',
                                onTap: () => setState(() => _selectedType = 'appreciation'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Received From Selector
                          _buildLabel(s.receivedFromLabel),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildPillButton(
                                title: s.receivedFromParent,
                                isSelected: _selectedSource == 'parent',
                                onTap: () => setState(() => _selectedSource = 'parent'),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                title: s.receivedFromStudent,
                                isSelected: _selectedSource == 'student',
                                onTap: () => setState(() => _selectedSource = 'student'),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                title: 'Staff Member',
                                isSelected: _selectedSource == 'staff_member',
                                onTap: () => setState(() => _selectedSource = 'staff_member'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Channel & Which Group / Place
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.channelLabel),
                                    const SizedBox(height: 6),
                                    SearchableFilterDropdown<String>(
                                      value: _selectedChannel,
                                      hint: s.channelLabel,
                                      searchHint: 'Search channel...',
                                      items: _meta.channels
                                          .map((c) => SearchableDropdownItem<String>(
                                                value: c.value,
                                                label: c.label,
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedChannel = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.whichGroupPlaceLabel),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _channelDetailController,
                                      decoration: _inputDecoration(isDark, hintText: s.whichGroupPlaceHint),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Received On & Branch
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.receivedOnLabel),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: _pickDateTime,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formattedReceivedDate,
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey.shade500),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.branchLabel),
                                    const SizedBox(height: 6),
                                    SearchableFilterDropdown<int>(
                                      value: _selectedBranchId,
                                      hint: s.branchLabel,
                                      searchHint: 'Search branch...',
                                      items: _branches
                                          .map((b) => SearchableDropdownItem<int>(
                                                value: b.id,
                                                label: '${b.code} - ${b.name}',
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) _onBranchChanged(val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Student details: Name, Class & section, Admission no.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.studentNameLabel),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _studentNameController,
                                      decoration: _inputDecoration(isDark, hintText: s.studentNameHint),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.classSectionLabel),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _classSectionController,
                                      decoration: _inputDecoration(isDark, hintText: s.classSectionHint),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.admissionNoLabel),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _admissionNoController,
                                      decoration: _inputDecoration(isDark, hintText: s.admissionNoHint),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Parent name & Mobile
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.parentNameLabel),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _parentNameController,
                                      decoration: _inputDecoration(isDark, hintText: s.parentNameHint),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(s.parentMobileLabel),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _parentMobileController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _inputDecoration(isDark, hintText: s.parentMobileHint),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Anonymous Checkbox
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _isAnonymous,
                                  activeColor: const Color(0xFF132A50),
                                  onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        s.keepParentAnonymous,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.keepParentAnonymousSubtext,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // About Selector
                          _buildLabel(s.aboutLabel),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPillButton(
                                title: s.aboutStaffMember,
                                isSelected: _selectedAboutKind == 'staff',
                                onTap: () => setState(() => _selectedAboutKind = 'staff'),
                              ),
                              _buildPillButton(
                                title: s.aboutDepartment,
                                isSelected: _selectedAboutKind == 'department',
                                onTap: () => setState(() => _selectedAboutKind = 'department'),
                              ),
                              _buildPillButton(
                                title: s.aboutTransport,
                                isSelected: _selectedAboutKind == 'transport',
                                onTap: () => setState(() => _selectedAboutKind = 'transport'),
                              ),
                              _buildPillButton(
                                title: s.aboutFacility,
                                isSelected: _selectedAboutKind == 'facility',
                                onTap: () => setState(() => _selectedAboutKind = 'facility'),
                              ),
                              _buildPillButton(
                                title: s.aboutGeneral,
                                isSelected: _selectedAboutKind == 'general',
                                onTap: () => setState(() => _selectedAboutKind = 'general'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Dynamic About details: Staff dropdown or Department dropdown
                          if (_selectedAboutKind == 'staff') ...[
                            _buildLabel(s.staffMemberSubtext),
                            const SizedBox(height: 6),
                            SearchableFilterDropdown<int?>(
                              value: _selectedAboutUserId,
                              hint: s.staffMemberSubtext,
                              searchHint: 'Search staff member...',
                              items: [
                                SearchableDropdownItem<int?>(
                                  value: null,
                                  label: s.notNamedOption,
                                ),
                                ..._assignees.map((a) {
                                  return SearchableDropdownItem<int?>(
                                    value: a.id,
                                    label: a.department?.isNotEmpty == true
                                        ? '${a.name} (${a.department})'
                                        : a.name,
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(() => _selectedAboutUserId = v),
                            ),
                            const SizedBox(height: 16),
                          ] else if (_selectedAboutKind == 'department') ...[
                            _buildLabel(s.departmentLabel),
                            const SizedBox(height: 6),
                            SearchableFilterDropdown<int?>(
                              value: _selectedAboutDepartmentId,
                              hint: s.departmentLabel,
                              searchHint: 'Search department...',
                              items: [
                                SearchableDropdownItem<int?>(
                                  value: null,
                                  label: s.notNamedOption,
                                ),
                                ..._departments.map((d) {
                                  return SearchableDropdownItem<int?>(
                                    value: d.id,
                                    label: d.name,
                                  );
                                }),
                              ],
                              onChanged: (v) => setState(() => _selectedAboutDepartmentId = v),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Category
                          _buildLabel(s.categoryLabel),
                          const SizedBox(height: 6),
                          SearchableFilterDropdown<String>(
                            value: _meta.categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : (_meta.categories.isNotEmpty ? _meta.categories.first : 'Other'),
                            hint: s.categoryLabel,
                            searchHint: 'Search category...',
                            items: _meta.categories
                                .map((cat) => SearchableDropdownItem<String>(value: cat, label: cat))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCategory = v);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Priority Selector & SLA Note
                          _buildLabel(s.priorityLabel),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPillButton(
                                title: s.priorityEmergency,
                                isSelected: _selectedPriority == 'emergency',
                                onTap: () => setState(() => _selectedPriority = 'emergency'),
                              ),
                              _buildPillButton(
                                title: s.priorityTopMost,
                                isSelected: _selectedPriority == 'top_most',
                                onTap: () => setState(() => _selectedPriority = 'top_most'),
                              ),
                              _buildPillButton(
                                title: s.priorityHigh,
                                isSelected: _selectedPriority == 'high',
                                onTap: () => setState(() => _selectedPriority = 'high'),
                              ),
                              _buildPillButton(
                                title: s.priorityMedium,
                                isSelected: _selectedPriority == 'medium',
                                onTap: () => setState(() => _selectedPriority = 'medium'),
                              ),
                              _buildPillButton(
                                title: s.priorityLow,
                                isSelected: _selectedPriority == 'low',
                                onTap: () => setState(() => _selectedPriority = 'low'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.targetDateDaysFromToday(slaDays),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Visibility
                          _buildLabel(s.visibilityLabel),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedVisibility,
                            isExpanded: true,
                            decoration: _inputDecoration(isDark),
                            items: [
                              DropdownMenuItem<String>(
                                value: 'general',
                                child: Text(s.visibilityGeneral, style: const TextStyle(fontSize: 13)),
                              ),
                              DropdownMenuItem<String>(
                                value: 'confidential',
                                child: Text(s.visibilityConfidential, style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedVisibility = v);
                            },
                          ),
                          const SizedBox(height: 16),

                          // What was said? *
                          _buildLabel(s.whatWasSaidLabel),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: _inputDecoration(isDark, hintText: s.whatWasSaidHint),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 16),

                          // Evidence & File attachment
                          _buildLabel(s.evidenceLabel),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isUploadingFile ? null : _pickAndUploadFile,
                                icon: _isUploadingFile
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.attach_file_rounded, size: 16),
                                label: Text(
                                  _isUploadingFile ? s.uploadingFile : s.addFileButton,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_attachments.isNotEmpty)
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _attachments.first.filename,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16),
                                        onPressed: () => setState(() => _attachments.clear()),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (_uploadError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _uploadError!,
                              style: const TextStyle(color: Colors.red, fontSize: 11),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Dynamic Ticket Creation Preview Banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              s.bannerTicketTaskCreated(
                                _meta.nextTicketNo.isNotEmpty ? _meta.nextTicketNo : 'TKT-...',
                                _meta.nextTaskNo.isNotEmpty ? _meta.nextTaskNo : 'TASK-...',
                                _meta.owner?.name.isNotEmpty == true ? _meta.owner!.name : 'Campus Head',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dialog Actions
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(s.cancelButton),
                          ),
                          const SizedBox(width: 12),
                          BlocBuilder<ComplaintsBloc, ComplaintsState>(
                            builder: (context, state) {
                              final isSubmitting = state is ComplaintsLoadedState && state.isSubmitting;
                              return ElevatedButton(
                                onPressed: isSubmitting ? null : _submitComplaint,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.button(context),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(s.registerComplaintButton),
                              );
                            },
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

  Widget _buildLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildPillButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF132A50)
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF132A50)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, {String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF132A50), width: 1.5),
      ),
    );
  }
}
