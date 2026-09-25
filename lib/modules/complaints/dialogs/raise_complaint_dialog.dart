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
import '../models/draft_model.dart';
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
  String _selectedSource = 'parent'; // 'parent', 'student', 'staff'
  String _selectedChannel = 'whatsapp_group';
  final TextEditingController _channelDetailController = TextEditingController();
  DateTime _receivedAt = DateTime.now();

  int? _selectedBranchId;
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _classSectionController = TextEditingController();
  final TextEditingController _admissionNoController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentMobileController = TextEditingController();
  bool _isAnonymous = false;

  String _selectedAboutKind = 'staff'; // 'staff', 'department', 'transport', 'facility', 'general'
  int? _selectedAboutUserId;
  int? _selectedAboutDepartmentId;

  String _selectedCategory = 'Other';
  String _selectedPriority = 'medium'; // 'emergency', 'top_most', 'high', 'medium', 'low'
  String _selectedVisibility = 'general'; // 'general', 'confidential'
  final TextEditingController _descriptionController = TextEditingController();

  // Drafts state
  List<DraftItemModel> _savedDrafts = [];
  bool _isLoadingDrafts = false;
  bool _isSavingDraft = false;

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
    _loadDrafts();
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
        _repository.getTicketMeta(source: _selectedSource),
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

  Future<void> _loadDrafts() async {
    try {
      final drafts = await _repository.getDrafts(kind: 'ticket');
      if (mounted) {
        setState(() {
          _savedDrafts = drafts;
        });
      }
    } catch (_) {}
  }

  Future<void> _onSourceChanged(String newSource) async {
    if (newSource == _selectedSource) return;
    setState(() {
      _selectedSource = newSource;
    });

    try {
      final updatedMeta = await _repository.getTicketMeta(
        branchId: _selectedBranchId,
        source: newSource,
      );
      if (mounted) {
        setState(() {
          _meta = updatedMeta;
          if (_meta.channels.isNotEmpty &&
              !_meta.channels.any((c) => c.value == _selectedChannel)) {
            _selectedChannel = _meta.channels.first.value;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onBranchChanged(int? newBranchId) async {
    if (newBranchId == null || newBranchId == _selectedBranchId) return;
    setState(() {
      _selectedBranchId = newBranchId;
    });

    try {
      final updatedMeta = await _repository.getTicketMeta(
        branchId: newBranchId,
        source: _selectedSource,
      );
      if (mounted) {
        setState(() {
          _meta = updatedMeta;
        });
      }
    } catch (_) {}
  }

  Future<void> _resumeDraft(DraftItemModel draft) async {
    setState(() {
      _isLoadingDrafts = true;
    });
    try {
      DraftPayloadModel? payload = draft.payload;
      if (payload == null) {
        final detail = await _repository.getDraftDetail(draft.id);
        payload = detail?.payload;
      }
      if (payload != null) {
        final targetBranchId = payload.branchId ?? _selectedBranchId;
        final targetSource = payload.source.isNotEmpty ? payload.source : _selectedSource;

        final updatedMeta = await _repository.getTicketMeta(
          branchId: targetBranchId,
          source: targetSource,
        );

        DateTime? parsedDate;
        if (payload.receivedAt != null && payload.receivedAt!.isNotEmpty) {
          try {
            parsedDate = DateTime.parse(payload.receivedAt!).toLocal();
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _meta = updatedMeta;
            _selectedType = payload!.type.isNotEmpty ? payload.type : 'complaint';
            _selectedSource = targetSource;
            if (payload.channel.isNotEmpty) {
              _selectedChannel = payload.channel;
            }
            _channelDetailController.text = payload.channelDetail ?? '';
            if (parsedDate != null) {
              _receivedAt = parsedDate;
            }
            if (payload.branchId != null) {
              _selectedBranchId = payload.branchId;
            }
            _studentNameController.text = payload.studentName ?? '';
            _classSectionController.text = payload.classSection ?? '';
            _admissionNoController.text = payload.admissionNo ?? '';
            _parentNameController.text = payload.parentName ?? '';
            _parentMobileController.text = payload.parentMobile ?? '';
            _isAnonymous = payload.isAnonymous;
            _selectedVisibility = payload.visibility ?? 'general';
            _selectedAboutKind = payload.aboutKind ?? 'staff';
            _selectedAboutUserId = payload.aboutUserId;
            _selectedAboutDepartmentId = payload.aboutDepartmentId;
            if (payload.category != null && payload.category!.isNotEmpty) {
              _selectedCategory = payload.category!;
            }
            if (payload.priority != null && payload.priority!.isNotEmpty) {
              _selectedPriority = payload.priority!;
            }
            _descriptionController.text = payload.description ?? '';
            _attachments = List.from(payload.attachments);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).draftResumedSuccess),
              backgroundColor: const Color(0xFF132A50),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[RaiseComplaintDialog] error resuming draft: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDrafts = false;
        });
      }
    }
  }

  Future<void> _deleteDraft(int draftId) async {
    final s = AppStrings.of(context);
    final success = await _repository.deleteDraft(draftId);
    if (success && mounted) {
      setState(() {
        _savedDrafts.removeWhere((d) => d.id == draftId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.draftDeletedSuccess),
          backgroundColor: Colors.grey.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveDraft() async {
    final s = AppStrings.of(context);
    final desc = _descriptionController.text.trim();
    final studentName = _studentNameController.text.trim();

    if (desc.isEmpty && studentName.isEmpty && _selectedAboutUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.fillRequiredFieldsDraftError),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });

    try {
      DateTime safeReceivedAt = _receivedAt;
      final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm").format(safeReceivedAt);

      String typeTitle = 'Complaint';
      if (_selectedType == 'appreciation') {
        typeTitle = 'Appreciation';
      } else if (_selectedType == 'feedback') {
        typeTitle = 'Feedback';
      }

      String subject = studentName;
      if (subject.isEmpty) {
        if (_selectedAboutUserId != null) {
          final assignee = _assignees.where((a) => a.id == _selectedAboutUserId).firstOrNull;
          subject = assignee?.name ?? 'staff';
        } else {
          subject = _selectedSource;
        }
      }

      final draftDesc = desc.isNotEmpty ? desc : 'testing';
      final label = '$typeTitle · $subject — $draftDesc';

      final payload = DraftPayloadModel(
        type: _selectedType,
        source: _selectedSource,
        channel: _selectedChannel,
        channelDetail: _channelDetailController.text.trim(),
        receivedAt: formattedDate,
        branchId: _selectedBranchId,
        studentName: _selectedSource == 'staff' ? '' : studentName,
        classSection: _selectedSource == 'staff' ? '' : _classSectionController.text.trim(),
        admissionNo: _selectedSource == 'staff' ? '' : _admissionNoController.text.trim(),
        parentName: _selectedSource == 'parent' ? _parentNameController.text.trim() : '',
        parentMobile: _selectedSource == 'parent' ? _parentMobileController.text.trim() : '',
        isAnonymous: _isAnonymous,
        visibility: _selectedType == 'appreciation' ? 'general' : _selectedVisibility,
        aboutKind: _selectedAboutKind,
        aboutUserId: _selectedAboutKind == 'staff' ? _selectedAboutUserId : null,
        aboutDepartmentId: _selectedAboutKind == 'department' ? _selectedAboutDepartmentId : null,
        aboutText: '',
        category: _selectedCategory,
        priority: _selectedType == 'appreciation' ? 'low' : _selectedPriority,
        description: desc,
        attachments: _attachments,
      );

      final req = DraftSaveRequest(kind: 'ticket', label: label, payload: payload);
      await _repository.saveDraft(req);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.draftSavedSuccess),
            backgroundColor: const Color(0xFF132A50),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadDrafts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
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

    if (_selectedSource != 'staff') {
      if (studentName.isEmpty || classSection.isEmpty || description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.fillRequiredFieldsError), backgroundColor: Colors.red.shade700),
        );
        return;
      }
    } else {
      if (description.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.fillRequiredFieldsError), backgroundColor: Colors.red.shade700),
        );
        return;
      }
    }

    final mobile = _parentMobileController.text.trim();
    if (_selectedSource == 'parent' && mobile.isNotEmpty && mobile.length != 10) {
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
      studentName: _selectedSource == 'staff' ? '' : studentName,
      classSection: _selectedSource == 'staff' ? '' : classSection,
      admissionNo: _selectedSource == 'staff' ? '' : _admissionNoController.text.trim(),
      parentName: _selectedSource == 'parent' ? _parentNameController.text.trim() : '',
      parentMobile: _selectedSource == 'parent' ? mobile : '',
      isAnonymous: _isAnonymous,
      visibility: _selectedType == 'appreciation' ? 'general' : _selectedVisibility,
      aboutKind: _selectedAboutKind,
      aboutUserId: _selectedAboutKind == 'staff' ? _selectedAboutUserId : null,
      aboutDepartmentId: _selectedAboutKind == 'department' ? _selectedAboutDepartmentId : null,
      aboutText: '',
      category: _selectedCategory,
      priority: _selectedType == 'appreciation' ? 'low' : _selectedPriority,
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
                          // Saved Drafts Banner
                          if (_savedDrafts.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2A1B1F) : const Color(0xFFFFF7F7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF5A2A33) : const Color(0xFFFECDD3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('🌯', style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        s.savedDraftsCount(_savedDrafts.length),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ..._savedDrafts.map((draft) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: _isLoadingDrafts ? null : () => _resumeDraft(draft),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.reply_rounded,
                                                    size: 14,
                                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    s.resumeButton,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDark ? Colors.white : const Color(0xFF334155),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              draft.label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            draft.formattedDisplayDate,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _deleteDraft(draft.id),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 15,
                                                color: Colors.red.shade400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],

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
                                onTap: () => _onSourceChanged('parent'),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                title: s.receivedFromStudent,
                                isSelected: _selectedSource == 'student',
                                onTap: () => _onSourceChanged('student'),
                              ),
                              const SizedBox(width: 8),
                              _buildPillButton(
                                title: s.receivedFromStaff,
                                isSelected: _selectedSource == 'staff',
                                onTap: () => _onSourceChanged('staff'),
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

                          // If Staff member, show Anonymous Checkbox right under Received On & Branch
                          if (_selectedSource == 'staff') ...[
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
                                          s.raiseAnonymously,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          s.raiseAnonymouslyDesc,
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
                          ],

                          // Student details (shown only if NOT staff)
                          if (_selectedSource != 'staff') ...[
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
                          ],

                          // Parent details (shown only if Parent)
                          if (_selectedSource == 'parent') ...[
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

                            // Anonymous Checkbox for Parent
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
                          ],

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
                            _buildLabel(
                              _selectedType == 'appreciation'
                                  ? s.staffMemberAppreciationSubtitle(
                                      _meta.appreciationPoints > 0 ? _meta.appreciationPoints : 50)
                                  : s.staffMemberSubtext,
                            ),
                            const SizedBox(height: 6),
                            SearchableFilterDropdown<int?>(
                              value: _selectedAboutUserId,
                              hint: _selectedType == 'appreciation'
                                  ? s.staffMemberDirectorDecides
                                  : s.staffMemberSubtext,
                              searchHint: 'Search staff member...',
                              items: [
                                SearchableDropdownItem<int?>(
                                  value: null,
                                  label: _selectedType == 'appreciation'
                                      ? s.staffMemberDirectorDecides
                                      : s.notNamedOption,
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

                          // Priority Selector & SLA Note (only shown if NOT appreciation)
                          if (_selectedType != 'appreciation') ...[
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
                          ],

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
                          OutlinedButton.icon(
                            onPressed: _isSavingDraft ? null : _saveDraft,
                            icon: _isSavingDraft
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('💾', style: TextStyle(fontSize: 14)),
                            label: Text(
                              s.saveDraftButton,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          BlocBuilder<ComplaintsBloc, ComplaintsState>(
                            builder: (context, state) {
                              final isSubmitting = state is ComplaintsLoadedState && state.isSubmitting;
                              final buttonColor = _selectedType == 'appreciation'
                                  ? const Color(0xFF132A50)
                                  : (_selectedType == 'complaint'
                                      ? const Color(0xFF991B1B)
                                      : AppColors.button(context));
                              return ElevatedButton(
                                onPressed: isSubmitting ? null : _submitComplaint,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
                                    : Text(
                                        _selectedType == 'appreciation'
                                            ? s.recordAppreciationButton
                                            : s.registerComplaintButton,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
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
