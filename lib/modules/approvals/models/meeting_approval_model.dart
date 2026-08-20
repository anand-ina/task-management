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
      name: json['name'] as String? ?? '',
      response: json['response'] as String?,
      required: json['required'] as bool?,
      attended: json['attended'] as bool?,
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
    return MeetingApprovalModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      startsAt: json['starts_at'] as String?,
      endsAt: json['ends_at'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      agenda: json['agenda'] as String?,
      isOneOnOne: json['is_one_on_one'] as bool?,
      kind: json['kind'] as String?,
      isOrganizer: json['is_organizer'] as bool?,
      completionStatus: json['completion_status'] as String?,
      completionNote: json['completion_note'] as String?,
      completionDecisionNote: json['completion_decision_note'] as String?,
      completionRequestedBy: json['completion_requested_by'] as String?,
      completionDecidedBy: json['completion_decided_by'] as String?,
      organizer: json['organizer'] as String?,
      organizerId: json['organizer_id'] as int?,
      branchName: json['branch_name'] as String?,
      myResponse: json['my_response'] as String?,
      myAttended: json['my_attended'] as bool?,
      myRequired: json['my_required'] as bool?,
      invitees: json['invitees'] != null && json['invitees'] is List
          ? (json['invitees'] as List).map((e) => InviteeModel.fromJson(e)).toList()
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
