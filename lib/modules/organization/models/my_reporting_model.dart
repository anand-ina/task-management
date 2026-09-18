class MyReportingPersonModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String designation;
  final int level;
  final String roleLabel;
  final String department;
  final String branchCode;
  final String branchName;
  final String? responsibility;

  const MyReportingPersonModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.designation,
    required this.level,
    required this.roleLabel,
    required this.department,
    required this.branchCode,
    required this.branchName,
    this.responsibility,
  });

  factory MyReportingPersonModel.fromJson(Map<String, dynamic> json) {
    return MyReportingPersonModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#132a50',
      designation: json['designation'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      roleLabel: json['role_label'] as String? ?? '',
      department: json['department'] as String? ?? '',
      branchCode: json['branch_code'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      responsibility: json['responsibility'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'avatar_color': avatarColor,
        'designation': designation,
        'level': level,
        'role_label': roleLabel,
        'department': department,
        'branch_code': branchCode,
        'branch_name': branchName,
        'responsibility': responsibility,
      };
}

class MyReportingResponseModel {
  final MyReportingPersonModel? me;
  final List<MyReportingPersonModel> managers;
  final List<MyReportingPersonModel> dotted;
  final List<MyReportingPersonModel> reports;
  final List<MyReportingPersonModel> dottedReports;
  final List<MyReportingPersonModel> peers;

  const MyReportingResponseModel({
    this.me,
    this.managers = const [],
    this.dotted = const [],
    this.reports = const [],
    this.dottedReports = const [],
    this.peers = const [],
  });

  factory MyReportingResponseModel.fromJson(Map<String, dynamic> json) {
    return MyReportingResponseModel(
      me: json['me'] != null
          ? MyReportingPersonModel.fromJson(json['me'] as Map<String, dynamic>)
          : null,
      managers: (json['managers'] as List<dynamic>?)
              ?.map((m) => MyReportingPersonModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      dotted: (json['dotted'] as List<dynamic>?)
              ?.map((m) => MyReportingPersonModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      reports: (json['reports'] as List<dynamic>?)
              ?.map((m) => MyReportingPersonModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      dottedReports: (json['dottedReports'] as List<dynamic>?)
              ?.map((m) => MyReportingPersonModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      peers: (json['peers'] as List<dynamic>?)
              ?.map((m) => MyReportingPersonModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'me': me?.toJson(),
        'managers': managers.map((m) => m.toJson()).toList(),
        'dotted': dotted.map((m) => m.toJson()).toList(),
        'reports': reports.map((m) => m.toJson()).toList(),
        'dottedReports': dottedReports.map((m) => m.toJson()).toList(),
        'peers': peers.map((m) => m.toJson()).toList(),
      };
}
