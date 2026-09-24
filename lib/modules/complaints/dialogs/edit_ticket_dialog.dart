import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../../shared_widgets/dropdowns/searchable_filter_dropdown.dart';
import '../models/lookup_models.dart';
import '../models/ticket_meta_model.dart';
import '../models/ticket_model.dart';
import '../repository/complaints_repository.dart';

class EditTicketDialog extends StatefulWidget {
  final TicketItemModel ticket;
  final VoidCallback? onSaved;

  const EditTicketDialog({
    super.key,
    required this.ticket,
    this.onSaved,
  });

  static Future<bool?> show(
    BuildContext context, {
    required TicketItemModel ticket,
    VoidCallback? onSaved,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => EditTicketDialog(
        ticket: ticket,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditTicketDialog> createState() => _EditTicketDialogState();
}

class _EditTicketDialogState extends State<EditTicketDialog> {
  final ComplaintsRepository _repository = ComplaintsRepository();

  late TextEditingController _studentNameController;
  late TextEditingController _classSectionController;
  late TextEditingController _admissionNoController;
  late TextEditingController _detailsController;
  late TextEditingController _descriptionController;
  late TextEditingController _reasonController;

  late String _selectedAboutKind;
  int? _selectedAboutUserId;
  int? _selectedAboutDepartmentId;
  late String _selectedCategory;
  late String _selectedPriority;
  late String _selectedVisibility;

  TicketMetaModel _meta = const TicketMetaModel();
  List<LookupDepartmentModel> _departments = [];
  List<LookupAssigneeModel> _assignees = [];

  bool _isLoadingInitial = true;
  bool _isSaving = false;
  bool _isUploadingFile = false;
  List<TicketAttachmentModel> _attachments = [];

  final List<String> _aboutKinds = [
    'staff',
    'department',
    'transport',
    'facility',
    'general',
  ];

  final List<String> _priorities = [
    'emergency',
    'top_most',
    'high',
    'medium',
    'low',
  ];

  final List<String> _visibilities = [
    'general',
    'confidential',
  ];

  @override
  void initState() {
    super.initState();
    _studentNameController = TextEditingController(text: widget.ticket.studentName ?? '');
    _classSectionController = TextEditingController(text: widget.ticket.classSection ?? '');
    _admissionNoController = TextEditingController(text: widget.ticket.admissionNo ?? '');
    _detailsController = TextEditingController(text: widget.ticket.aboutText ?? '');
    _descriptionController = TextEditingController(text: widget.ticket.description);
    _reasonController = TextEditingController();

    _selectedAboutKind = widget.ticket.aboutKind.isNotEmpty ? widget.ticket.aboutKind : 'general';
    _selectedAboutUserId = widget.ticket.aboutUserId;
    _selectedAboutDepartmentId = widget.ticket.aboutDepartmentId;
    _selectedCategory = widget.ticket.category.isNotEmpty ? widget.ticket.category : 'Other';
    _selectedPriority = widget.ticket.priority.isNotEmpty ? widget.ticket.priority : 'medium';
    _selectedVisibility = widget.ticket.visibility.isNotEmpty ? widget.ticket.visibility : 'general';
    _attachments = List.from(widget.ticket.attachments);

    _loadInitialData();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _classSectionController.dispose();
    _admissionNoController.dispose();
    _detailsController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _repository.getTicketMeta(branchId: widget.ticket.branchId),
        _repository.getDepartments(),
        _repository.getAssignees(),
      ]);

      if (mounted) {
        setState(() {
          _meta = results[0] as TicketMetaModel;
          _departments = results[1] as List<LookupDepartmentModel>;
          _assignees = results[2] as List<LookupAssigneeModel>;
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

  Future<void> _pickAndUploadFile() async {
    try {
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result == null) return;
      final List<dynamic> fileList = result is List ? result : (result.files as List);
      if (fileList.isEmpty) return;

      final dynamic file = fileList.first;
      final String? filePath = (file as dynamic).path?.toString();
      final String filename = (file as dynamic).name?.toString() ?? 'attachment';
      if (filePath == null) return;

      setState(() {
        _isUploadingFile = true;
      });

      final uploaded = await _repository.uploadFile(filePath: filePath, filename: filename);
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File upload failed: $e')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('What was said is required.')),
      );
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reason for this change is required.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final payload = <String, dynamic>{
        'student_name': _studentNameController.text.trim(),
        'class_section': _classSectionController.text.trim(),
        'admission_no': _admissionNoController.text.trim(),
        'about_kind': _selectedAboutKind,
        if (_selectedAboutKind == 'staff') 'about_user_id': _selectedAboutUserId,
        if (_selectedAboutKind == 'department') 'about_department_id': _selectedAboutDepartmentId,
        'about_text': _detailsController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'visibility': _selectedVisibility,
        'description': _descriptionController.text.trim(),
        'reason': _reasonController.text.trim(),
        'attachments': _attachments.map((a) => a.toJson()).toList(),
      };

      await _repository.updateTicket(widget.ticket.id, payload);

      if (mounted) {
        widget.onSaved?.call();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  String _formatAboutKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'staff':
        return 'Staff member';
      case 'department':
        return 'Department';
      case 'transport':
        return 'Transport';
      case 'facility':
        return 'Facility';
      default:
        return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);

    final categories = _meta.categories.isNotEmpty
        ? _meta.categories
        : ['Other', 'Transport', 'Food / canteen', 'Academics', 'Behavior', 'Facilities', 'Admin / Fees'];

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('✏️ ', style: TextStyle(fontSize: 18)),
                      Text(
                        '${s.editTicketTitlePrefix} ${widget.ticket.ticketNo}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: labelColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _isLoadingInitial
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Student name, Class & section, Admission no.
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 500) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        label: s.studentNameLabel,
                                        controller: _studentNameController,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildTextField(
                                        label: s.classAndSectionLabel,
                                        controller: _classSectionController,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildTextField(
                                        label: s.admissionNoLabel,
                                        controller: _admissionNoController,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildTextField(
                                    label: s.studentNameLabel,
                                    controller: _studentNameController,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    label: s.classAndSectionLabel,
                                    controller: _classSectionController,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    label: s.admissionNoLabel,
                                    controller: _admissionNoController,
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // About and Details
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 500) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: s.aboutLabel,
                                        value: _selectedAboutKind,
                                        items: _aboutKinds,
                                        displayText: (val) => _formatAboutKind(val),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              _selectedAboutKind = val;
                                            });
                                          }
                                        },
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildTextField(
                                        label: s.detailsLabel,
                                        controller: _detailsController,
                                        placeholder: 'e.g. Bus 4',
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildDropdownField(
                                    label: s.aboutLabel,
                                    value: _selectedAboutKind,
                                    items: _aboutKinds,
                                    displayText: (val) => _formatAboutKind(val),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedAboutKind = val;
                                        });
                                      }
                                    },
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    label: s.detailsLabel,
                                    controller: _detailsController,
                                    placeholder: 'e.g. Bus 4',
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Category, Priority, Visibility
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth > 500) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _buildSearchableDropdown(
                                        label: s.categoryLabel,
                                        value: _selectedCategory,
                                        items: categories,
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedCategory = val);
                                        },
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: s.priorityLabel,
                                        value: _selectedPriority,
                                        items: _priorities,
                                        displayText: (v) => v,
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedPriority = val);
                                        },
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: s.visibilityLabel,
                                        value: _selectedVisibility,
                                        items: _visibilities,
                                        displayText: (v) => v == 'confidential' ? 'Confidential' : 'General',
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedVisibility = val);
                                        },
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildSearchableDropdown(
                                    label: s.categoryLabel,
                                    value: _selectedCategory,
                                    items: categories,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCategory = val);
                                    },
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDropdownField(
                                    label: s.priorityLabel,
                                    value: _selectedPriority,
                                    items: _priorities,
                                    displayText: (v) => v,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedPriority = val);
                                    },
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDropdownField(
                                    label: s.visibilityLabel,
                                    value: _selectedVisibility,
                                    items: _visibilities,
                                    displayText: (v) => v == 'confidential' ? 'Confidential' : 'General',
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedVisibility = val);
                                    },
                                    isDark: isDark,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // What was said *
                          _buildTextField(
                            label: s.whatWasSaidLabel,
                            controller: _descriptionController,
                            maxLines: 3,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          // Add evidence
                          Text(
                            s.addEvidenceLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                          ),
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
                                    : const Icon(Icons.attach_file, size: 16),
                                label: Text(s.addFileButton),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_attachments.isNotEmpty)
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _attachments.map((att) {
                                      return Chip(
                                        label: Text(
                                          att.filename,
                                          style: const TextStyle(fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            _attachments.remove(att);
                                          });
                                        },
                                        deleteIconColor: Colors.red,
                                        backgroundColor: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFF1F5F9),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Reason for this change *
                          _buildTextField(
                            label: s.reasonForChangeLabel,
                            controller: _reasonController,
                            placeholder: s.reasonForChangePlaceholder,
                            maxLines: 3,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text(s.cancelButton),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            s.saveChangesButton,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    int maxLines = 1,
    required bool isDark,
  }) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);
    final fillBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: fillBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required String Function(String) displayText,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);
    final fillBg = isDark ? const Color(0xFF0F172A) : Colors.white;

    final selectedValue = items.contains(value) ? value : (items.isNotEmpty ? items.first : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fillBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue.isNotEmpty ? selectedValue : null,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    displayText(e),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF475569);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        SearchableFilterDropdown<String>(
          value: items.contains(value) ? value : (items.isNotEmpty ? items.first : ''),
          hint: label,
          searchHint: 'Search $label...',
          items: items
              .map((item) => SearchableDropdownItem<String>(value: item, label: item))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
