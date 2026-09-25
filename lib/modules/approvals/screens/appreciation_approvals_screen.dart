import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/utils/network_connectivity_service.dart';
import '../../../shared_widgets/announcement_banner_wrapper.dart';
import '../../../shared_widgets/app_bar/custom_app_bar.dart';
import '../../../shared_widgets/dialogs/exit_confirmation_dialog.dart';
import '../../../shared_widgets/dialogs/no_internet_dialog.dart';
import '../../../shared_widgets/drawer/custom_left_drawer.dart';
import '../../../shared_widgets/floating_action_button/todo_floating_action_button.dart';
import '../../complaints/dialogs/ticket_details_dialog.dart';
import '../../complaints/models/lookup_models.dart';
import '../../complaints/models/ticket_model.dart';
import '../../complaints/repository/complaints_repository.dart';

class AppreciationApprovalsScreen extends StatefulWidget {
  const AppreciationApprovalsScreen({super.key});

  @override
  State<AppreciationApprovalsScreen> createState() => _AppreciationApprovalsScreenState();
}

class _AppreciationApprovalsScreenState extends State<AppreciationApprovalsScreen> {
  final ComplaintsRepository _repository = ComplaintsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<TicketItemModel> _tickets = [];
  List<LookupAssigneeModel> _assignees = [];

  // Card form states mapped by ticketId
  final Map<int, int?> _selectedFacultyIds = {};
  final Map<int, TextEditingController> _pointsControllers = {};
  final Map<int, TextEditingController> _reasonControllers = {};
  final Map<int, bool> _submittingMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final controller in _pointsControllers.values) {
      controller.dispose();
    }
    for (final controller in _reasonControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isOnline = await NetworkConnectivityService().checkConnection();
    if (!isOnline && mounted) {
      setState(() => _isLoading = false);
      NoInternetDialog.showForceLogout(context);
      return;
    }

    try {
      final ticketsFuture = _repository.getTickets(
        status: 'pending_reward',
        type: 'appreciation',
      );
      final assigneesFuture = _repository.getAssignees();

      final results = await Future.wait([ticketsFuture, assigneesFuture]);
      final ticketResponse = results[0] as TicketListResponse;
      final assigneesList = results[1] as List<LookupAssigneeModel>;

      if (mounted) {
        setState(() {
          _tickets = ticketResponse.items;
          _assignees = assigneesList;
          _isLoading = false;

          // Initialize form controllers for any new tickets
          for (final ticket in _tickets) {
            _pointsControllers.putIfAbsent(
              ticket.id,
              () => TextEditingController(text: '50'),
            );
            _reasonControllers.putIfAbsent(
              ticket.id,
              () => TextEditingController(),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDateTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openStaffPicker(int ticketId) async {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final selectedStaff = await showDialog<LookupAssigneeModel>(
      context: context,
      builder: (pickerContext) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final filtered = _assignees.where((a) {
              final query = filter.toLowerCase().trim();
              if (query.isEmpty) return true;
              return a.name.toLowerCase().contains(query) ||
                  (a.department?.toLowerCase().contains(query) ?? false);
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: dialogBg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450, maxHeight: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            s.facultyRequiredLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => Navigator.of(pickerContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: s.searchStaffHint,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        onChanged: (val) {
                          setPickerState(() => filter = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: borderColor),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                s.noStaffFound,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final staff = filtered[index];
                                final isSelected = _selectedFacultyIds[ticketId] == staff.id;

                                Color avatarBg;
                                try {
                                  final hex = staff.avatarColor.replaceFirst('#', '');
                                  avatarBg = Color(int.parse('FF$hex', radix: 16));
                                } catch (_) {
                                  avatarBg = const Color(0xFF132A50);
                                }

                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: avatarBg,
                                    child: Text(
                                      staff.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    staff.name,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                  subtitle: staff.department != null && staff.department!.isNotEmpty
                                      ? Text(
                                          staff.department!,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                        )
                                      : null,
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: Color(0xFF16A34A), size: 18)
                                      : null,
                                  onTap: () => Navigator.of(pickerContext).pop(staff),
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

    if (selectedStaff != null) {
      setState(() {
        _selectedFacultyIds[ticketId] = selectedStaff.id;
      });
    }
  }

  Future<void> _awardPoints(TicketItemModel ticket) async {
    final s = AppStrings.of(context);
    final facultyId = _selectedFacultyIds[ticket.id];
    if (facultyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.selectStaffMemberHint),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reason = _reasonControllers[ticket.id]?.text.trim() ?? '';
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.whyThisFacultyHint),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pointsStr = _pointsControllers[ticket.id]?.text.trim() ?? '50';
    final points = int.tryParse(pointsStr) ?? 50;

    final isOnline = await NetworkConnectivityService().checkConnection();
    if (!isOnline && mounted) {
      NoInternetDialog.show(context);
      return;
    }

    setState(() {
      _submittingMap[ticket.id] = true;
    });

    try {
      await _repository.awardTicket(
        ticketId: ticket.id,
        userId: facultyId,
        points: points,
        reason: reason,
      );

      if (mounted) {
        setState(() {
          _submittingMap[ticket.id] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.pointsAwardedSuccess),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );

        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submittingMap[ticket.id] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to award points: $e'),
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

    final headerTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          await ExitConfirmationDialog.show(context);
        }
      },
      child: Scaffold(
        floatingActionButton: const TodoFloatingActionButton(),
        drawer: const CustomLeftDrawer(currentRoute: '/approvals/appreciations'),
        appBar: const CustomAppBar(),
        body: AnnouncementBannerWrapper(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title & Waiting Count Pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        s.appreciationApprovals,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: headerTextColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '${_tickets.length} ${s.waitingBadge}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    s.appreciationApprovalsSubtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Loading / Error / Empty / List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Text(
                              'Failed to load appreciations: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_tickets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Text(
                          s.noAppreciationsWaiting,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final ticket = _tickets[index];
                        return _buildAppreciationCard(ticket);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppreciationCard(TicketItemModel ticket) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF64748B);
    final descBoxBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final isSubmitting = _submittingMap[ticket.id] ?? false;
    final selectedFacultyId = _selectedFacultyIds[ticket.id];
    final selectedFaculty = _assignees.where((a) => a.id == selectedFacultyId).firstOrNull;

    final pointsController = _pointsControllers[ticket.id] ?? TextEditingController(text: '50');
    final reasonController = _reasonControllers[ticket.id] ?? TextEditingController();

    // From string composition
    final sourcePart = _capitalize(ticket.source);
    final channelPart = ticket.channelLabel ?? _capitalize(ticket.channel);
    final channelDetailPart = ticket.channelDetail != null && ticket.channelDetail!.isNotEmpty
        ? ' — ${ticket.channelDetail}'
        : '';
    final fromValue = '$sourcePart · $channelPart$channelDetailPart';

    // Student & About values
    final studentValue = ticket.studentName != null && ticket.studentName!.isNotEmpty
        ? ticket.studentName!
        : s.anonymousLabel;
    final aboutValue = ticket.aboutUserName != null && ticket.aboutUserName!.isNotEmpty
        ? ticket.aboutUserName!
        : (ticket.aboutText != null && ticket.aboutText!.isNotEmpty
            ? ticket.aboutText!
            : s.notNamedYetLabel);

    // Raised By composition
    final raisedByValue = ticket.raisedByName != null && ticket.raisedByName!.isNotEmpty
        ? '${ticket.raisedByName}${ticket.branchName != null ? ' · ${ticket.branchName}' : ''}'
        : (ticket.branchName ?? '');

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4.5,
            child: Container(
              color: const Color(0xFF10B981),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          final leftSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ticket No, Badges, Open full ticket button
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    ticket.ticketNo,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Appreciation',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.awaitingYourApproval,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      TicketDetailsDialog.show(
                        context,
                        ticketId: ticket.id,
                        onUpdated: _loadData,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      s.openFullTicket,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: descBoxBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.description.isNotEmpty ? ticket.description : '—',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Metadata Table
              _buildMetaRow(s.fromLabel, fromValue, textColor, mutedText),
              const SizedBox(height: 6),
              _buildMetaRow(s.studentLabel, studentValue, textColor, mutedText),
              const SizedBox(height: 6),
              _buildMetaRow(s.aboutLabel, aboutValue, textColor, mutedText),
              const SizedBox(height: 6),
              _buildMetaRow(s.categoryLabel, ticket.category, textColor, mutedText),
              const SizedBox(height: 6),
              _buildMetaRow(
                s.receivedLabel,
                _formatDateTime(ticket.receivedAt),
                textColor,
                mutedText,
              ),
              const SizedBox(height: 6),
              _buildMetaRow(s.raisedByLabel, raisedByValue, textColor, mutedText),
              const SizedBox(height: 14),

              // Evidence Attached Notice
              Text(
                '${s.evidenceAttachedNotice} ${ticket.raisedByName ?? ""}.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: mutedText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );

          final rightSection = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.approveAppreciationHeader,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.noFacultyNamedSubtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: mutedText,
                  ),
                ),
                const SizedBox(height: 14),

                // Faculty *
                Text(
                  s.facultyRequiredLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _openStaffPicker(ticket.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (selectedFaculty != null) ...[
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF132A50),
                            child: Text(
                              selectedFaculty.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFaculty.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          Expanded(
                            child: Text(
                              s.selectStaffMemberHint,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Reward Points
                Text(
                  s.rewardPointsLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    fillColor: cardBg,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Reason *
                Text(
                  s.reasonRequiredLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: InputDecoration(
                    fillColor: cardBg,
                    filled: true,
                    hintText: s.whyThisFacultyHint,
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Approve & Award 50 points button
                ElevatedButton(
                  onPressed: isSubmitting ? null : () => _awardPoints(ticket),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '🏅 ${s.approveAndAwardPoints} ${pointsController.text.trim()} ${s.rewardPointsLabel.toLowerCase()}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: leftSection),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: rightSection),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftSection,
                const SizedBox(height: 20),
                rightSection,
              ],
            );
          }
        },
      ),
    ),
  ],
),
);
  }

  Widget _buildMetaRow(String label, String value, Color textColor, Color mutedText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
