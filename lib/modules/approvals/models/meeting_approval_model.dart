class InviteeModel {
  final String name;
  final String? response;
  final bool? required;
  final bool? attended;

  InviteeModel({
    required this.name,
    this.response,
    this.required,
    this.attended,
  });

  factory InviteeModel.fromJson(Map<String, dynamic> json) {
    return InviteeModel(
      name: json['name']?.toString() ?? '',
      response: json['response']?.toString(),
      required: json['required'] is bool ? json['required'] as bool : null,
      attended: json['attended'] is bool ? json['attended'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'response': response,
      'required': required,
      'attended': attended,
    };
  }
}

class MeetingApprovalModel {
  final int id;
  final String title;
  final String? startsAt;
  final String? endsAt;
  final String? location;
  final String status;
  final String? agenda;
  final bool? isOneOnOne;
  final String? kind;
  final bool? isOrganizer;
  final String? completionStatus;
  final String? completionNote;
  final String? completionDecisionNote;
  final String? completionRequestedBy;
  final String? completionDecidedBy;
  final String? organizer;
  final int? organizerId;
  final String? branchName;
  final String? myResponse;
  final bool? myAttended;
  final bool? myRequired;
  final List<InviteeModel> invitees;

  MeetingApprovalModel({
    required this.id,
    required this.title,
    this.startsAt,
    this.endsAt,
    this.location,
    required this.status,
    this.agenda,
    this.isOneOnOne,
    this.kind,
    this.isOrganizer,
    this.completionStatus,
    this.completionNote,
    this.completionDecisionNote,
    this.completionRequestedBy,
    this.completionDecidedBy,
    this.organizer,
    this.organizerId,
    this.branchName,
    this.myResponse,
    this.myAttended,
    this.myRequired,
    required this.invitees,
  });

  factory MeetingApprovalModel.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic val) {
      if (val == null) return null;
      if (val is Map) return val['name']?.toString() ?? val['title']?.toString();
      return val.toString();
    }

    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    bool? parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val.toLowerCase() == 'true' || val == '1';
      return null;
    }

    return MeetingApprovalModel(
      id: parseId(json['id']),
      title: parseString(json['title']) ?? parseString(json['meeting_title']) ?? parseString(json['name']) ?? 'Untitled Meeting',
      startsAt: parseString(json['starts_at']) ?? parseString(json['start_time']) ?? parseString(json['date']),
      endsAt: parseString(json['ends_at']) ?? parseString(json['end_time']),
      location: parseString(json['location']) ?? parseString(json['venue']),
      status: parseString(json['status']) ?? parseString(json['meeting_status']) ?? 'scheduled',
      agenda: parseString(json['agenda']) ?? parseString(json['description']) ?? parseString(json['note']),
      isOneOnOne: parseBool(json['is_one_on_one']),
      kind: parseString(json['kind']),
      isOrganizer: parseBool(json['is_organizer']),
      completionStatus: parseString(json['completion_status']),
      completionNote: parseString(json['completion_note']),
      completionDecisionNote: parseString(json['completion_decision_note']),
      completionRequestedBy: parseString(json['completion_requested_by']),
      completionDecidedBy: parseString(json['completion_decided_by']),
      organizer: parseString(json['organizer']) ?? parseString(json['organizer_name']),
      organizerId: json['organizer_id'] != null ? parseId(json['organizer_id']) : null,
      branchName: parseString(json['branch_name']) ?? parseString(json['branch']),
      myResponse: parseString(json['my_response']),
      myAttended: parseBool(json['my_attended']),
      myRequired: parseBool(json['my_required']),
      invitees: json['invitees'] != null && json['invitees'] is List
          ? (json['invitees'] as List)
              .map((e) => InviteeModel.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'location': location,
      'status': status,
      'agenda': agenda,
      'is_one_on_one': isOneOnOne,
      'kind': kind,
      'is_organizer': isOrganizer,
      'completion_status': completionStatus,
      'completion_note': completionNote,
      'completion_decision_note': completionDecisionNote,
      'completion_requested_by': completionRequestedBy,
      'completion_decided_by': completionDecidedBy,
      'organizer': organizer,
      'organizer_id': organizerId,
      'branch_name': branchName,
      'my_response': myResponse,
      'my_attended': myAttended,
      'my_required': myRequired,
      'invitees': invitees.map((e) => e.toJson()).toList(),
    };
  }
}
