import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_strings.dart';
import '../models/meeting_model.dart';
import '../models/minutes_of_meeting_model.dart';
import '../repository/meetings_repository.dart';

class MinutesOfMeetingDialog extends StatefulWidget {
  final MeetingItemModel meeting;

  const MinutesOfMeetingDialog({
    super.key,
    required this.meeting,
  });

  static Future<bool?> show(BuildContext context, MeetingItemModel meeting) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MinutesOfMeetingDialog(meeting: meeting),
    );
  }

  @override
  State<MinutesOfMeetingDialog> createState() => _MinutesOfMeetingDialogState();
}

class _MinutesOfMeetingDialogState extends State<MinutesOfMeetingDialog> {
  final MeetingsRepository _repository = MeetingsRepository();

  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _attendeesController = TextEditingController();
  final TextEditingController _agendaController = TextEditingController();
  final TextEditingController _discussionController = TextEditingController();
  final TextEditingController _decisionsController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _nextMeetingDateController = TextEditingController();

  List<MomActionItem> _actionItems = [];
  MomData? _existingMom;
  List<MomInvitee> _invitees = [];

  @override
  void initState() {
    super.initState();
    _loadMomData();
  }

  @override
  void dispose() {
    _attendeesController.dispose();
    _agendaController.dispose();
    _discussionController.dispose();
    _decisionsController.dispose();
    _venueController.dispose();
    _nextMeetingDateController.dispose();
    super.dispose();
  }

  Future<void> _loadMomData() async {
    final meetingId = widget.meeting.rawId ?? widget.meeting.id;
    try {
      final momModel = await _repository.getMeetingMom(meetingId);
      if (momModel != null) {
        _existingMom = momModel.mom;
        _invitees = momModel.invitees;

        if (_existingMom != null) {
          _attendeesController.text = _existingMom!.attendeesText;
          _agendaController.text = _existingMom!.agenda.isNotEmpty
              ? _existingMom!.agenda
              : (widget.meeting.agenda ?? '');
          _discussionController.text = _existingMom!.discussion;
          _decisionsController.text = _existingMom!.decisions;
          _venueController.text = _existingMom!.venue?.isNotEmpty == true
              ? _existingMom!.venue!
              : (widget.meeting.location ?? 'In person');
          _nextMeetingDateController.text = _existingMom!.nextMeetingDate ?? '';
          _actionItems = List.from(_existingMom!.actionItems);
        } else {
          // Initialize defaults
          _agendaController.text = widget.meeting.agenda ?? '';
          _venueController.text = widget.meeting.location ?? 'In person';

          // Suggest attendees from invitees who attended or all invitees
          final attendedNames = _invitees
              .where((i) => i.attended)
              .map((i) => i.name)
              .toList();
          if (attendedNames.isNotEmpty) {
            _attendeesController.text = attendedNames.join(', ');
          } else if (_invitees.isNotEmpty) {
            _attendeesController.text = _invitees.map((i) => i.name).join(', ');
          }
        }
      }
    } catch (e) {
      debugPrint('[MinutesOfMeetingDialog] Error loading MOM: $e');
      // If error or new, initialize from widget.meeting
      _agendaController.text = widget.meeting.agenda ?? '';
      _venueController.text = widget.meeting.location ?? 'In person';
      if (widget.meeting.invitees.isNotEmpty) {
        _attendeesController.text = widget.meeting.invitees.map((i) => i.name).join(', ');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickNextMeetingDate() async {
    DateTime initialDate = DateTime.now().add(const Duration(days: 7));
    if (_nextMeetingDateController.text.isNotEmpty) {
      final parsed = DateTime.tryParse(_nextMeetingDateController.text);
      if (parsed != null) initialDate = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() {
        _nextMeetingDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addActionItem() {
    setState(() {
      _actionItems.add(const MomActionItem(item: '', owner: '', due: ''));
    });
  }

  void _removeActionItem(int index) {
    if (index >= 0 && index < _actionItems.length) {
      setState(() {
        _actionItems.removeAt(index);
      });
    }
  }

  Future<void> _saveMom() async {
    final s = AppStrings.of(context);
    final meetingId = widget.meeting.rawId ?? widget.meeting.id;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'attendeesText': _attendeesController.text.trim(),
        'agenda': _agendaController.text.trim(),
        'discussion': _discussionController.text.trim(),
        'decisions': _decisionsController.text.trim(),
        'nextMeetingDate': _nextMeetingDateController.text.trim(),
        'venue': _venueController.text.trim(),
        'actionItems': _actionItems
            .where((a) => a.item.trim().isNotEmpty)
            .map((a) => a.toJson())
            .toList(),
      };

      await _repository.saveMeetingMom(meetingId, payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.momSavedSuccess),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save MOM: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  String _formatSubtitleDate() {
    try {
      final dt = DateTime.parse(widget.meeting.startsAt).toLocal();
      return DateFormat('EEE d MMM, HH:mm').format(dt);
    } catch (_) {
      return widget.meeting.startsAt;
    }
  }

  InputDecoration _inputDecoration(BuildContext context, bool isDark, {String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subtitle = '${widget.meeting.title} · ${_formatSubtitleDate()}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 580,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title + Close Icon Button
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.minutesOfMeetingTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Attendees (who was present)
                      Text(
                        s.attendeesPresentLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _attendeesController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDecoration(context, isDark, hintText: 'Names of attendees...'),
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Agenda
                      Text(
                        s.agendaMomLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _agendaController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDecoration(context, isDark, hintText: 'Meeting agenda...'),
                      ),
                      const SizedBox(height: 14),

                      // Field 3: Discussion points
                      Text(
                        s.discussionPointsLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _discussionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDecoration(context, isDark, hintText: '1.\n2.\n3.'),
                      ),
                      const SizedBox(height: 14),

                      // Field 4: Decisions taken
                      Text(
                        s.decisionsTakenLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _decisionsController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 12),
                        decoration: _inputDecoration(context, isDark, hintText: 'Decisions agreed upon...'),
                      ),
                      const SizedBox(height: 14),

                      // Field 5: Venue & Next Meeting Date (Two Columns)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.venueLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _venueController,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _inputDecoration(context, isDark, hintText: 'e.g., In person'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.nextMeetingDateLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _pickNextMeetingDate,
                                  child: IgnorePointer(
                                    child: TextField(
                                      controller: _nextMeetingDateController,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: _inputDecoration(
                                        context,
                                        isDark,
                                        hintText: 'YYYY-MM-DD',
                                      ).copyWith(
                                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Field 6: Action Items Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.actionItemsLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addActionItem,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              s.addActionItemButton,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      if (_actionItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No action items yet. Click "+ Add Action Item" to add.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _actionItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _actionItems[index];
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Index #
                                  Container(
                                    width: 22,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Action
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: item.item,
                                      style: const TextStyle(fontSize: 11),
                                      decoration: InputDecoration(
                                        hintText: s.actionItemCol,
                                        hintStyle: const TextStyle(fontSize: 10.5),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        _actionItems[index] = _actionItems[index].copyWith(item: val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Owner
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: item.owner,
                                      style: const TextStyle(fontSize: 11),
                                      decoration: InputDecoration(
                                        hintText: s.ownerCol,
                                        hintStyle: const TextStyle(fontSize: 10.5),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        _actionItems[index] = _actionItems[index].copyWith(owner: val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Due
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      initialValue: item.due,
                                      style: const TextStyle(fontSize: 11),
                                      decoration: InputDecoration(
                                        hintText: s.dueCol,
                                        hintStyle: const TextStyle(fontSize: 10.5),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        _actionItems[index] = _actionItems[index].copyWith(due: val);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Delete
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                    onPressed: () => _removeActionItem(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),

            // Bottom Buttons: Cancel & Save MOM
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    s.cancelButton,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: _isSaving ? null : _saveMom,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          s.saveMomButton,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
