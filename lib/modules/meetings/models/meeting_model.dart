class InviteeItemModel {
  final String name;
  final String? response;
  final bool? required;
  final bool? attended;

  InviteeItemModel({
    required this.name,
    this.response,
    this.required,
    this.attended,
  });

  factory InviteeItemModel.fromJson(Map<String, dynamic> json) {
    return InviteeItemModel(
      name: json['name']?.toString() ?? '',
      response: json['response']?.toString(),
      required: json['required'] is bool ? json['required'] as bool : null,
      attended: json['attended'] is bool ? json['attended'] as bool : null,
    );
  }
}

class MeetingItemModel {
  final dynamic rawId;
  final int id;
  final String title;
  final String startsAt;
  final String endsAt;
  final String? location;
  final String status;
  final String? agenda;
  final bool? isOneOnOne;
  final String? kind;
  final bool isOrganizer;
  final String? completionStatus;
  final String? completionNote;
  final String? completionDecisionNote;
  final String? completionRequestedBy;
  final String? completionDecidedBy;
  final String? organizer;
  final int? organizerId;
  final String? branchName;
  final String? myResponse;
  final bool? myRequired;
  final bool? myAttended;
  final int? rescheduleId;
  final String? rescheduleStart;
  final String? rescheduleEnd;
  final String? rescheduleNote;
  final String? rescheduleBy;
  final bool? rescheduleIsMine;
  final bool? syncToGoogle;
  final bool? createGoogleMeet;
  final String? googleEventId;
  final String? googleMeetUrl;
  final String? googleSyncStatus;
  final String? googleSyncError;
  final List<InviteeItemModel> invitees;

  MeetingItemModel({
    required this.rawId,
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.location,
    required this.status,
    this.agenda,
    this.isOneOnOne,
    this.kind,
    required this.isOrganizer,
    this.completionStatus,
    this.completionNote,
    this.completionDecisionNote,
    this.completionRequestedBy,
    this.completionDecidedBy,
    this.organizer,
    this.organizerId,
    this.branchName,
    this.myResponse,
    this.myRequired,
    this.myAttended,
    this.rescheduleId,
    this.rescheduleStart,
    this.rescheduleEnd,
    this.rescheduleNote,
    this.rescheduleBy,
    this.rescheduleIsMine,
    this.syncToGoogle,
    this.createGoogleMeet,
    this.googleEventId,
    this.googleMeetUrl,
    this.googleSyncStatus,
    this.googleSyncError,
    required this.invitees,
  });

  bool get isGoogleMeet =>
      createGoogleMeet == true ||
      (googleMeetUrl != null && googleMeetUrl!.trim().isNotEmpty) ||
      (location != null && location!.toLowerCase().contains('google meet'));

  bool get hasActiveGoogleMeet =>
      googleSyncStatus == 'synced' ||
      (googleMeetUrl != null && googleMeetUrl!.trim().isNotEmpty) ||
      (googleEventId != null && googleEventId!.trim().isNotEmpty);

  bool get isCancelled =>
      status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'canceled';

  bool get isCompleted =>
      status.toLowerCase() == 'completed' ||
      completionStatus?.toLowerCase() == 'approved' ||
      completionStatus?.toLowerCase() == 'completed';

  bool get isPendingCompletion => completionStatus?.toLowerCase() == 'pending';

  bool get hasReschedule =>
      rescheduleId != null || (rescheduleStart != null && rescheduleStart!.trim().isNotEmpty);

  factory MeetingItemModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    int? parseNullableId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return MeetingItemModel(
      rawId: json['id'],
      id: parseId(json['id']),
      title: json['title']?.toString() ?? '',
      startsAt: json['starts_at']?.toString() ?? json['date_text']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? json['starts_at']?.toString() ?? '',
      location: json['location']?.toString() ?? json['mode']?.toString() ?? 'In person',
      status: json['status']?.toString() ?? 'scheduled',
      agenda: json['agenda']?.toString(),
      isOneOnOne: json['is_one_on_one'] is bool ? json['is_one_on_one'] as bool : null,
      kind: json['kind']?.toString(),
      isOrganizer: json['is_organizer'] == true || json['is_initiated_by_me'] == true,
      completionStatus: json['completion_status']?.toString(),
      completionNote: json['completion_note']?.toString(),
      completionDecisionNote: json['completion_decision_note']?.toString(),
      completionRequestedBy: json['completion_requested_by']?.toString(),
      completionDecidedBy: json['completion_decided_by']?.toString(),
      organizer: json['organizer']?.toString() ?? json['organizer_name']?.toString() ?? '',
      organizerId: parseNullableId(json['organizer_id']),
      branchName: json['branch_name']?.toString(),
      myResponse: json['my_response']?.toString(),
      myRequired: json['my_required'] is bool ? json['my_required'] as bool : null,
      myAttended: json['my_attended'] is bool ? json['my_attended'] as bool : null,
      rescheduleId: parseNullableId(json['reschedule_id']),
      rescheduleStart: json['reschedule_start']?.toString(),
      rescheduleEnd: json['reschedule_end']?.toString(),
      rescheduleNote: json['reschedule_note']?.toString(),
      rescheduleBy: json['reschedule_by']?.toString(),
      rescheduleIsMine: json['reschedule_is_mine'] is bool ? json['reschedule_is_mine'] as bool : null,
      syncToGoogle: json['sync_to_google'] is bool ? json['sync_to_google'] as bool : null,
      createGoogleMeet: json['create_google_meet'] is bool ? json['create_google_meet'] as bool : null,
      googleEventId: json['google_event_id']?.toString(),
      googleMeetUrl: json['google_meet_url']?.toString(),
      googleSyncStatus: json['google_sync_status']?.toString(),
      googleSyncError: json['google_sync_error']?.toString(),
      invitees: json['invitees'] != null && json['invitees'] is List
          ? (json['invitees'] as List)
              .map((e) => InviteeItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList()
          : [],
    );
  }
}
