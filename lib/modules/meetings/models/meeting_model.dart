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
      name: json['name'] as String? ?? '',
      response: json['response'] as String?,
      required: json['required'] as bool?,
      attended: json['attended'] as bool?,
    );
  }
}

class MeetingItemModel {
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
  final String? organizer;
  final String? branchName;
  final List<InviteeItemModel> invitees;

  MeetingItemModel({
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
    this.organizer,
    this.branchName,
    required this.invitees,
  });

  factory MeetingItemModel.fromJson(Map<String, dynamic> json) {
    return MeetingItemModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      startsAt: json['starts_at'] as String? ?? json['date_text'] as String? ?? '',
      endsAt: json['ends_at'] as String? ?? json['starts_at'] as String? ?? '',
      location: json['location'] as String? ?? json['mode'] as String? ?? 'Online',
      status: json['status'] as String? ?? 'scheduled',
      agenda: json['agenda'] as String?,
      isOneOnOne: json['is_one_on_one'] as bool?,
      kind: json['kind'] as String?,
      isOrganizer: json['is_organizer'] as bool? ?? json['is_initiated_by_me'] as bool? ?? true,
      organizer: json['organizer'] as String? ?? json['organizer_name'] as String? ?? 'Vamsi',
      branchName: json['branch_name'] as String?,
      invitees: json['invitees'] != null && json['invitees'] is List
          ? (json['invitees'] as List).map((e) => InviteeItemModel.fromJson(e)).toList()
          : [],
    );
  }
}
