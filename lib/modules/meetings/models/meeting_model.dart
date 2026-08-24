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
  final String? completionRequestedBy;
  final String? organizer;
  final String? branchName;
  final String? myResponse;
  final bool? myRequired;
  final bool? myAttended;
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
    this.completionRequestedBy,
    this.organizer,
    this.branchName,
    this.myResponse,
    this.myRequired,
    this.myAttended,
    required this.invitees,
  });

  factory MeetingItemModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
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
      completionRequestedBy: json['completion_requested_by']?.toString(),
      organizer: json['organizer']?.toString() ?? json['organizer_name']?.toString() ?? 'Vamsi',
      branchName: json['branch_name']?.toString(),
      myResponse: json['my_response']?.toString(),
      myRequired: json['my_required'] is bool ? json['my_required'] as bool : null,
      myAttended: json['my_attended'] is bool ? json['my_attended'] as bool : null,
      invitees: json['invitees'] != null && json['invitees'] is List
          ? (json['invitees'] as List)
              .map((e) => InviteeItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList()
          : [],
    );
  }
}
