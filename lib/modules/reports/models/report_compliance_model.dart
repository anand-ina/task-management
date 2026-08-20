class MissedUserModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String department;

  MissedUserModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.department,
  });

  factory MissedUserModel.fromJson(Map<String, dynamic> json) {
    return MissedUserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#d98a04',
      department: json['department'] as String? ?? '',
    );
  }
}

class ComplianceDayModel {
  final String day;
  final int eligible;
  final int filed;
  final int missed;
  final double rate;
  final List<MissedUserModel> missedUsers;

  ComplianceDayModel({
    required this.day,
    required this.eligible,
    required this.filed,
    required this.missed,
    required this.rate,
    required this.missedUsers,
  });

  factory ComplianceDayModel.fromJson(Map<String, dynamic> json) {
    return ComplianceDayModel(
      day: json['day'] as String? ?? '',
      eligible: json['eligible'] as int? ?? 0,
      filed: json['filed'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      missedUsers: json['missedUsers'] != null && json['missedUsers'] is List
          ? (json['missedUsers'] as List).map((e) => MissedUserModel.fromJson(e)).toList()
          : [],
    );
  }
}

class ReportComplianceModel {
  final List<ComplianceDayModel> days;
  final List<MissedUserModel> people;

  ReportComplianceModel({
    required this.days,
    required this.people,
  });

  factory ReportComplianceModel.fromJson(Map<String, dynamic> json) {
    return ReportComplianceModel(
      days: json['days'] != null && json['days'] is List
          ? (json['days'] as List).map((e) => ComplianceDayModel.fromJson(e)).toList()
          : [],
      people: json['people'] != null && json['people'] is List
          ? (json['people'] as List).map((e) => MissedUserModel.fromJson(e)).toList()
          : [],
    );
  }
}
