import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../tasks/screens/all_tasks_screen.dart';
import '../models/lookup_models.dart';
import '../models/ticket_model.dart';
import '../repository/complaints_repository.dart';
import 'edit_ticket_dialog.dart';

class TicketDetailsDialog extends StatefulWidget {
  final int ticketId;
  final VoidCallback? onUpdated;

  const TicketDetailsDialog({
    super.key,
    required this.ticketId,
    this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required int ticketId,
    VoidCallback? onUpdated,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => TicketDetailsDialog(
        ticketId: ticketId,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<TicketDetailsDialog> createState() => _TicketDetailsDialogState();
}

class _TicketDetailsDialogState extends State<TicketDetailsDialog> {
  final ComplaintsRepository _repository = ComplaintsRepository();

  TicketItemModel? _ticket;
  bool _isLoading = true;
  String? _errorMessage;

  // Assign Section State
  bool _isAssignOpen = false;
  List<LookupAssigneeModel> _allAssignees = [];
  List<LookupAssigneeModel> _filteredAssignees = [];
  final Set<int> _selectedAssigneeIds = {};
  final TextEditingController _assignSearchController = TextEditingController();
  final TextEditingController _assignNoteController = TextEditingController();
  bool _isSubmittingAssign = false;

  // Close The Loop State
  String _closeLoopTab = 'resolve'; // 'resolve' or 'reject'
  final TextEditingController _resolutionController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();
  bool _isSubmittingCloseLoop = false;

  // Reward / Award Section State (for Appreciation in Director Login)
  int? _selectedAwardFacultyId;
  final TextEditingController _awardPointsController = TextEditingController(text: '50');
  final TextEditingController _awardReasonController = TextEditingController();
  bool _isSubmittingAward = false;

  @override
  void initState() {
    super.initState();
    _fetchTicketDetails();
    _fetchAssignees();
  }

  @override
  void dispose() {
    _assignSearchController.dispose();
    _assignNoteController.dispose();
    _resolutionController.dispose();
    _rejectReasonController.dispose();
    _awardPointsController.dispose();
    _awardReasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchTicketDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticket = await _repository.getTicketById(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _isLoading = false;
          _selectedAwardFacultyId ??= ticket.awardedUserId ?? ticket.aboutUserId;
          if (ticket.pointsAwarded != null && ticket.pointsAwarded! > 0) {
            _awardPointsController.text = ticket.pointsAwarded.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _fetchAssignees() async {
    try {
      final list = await _repository.getAssignees();
      if (mounted) {
        setState(() {
          _allAssignees = list;
          _filteredAssignees = list;
          if (_selectedAwardFacultyId == null && _ticket != null) {
            _selectedAwardFacultyId = _ticket!.awardedUserId ?? _ticket!.aboutUserId;
          }
        });
      }
    } catch (_) {}
  }

  void _filterAssignees(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredAssignees = _allAssignees;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredAssignees = _allAssignees
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.department!.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _handleAssign() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (_selectedAssigneeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one assignee.')),
      );
      return;
    }

    if (_assignNoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter what they should do.')),
      );
      return;
    }

    setState(() {
      _isSubmittingAssign = true;
    });

    try {
      final updated = await _repository.assignTicket(
        widget.ticketId,
        assigneeIds: _selectedAssigneeIds.toList(),
        note: _assignNoteController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _ticket = updated;
          _isAssignOpen = false;
          _isSubmittingAssign = false;
          _assignNoteController.clear();
          _selectedAssigneeIds.clear();
        });
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket assigned successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingAssign = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _handleResolve() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (_resolutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter resolution comments.')),
      );
      return;
    }

    setState(() {
      _isSubmittingCloseLoop = true;
    });

    try {
      final updated = await _repository.resolveTicket(
        widget.ticketId,
        resolution: _resolutionController.text.trim(),
        notifyParent: false,
      );

      if (mounted) {
        setState(() {
          _ticket = updated;
          _isSubmittingCloseLoop = false;
          _resolutionController.clear();
        });
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket resolved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingCloseLoop = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _handleReject() async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (_rejectReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason why ticket is not valid.')),
      );
      return;
    }

    setState(() {
      _isSubmittingCloseLoop = true;
    });

    try {
      final updated = await _repository.rejectTicket(
        widget.ticketId,
        reason: _rejectReasonController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _ticket = updated;
          _isSubmittingCloseLoop = false;
          _rejectReasonController.clear();
        });
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket closed as not valid.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingCloseLoop = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _handleAwardPoints(AppStrings s) async {
    final hasNet = await NetworkConnectivityService().checkConnection();
    if (!hasNet && mounted) {
      NoInternetDialog.showForceLogout(context);
      return;
    }

    if (_selectedAwardFacultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.selectFacultyPrompt)),
      );
      return;
    }

    final points = int.tryParse(_awardPointsController.text.trim()) ?? 0;
    if (points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pleaseEnterPoints)),
      );
      return;
    }

    final reason = _awardReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pleaseEnterReason)),
      );
      return;
    }

    setState(() {
      _isSubmittingAward = true;
    });

    try {
      final updated = await _repository.awardTicket(
        ticketId: widget.ticketId,
        userId: _selectedAwardFacultyId!,
        points: points,
        reason: reason,
      );

      if (mounted) {
        setState(() {
          _ticket = updated;
          _isSubmittingAward = false;
          _awardReasonController.clear();
        });
        widget.onUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.pointsUpdatedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmittingAward = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _showFacultyPicker(AppStrings s, bool isDark, Color textColor, Color labelColor, Color borderColor) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _allAssignees.where((a) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase();
              final name = a.name.toLowerCase();
              final dept = (a.department ?? '').toLowerCase();
              return name.contains(q) || dept.contains(q);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.selectFacultyPrompt,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: labelColor),
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (val) {
                        setModalState(() {
                          query = val;
                        });
                      },
                      style: TextStyle(fontSize: 12.5, color: textColor),
                      decoration: InputDecoration(
                        hintText: s.searchFacultyPlaceholder,
                        hintStyle: TextStyle(fontSize: 12, color: labelColor),
                        prefixIcon: Icon(Icons.search, size: 16, color: labelColor),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('No faculty found', style: TextStyle(fontSize: 12, color: labelColor)),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final f = filtered[idx];
                                final isSelected = f.id == _selectedAwardFacultyId;
                                final displayName = f.department?.isNotEmpty == true
                                    ? '${f.name} · ${f.department}'
                                    : f.name;

                                return ListTile(
                                  dense: true,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  tileColor: isSelected
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                      : null,
                                  title: Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: textColor,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Color(0xFF3B82F6))
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedAwardFacultyId = f.id;
                                    });
                                    Navigator.of(dialogCtx).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEditTicket() async {
    if (_ticket == null) return;
    final saved = await EditTicketDialog.show(
      context,
      ticket: _ticket!,
      onSaved: () {
        _fetchTicketDetails();
        widget.onUpdated?.call();
      },
    );
    if (saved == true && mounted) {
      _fetchTicketDetails();
      widget.onUpdated?.call();
    }
  }

  void _navigateToAllTasks([TicketItemModel? ticket]) {
    final t = ticket ?? _ticket;
    int? targetTaskId = t?.taskId;
    if (targetTaskId == null && t?.taskNo != null && t!.taskNo!.isNotEmpty) {
      targetTaskId = int.tryParse(t.taskNo!.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AllTasksScreen(
          initialTaskId: targetTaskId,
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final datePart = DateFormat('d MMM yyyy').format(dt);
      final timePart = DateFormat('hh:mm a').format(dt).toLowerCase();
      return '$datePart, $timePart';
    } catch (_) {
      return raw;
    }
  }

  String _formatSimpleDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF3B82F6);
    try {
      String clean = hex.replaceAll('#', '');
      if (clean.length == 6) clean = 'FF$clean';
      return Color(int.parse('0x$clean'));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 880,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(s, isDark, textColor, labelColor, borderColor),

            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchTicketDetails,
                                  child: Text(s.retryButton),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildBody(s, isDark, textColor, labelColor, borderColor),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    ),
                    child: Text(s.closeButton),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    final ticket = _ticket;
    final isConfidential = ticket?.visibility.toLowerCase() == 'confidential';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  ticket?.ticketNo ?? 'TICKET',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (ticket != null) ...[
                  _buildTypePill(ticket.type, isDark),
                  _buildStatusPill(ticket.status, isDark),
                  if (isConfidential)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔒 ', style: TextStyle(fontSize: 10)),
                          Text(
                            s.confidentialBadge,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ticket != null && ticket.canManage)
                OutlinedButton.icon(
                  onPressed: _openEditTicket,
                  icon: const Text('✏️', style: TextStyle(fontSize: 12)),
                  label: Text(
                    s.editTicketButton,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: labelColor, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    final ticket = _ticket!;
    final isDesktop = MediaQuery.of(context).size.width > 680;

    final authState = context.read<AuthBloc>().state;
    bool isDirector = false;
    if (authState is AuthenticatedState) {
      final role = authState.userProfile.role.toLowerCase();
      final roleLabel = authState.userProfile.roleLabel.toLowerCase();
      isDirector = role.contains('director') || roleLabel.contains('director');
    }

    final isAppreciation = ticket.type.toLowerCase() == 'appreciation';
    final isParent = ticket.source.toLowerCase() == 'parent';
    final isClosed = isAppreciation ||
        ticket.status.toLowerCase() == 'resolved' ||
        ticket.status.toLowerCase() == 'rejected' ||
        ticket.status.toLowerCase() == 'closed' ||
        ticket.status.toLowerCase() == 'not_valid' ||
        ticket.status.toLowerCase() == 'not valid' ||
        (ticket.resolution != null && ticket.resolution!.trim().isNotEmpty);

    final hasAssignee = ticket.taskAssignees.isNotEmpty ||
        ticket.events.any((e) =>
            e.kind.toLowerCase() == 'assigned' &&
            (e.note.toLowerCase().startsWith('assigned to') ||
             e.note.toLowerCase().contains(' — ')));

    final statusLower = ticket.status.toLowerCase();
    final isStatusNew = statusLower == 'new';
    final isTerminal = statusLower == 'closed' ||
        statusLower == 'not_valid' ||
        statusLower == 'not valid' ||
        statusLower == 'rejected' ||
        statusLower == 'resolved';

    // In Director login: Close the loop and Assign to button only when status is new, and not when closed, not valid, reject, or resolved
    final bool canShowAssignButton;
    final bool shouldShowCloseLoopSection;

    if (isDirector) {
      canShowAssignButton = !isAppreciation && isStatusNew && !isTerminal;
      shouldShowCloseLoopSection = !isAppreciation && isStatusNew && !isTerminal;
    } else {
      canShowAssignButton = false;
      shouldShowCloseLoopSection = false;
    }

    final hasResolution = isAppreciation ||
        ticket.status.toLowerCase() == 'resolved' ||
        ticket.status.toLowerCase() == 'rejected' ||
        ticket.status.toLowerCase() == 'closed' ||
        (ticket.resolution != null && ticket.resolution!.trim().isNotEmpty);

    final hasEvidence = ticket.attachmentsHidden || ticket.attachments.isNotEmpty;

    final showDirectorRewardCard = isAppreciation &&
        isDirector &&
        (statusLower == 'recorded' || ticket.canAward);

    final Widget? rewardCardWidget = (isAppreciation && isDirector)
        ? (showDirectorRewardCard
            ? _buildDirectorRewardCard(ticket, s, isDark, textColor, labelColor, borderColor)
            : _buildRewardCard(ticket, s, isDark, textColor, labelColor, borderColor))
        : null;

    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Details & History)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescriptionCard(ticket, isDark, textColor),
                  const SizedBox(height: 18),
                  _buildDetailsSection(ticket, s, isDark, textColor, labelColor),
                  if (hasResolution) ...[
                    const SizedBox(height: 18),
                    _buildClosedResolutionSection(ticket, s, isDark, textColor, labelColor, borderColor),
                  ],
                  if (hasEvidence) ...[
                    const SizedBox(height: 18),
                    _buildEvidenceSection(ticket, s, isDark, textColor, labelColor, borderColor),
                  ],
                  const SizedBox(height: 18),
                  _buildHistorySection(ticket, s, isDark, textColor, labelColor, borderColor),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Right Column (Linked Task, Assign, Close the Loop, or Reward)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAppreciation && isDirector && rewardCardWidget != null) ...[
                    rewardCardWidget,
                  ] else if (!isAppreciation) ...[
                    _buildLinkedTaskCard(
                      ticket,
                      s,
                      isDark,
                      textColor,
                      labelColor,
                      borderColor,
                      canShowAssignButton: canShowAssignButton,
                    ),
                    if (_isAssignOpen && canShowAssignButton) ...[
                      const SizedBox(height: 16),
                      _buildAssignTicketCard(ticket, s, isDark, textColor, labelColor, borderColor),
                    ] else if (shouldShowCloseLoopSection) ...[
                      const SizedBox(height: 16),
                      _buildCloseLoopCard(ticket, s, isDark, textColor, labelColor, borderColor),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout: single scroll column
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAppreciation && isDirector && rewardCardWidget != null) ...[
            rewardCardWidget,
            const SizedBox(height: 16),
          ] else if (!isAppreciation) ...[
            _buildLinkedTaskCard(
              ticket,
              s,
              isDark,
              textColor,
              labelColor,
              borderColor,
              canShowAssignButton: canShowAssignButton,
            ),
            if (_isAssignOpen && canShowAssignButton) ...[
              const SizedBox(height: 16),
              _buildAssignTicketCard(ticket, s, isDark, textColor, labelColor, borderColor),
            ] else if (shouldShowCloseLoopSection) ...[
              const SizedBox(height: 16),
              _buildCloseLoopCard(ticket, s, isDark, textColor, labelColor, borderColor),
            ],
            const SizedBox(height: 18),
          ],
          _buildDescriptionCard(ticket, isDark, textColor),
          const SizedBox(height: 18),
          _buildDetailsSection(ticket, s, isDark, textColor, labelColor),
          if (hasResolution) ...[
            const SizedBox(height: 18),
            _buildClosedResolutionSection(ticket, s, isDark, textColor, labelColor, borderColor),
          ],
          if (hasEvidence) ...[
            const SizedBox(height: 18),
            _buildEvidenceSection(ticket, s, isDark, textColor, labelColor, borderColor),
          ],
          const SizedBox(height: 18),
          _buildHistorySection(ticket, s, isDark, textColor, labelColor, borderColor),
        ],
      ),
    );
  }

  /// Description box with vertical accent line on left
  Widget _buildDescriptionCard(TicketItemModel ticket, bool isDark, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.5,
            height: 22,
            margin: const EdgeInsets.only(right: 12, top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              ticket.description.isNotEmpty ? ticket.description : 'No description provided',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Details metadata section
  Widget _buildDetailsSection(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
  ) {
    final fromLabel = '${ticket.source.toUpperCase().substring(0, 1)}${ticket.source.substring(1)} · '
        '${ticket.channelLabel ?? ticket.channel}'
        '${ticket.channelDetail?.isNotEmpty == true ? " — ${ticket.channelDetail}" : ""}';

    final studentLabel = ticket.studentName?.isNotEmpty == true
        ? '${ticket.studentName} · ${ticket.classSection ?? ""}'
        : '—';

    final isParentHidden = ticket.isAnonymous || ticket.parentHidden;
    final parentLabel = isParentHidden
        ? s.anonymousHidden
        : (ticket.parentName?.isNotEmpty == true
            ? '${ticket.parentName} · ${ticket.parentMobile ?? ""}'
            : '—');

    final aboutLabel = ticket.aboutUserName?.isNotEmpty == true
        ? 'Staff — ${ticket.aboutUserName}'
        : (ticket.aboutDepartmentName?.isNotEmpty == true
            ? 'Department — ${ticket.aboutDepartmentName}'
            : (ticket.aboutText?.isNotEmpty == true ? ticket.aboutText! : '—'));

    final categoryLabel = '${ticket.category} · ${ticket.priority}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.detailsSectionLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        _buildDetailRow('From', fromLabel, isDark, textColor, labelColor),
        _buildDetailRow('Student', studentLabel, isDark, textColor, labelColor),
        _buildDetailRow('Parent', parentLabel, isDark, textColor, labelColor, isPill: isParentHidden),
        _buildDetailRow('About', aboutLabel, isDark, textColor, labelColor),
        _buildDetailRow('Category', categoryLabel, isDark, textColor, labelColor),
        _buildDetailRow('Received', _formatDate(ticket.receivedAt), isDark, textColor, labelColor),
        _buildDetailRow('Raised by', '${ticket.raisedByName ?? "Admin"} · ${_formatDate(ticket.createdAt)}', isDark, textColor, labelColor),
        if (ticket.branchName?.isNotEmpty == true)
          _buildDetailRow('Branch', ticket.branchName!, isDark, textColor, labelColor),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark,
    Color textColor,
    Color labelColor, {
    bool isPill = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
              ),
            ),
          ),
          Expanded(
            child: isPill
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Evidence Section
  Widget _buildEvidenceSection(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    if (!ticket.attachmentsHidden && ticket.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.evidenceLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        if (ticket.attachmentsHidden)
          Text(
            s.evidenceVisibleCampusHeadOnly,
            style: TextStyle(
              fontSize: 11.5,
              color: labelColor,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (ticket.attachments.isNotEmpty)
          Column(
            children: ticket.attachments.map((att) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        att.filename,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2563EB),
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading ${att.filename}...')),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        s.downloadLabel,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Closed / Resolved Resolution Section
  Widget _buildClosedResolutionSection(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    String note = ticket.resolution ?? '';
    String actor = ticket.resolvedByName ?? '';
    String? timestamp = ticket.resolvedAt;

    if (note.isEmpty || actor.isEmpty) {
      final closeEvent = ticket.events.cast<TicketEventModel?>().firstWhere(
        (e) => e != null && (e.kind.toLowerCase() == 'rejected' || e.kind.toLowerCase() == 'resolved' || e.kind.toLowerCase() == 'points_awarded'),
        orElse: () => null,
      );
      if (closeEvent != null) {
        if (note.isEmpty) {
          if (closeEvent.note.contains(' — ')) {
            note = closeEvent.note.split(' — ').last;
          } else {
            note = closeEvent.note;
          }
        }
        if (actor.isEmpty) actor = closeEvent.actor ?? '';
        timestamp ??= closeEvent.createdAt;
      }
    }

    final isAppreciation = ticket.type.toLowerCase() == 'appreciation';
    final isRejected = ticket.status.toLowerCase() == 'rejected';
    final title = isAppreciation
        ? s.resolutionLabel
        : (isRejected ? s.closedSectionLabel : s.resolvedSectionLabel);
    final formattedTime = _formatDate(timestamp);
    final subtitle = actor.isNotEmpty ? '$actor · $formattedTime' : formattedTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A)
                : (isRejected ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDF4)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? borderColor
                  : (isRejected ? const Color(0xFFE2E8F0) : const Color(0xFFDCFCE7)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.isNotEmpty ? note : '—',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Reward Card for Appreciation tickets
  Widget _buildRewardCard(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    final points = ticket.pointsAwarded ?? 50;
    final targetName = (ticket.awardedUserName != null && ticket.awardedUserName!.isNotEmpty)
        ? ticket.awardedUserName!
        : ((ticket.aboutUserName != null && ticket.aboutUserName!.isNotEmpty)
            ? ticket.aboutUserName!
            : 'Staff');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                s.rewardLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFDCFCE7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+$points points to $targetName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.onlyDirectorCanChange,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Reward Card for Appreciation tickets in Director Login
  Widget _buildDirectorRewardCard(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    final points = ticket.pointsAwarded ?? 50;
    final targetName = (ticket.awardedUserName != null && ticket.awardedUserName!.isNotEmpty)
        ? ticket.awardedUserName!
        : ((ticket.aboutUserName != null && ticket.aboutUserName!.isNotEmpty)
            ? ticket.aboutUserName!
            : 'Staff');

    LookupAssigneeModel? selectedFaculty;
    if (_selectedAwardFacultyId != null) {
      selectedFaculty = _allAssignees.cast<LookupAssigneeModel?>().firstWhere(
        (a) => a?.id == _selectedAwardFacultyId,
        orElse: () => null,
      );
    }
    final facultyDisplay = selectedFaculty != null
        ? (selectedFaculty.department?.isNotEmpty == true
            ? '${selectedFaculty.name} · ${selectedFaculty.department}'
            : selectedFaculty.name)
        : ((ticket.awardedUserName?.isNotEmpty == true
            ? ticket.awardedUserName!
            : (ticket.aboutUserName?.isNotEmpty == true ? ticket.aboutUserName! : s.selectFacultyPrompt)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: REWARD — DIRECTOR ONLY
          Text(
            s.rewardDirectorOnly,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle: +50 points to Swapnika. Changing this moves the points.
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 11.5, color: labelColor),
              children: [
                TextSpan(
                  text: '+$points points to $targetName. ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(text: s.changingThisMovesPoints),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Faculty *
          Text(
            s.facultyLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showFacultyPicker(s, isDark, textColor, labelColor, borderColor),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      facultyDisplay,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: labelColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Reward points
          Text(
            s.rewardPointsLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _awardPointsController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 12.5, color: textColor),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Reason *
          Text(
            s.reasonRequiredLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _awardReasonController,
            maxLines: 3,
            style: TextStyle(fontSize: 12.5, color: textColor),
            decoration: InputDecoration(
              hintText: s.whyIsThisBeingChangedHint,
              hintStyle: TextStyle(fontSize: 11.5, color: labelColor),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Update faculty & points Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: _isSubmittingAward ? null : () => _handleAwardPoints(s),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isSubmittingAward
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      s.updateFacultyAndPoints,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// History Timeline
  Widget _buildHistorySection(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.historyLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 10),
        if (ticket.events.isEmpty)
          Text(
            'No events recorded.',
            style: TextStyle(fontSize: 11.5, color: labelColor, fontStyle: FontStyle.italic),
          )
        else
          Column(
            children: ticket.events.map((ev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        ev.kind,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev.note,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ev.actor ?? "System"} · ${_formatDate(ev.createdAt)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: labelColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Linked Task Card in Right Column
  Widget _buildLinkedTaskCard(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor, {
    bool canShowAssignButton = false,
  }) {
    final hasLinkedTask = ticket.taskNo?.isNotEmpty == true || ticket.taskId != null;
    final taskNo = ticket.taskNo ?? (ticket.taskId != null ? 'TASK-${ticket.taskId}' : '—');
    final taskStatus = ticket.taskStatus?.replaceAll('_', ' ') ?? 'to be started';
    final taskDue = _formatSimpleDate(ticket.taskDueDate);

    TicketAssigneeModel? assignee;
    if (ticket.taskAssignees.isNotEmpty) {
      assignee = ticket.taskAssignees.first;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.linkedTask,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),

          // Task ID & Status
          Row(
            children: [
              Expanded(
                child: Text(
                  taskNo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  taskStatus,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Due Date Badge
          if (ticket.taskDueDate?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Due $taskDue',
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Assignee
          if (assignee != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: _parseColor(assignee.color),
                  child: Text(
                    assignee.initials,
                    style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  assignee.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Action Buttons: Assign to... (if applicable) and Open task
          if (canShowAssignButton)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAssignOpen = !_isAssignOpen;
                      });
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 14),
                    label: Text(
                      s.assignTo,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.button(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: hasLinkedTask ? () => _navigateToAllTasks(ticket) : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      s.openTask,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: hasLinkedTask ? () => _navigateToAllTasks(ticket) : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  s.openTask,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Owner caption
          if (ticket.ownerName?.isNotEmpty == true)
            Text(
              'Owner: ${ticket.ownerName} · ${s.campusHeadLabel}',
              style: TextStyle(
                fontSize: 10.5,
                color: labelColor,
              ),
            ),
        ],
      ),
    );
  }

  /// Assign This Ticket Card
  Widget _buildAssignTicketCard(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.assignThisTicket,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: labelColor,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isAssignOpen = false),
                child: Icon(Icons.close, size: 16, color: labelColor),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search people...
          TextField(
            controller: _assignSearchController,
            onChanged: _filterAssignees,
            style: TextStyle(fontSize: 12.5, color: textColor),
            decoration: InputDecoration(
              hintText: s.searchPeoplePlaceholder,
              hintStyle: TextStyle(fontSize: 12, color: labelColor),
              prefixIcon: Icon(Icons.search, size: 16, color: labelColor),
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Assignees list with checkboxes
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: _filteredAssignees.isEmpty
                ? Center(
                    child: Text('No assignees found', style: TextStyle(fontSize: 11, color: labelColor)),
                  )
                : ListView.builder(
                    itemCount: _filteredAssignees.length,
                    itemBuilder: (context, index) {
                      final assignee = _filteredAssignees[index];
                      final isChecked = _selectedAssigneeIds.contains(assignee.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selectedAssigneeIds.remove(assignee.id);
                            } else {
                              _selectedAssigneeIds.add(assignee.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isChecked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedAssigneeIds.add(assignee.id);
                                      } else {
                                        _selectedAssigneeIds.remove(assignee.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  assignee.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Text(
                                '${assignee.department}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),

          // What should they do? (required)
          TextField(
            controller: _assignNoteController,
            maxLines: 2,
            style: TextStyle(fontSize: 12.5, color: textColor),
            decoration: InputDecoration(
              hintText: s.whatShouldTheyDoPlaceholder,
              hintStyle: TextStyle(fontSize: 12, color: labelColor),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Assign button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingAssign ? null : _handleAssign,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.button(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmittingAssign
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(s.assignButton, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// Close The Loop Section (Resolve / Not Valid)
  Widget _buildCloseLoopCard(
    TicketItemModel ticket,
    AppStrings s,
    bool isDark,
    Color textColor,
    Color labelColor,
    Color borderColor,
  ) {
    final isResolve = _closeLoopTab == 'resolve';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.closeTheLoop,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 10),

          // Tabs: Resolve and Not valid
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _closeLoopTab = 'resolve');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isResolve ? AppColors.button(context) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    foregroundColor: isResolve ? Colors.white : (isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(s.resolveTab, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _closeLoopTab = 'reject');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isResolve ? AppColors.button(context) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    foregroundColor: !isResolve ? Colors.white : (isDark ? Colors.grey.shade400 : const Color(0xFF475569)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(s.notValidTab, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body based on tab
          if (isResolve) ...[
            TextField(
              controller: _resolutionController,
              maxLines: 3,
              style: TextStyle(fontSize: 12.5, color: textColor),
              decoration: InputDecoration(
                hintText: s.whatWasDonePlaceholder,
                hintStyle: TextStyle(fontSize: 12, color: labelColor),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF16A34A)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmittingCloseLoop ? null : _handleResolve,
                icon: const Icon(Icons.check, size: 16),
                label: Text(
                  s.markResolvedButton,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            TextField(
              controller: _rejectReasonController,
              maxLines: 3,
              style: TextStyle(fontSize: 12.5, color: textColor),
              decoration: InputDecoration(
                hintText: s.reasonWhyNotValidPlaceholder,
                hintStyle: TextStyle(fontSize: 12, color: labelColor),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDC2626)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingCloseLoop ? null : _handleReject,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  s.closeAsNotValidButton,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypePill(String type, bool isDark) {
    final isComplaint = type.toLowerCase().contains('complaint');
    final color = isComplaint ? const Color(0xFFE11D48) : const Color(0xFF2563EB);
    final bg = isComplaint
        ? (isDark ? const Color(0xFF881337).withOpacity(0.35) : const Color(0xFFFFF1F2))
        : (isDark ? const Color(0xFF1E3A8A).withOpacity(0.35) : const Color(0xFFEFF6FF));

    final label = isComplaint ? 'Complaint' : 'Feedback / Suggestion';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'new':
        color = const Color(0xFFD97706);
        bg = isDark ? const Color(0xFF78350F).withOpacity(0.4) : const Color(0xFFFEF3C7);
        break;
      case 'in_progress':
        color = const Color(0xFF2563EB);
        bg = isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFFDBEAFE);
        break;
      case 'resolved':
        color = const Color(0xFF16A34A);
        bg = isDark ? const Color(0xFF14532D).withOpacity(0.4) : const Color(0xFFDCFCE7);
        break;
      default:
        color = const Color(0xFF64748B);
        bg = isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.substring(0, 1).toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
