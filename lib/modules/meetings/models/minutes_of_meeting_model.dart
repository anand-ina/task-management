class MomActionItem {
  final String item;
  final String owner;
  final String due;

  const MomActionItem({
    required this.item,
    required this.owner,
    required this.due,
  });

  factory MomActionItem.fromJson(Map<String, dynamic> json) {
    return MomActionItem(
      item: json['item']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      due: json['due']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'owner': owner,
      'due': due,
    };
  }

  MomActionItem copyWith({
    String? item,
    String? owner,
    String? due,
  }) {
    return MomActionItem(
      item: item ?? this.item,
      owner: owner ?? this.owner,
      due: due ?? this.due,
    );
  }
}

class MomData {
  final String attendeesText;
  final String agenda;
  final String discussion;
  final String decisions;
  final String? nextMeetingDate;
  final String? venue;
  final String? recordedBy;
  final List<MomActionItem> actionItems;

  const MomData({
    required this.attendeesText,
    required this.agenda,
    required this.discussion,
    required this.decisions,
    this.nextMeetingDate,
    this.venue,
    this.recordedBy,
    required this.actionItems,
  });

  factory MomData.fromJson(Map<String, dynamic> json) {
    List<MomActionItem> items = [];
    if (json['actionItems'] is List) {
      items = (json['actionItems'] as List)
          .map((e) => MomActionItem.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    } else if (json['action_items'] is List) {
      items = (json['action_items'] as List)
          .map((e) => MomActionItem.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    return MomData(
      attendeesText: json['attendeesText']?.toString() ?? json['attendees_text']?.toString() ?? '',
      agenda: json['agenda']?.toString() ?? '',
      discussion: json['discussion']?.toString() ?? '',
      decisions: json['decisions']?.toString() ?? '',
      nextMeetingDate: json['nextMeetingDate']?.toString() ?? json['next_meeting_date']?.toString(),
      venue: json['venue']?.toString() ?? json['location']?.toString(),
      recordedBy: json['recordedBy']?.toString() ?? json['recorded_by']?.toString(),
      actionItems: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attendeesText': attendeesText,
      'agenda': agenda,
      'discussion': discussion,
      'decisions': decisions,
      'nextMeetingDate': nextMeetingDate ?? '',
      'venue': venue ?? '',
      'actionItems': actionItems.map((e) => e.toJson()).toList(),
    };
  }
}

class MomMeetingDetails {
  final int id;
  final String title;
  final String? startsAt;
  final String? endsAt;
  final String? location;
  final String? agenda;
  final String? status;
  final String? organizer;

  const MomMeetingDetails({
    required this.id,
    required this.title,
    this.startsAt,
    this.endsAt,
    this.location,
    this.agenda,
    this.status,
    this.organizer,
  });

  factory MomMeetingDetails.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return MomMeetingDetails(
      id: parseId(json['id']),
      title: json['title']?.toString() ?? '',
      startsAt: json['starts_at']?.toString() ?? json['startsAt']?.toString(),
      endsAt: json['ends_at']?.toString() ?? json['endsAt']?.toString(),
      location: json['location']?.toString(),
      agenda: json['agenda']?.toString(),
      status: json['status']?.toString(),
      organizer: json['organizer']?.toString() ?? json['organizer_name']?.toString(),
    );
  }
}

class MomInvitee {
  final String name;
  final bool required;
  final bool attended;
  final String? response;

  const MomInvitee({
    required this.name,
    this.required = false,
    this.attended = false,
    this.response,
  });

  factory MomInvitee.fromJson(Map<String, dynamic> json) {
    return MomInvitee(
      name: json['name']?.toString() ?? '',
      required: json['required'] == true,
      attended: json['attended'] == true,
      response: json['response']?.toString(),
    );
  }
}

class MinutesOfMeetingModel {
  final MomMeetingDetails meeting;
  final List<MomInvitee> invitees;
  final MomData? mom;

  const MinutesOfMeetingModel({
    required this.meeting,
    required this.invitees,
    this.mom,
  });

  factory MinutesOfMeetingModel.fromJson(Map<String, dynamic> json) {
    final meetingMap = json['meeting'] is Map<String, dynamic>
        ? json['meeting'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawInvitees = json['invitees'];
    List<MomInvitee> inviteesList = [];
    if (rawInvitees is List) {
      inviteesList = rawInvitees
          .map((e) => MomInvitee.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    MomData? momData;
    if (json['mom'] is Map<String, dynamic>) {
      momData = MomData.fromJson(json['mom'] as Map<String, dynamic>);
    }

    return MinutesOfMeetingModel(
      meeting: MomMeetingDetails.fromJson(meetingMap),
      invitees: inviteesList,
      mom: momData,
    );
  }
}
