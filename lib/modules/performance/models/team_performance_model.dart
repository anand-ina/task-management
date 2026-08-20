class TeamMemberModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String? designation;
  final String? lastLogin;
  final String department;
  final String? branchCode;
  final String? branchName;
  final String? role;
  final int assigned;
  final int done;
  final int onTimeDone;
  final int inProgress;
  final int toBeStarted;
  final int dropped;
  final int overdue;
  final int dueToday;
  final int emergencyHighOpen;
  final int onTime;
  final double avgDays;
  final int points;

  TeamMemberModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.designation,
    this.lastLogin,
    required this.department,
    this.branchCode,
    this.branchName,
    this.role,
    required this.assigned,
    required this.done,
    required this.onTimeDone,
    required this.inProgress,
    required this.toBeStarted,
    required this.dropped,
    required this.overdue,
    required this.dueToday,
    required this.emergencyHighOpen,
    required this.onTime,
    required this.avgDays,
    required this.points,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    return TeamMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#d98a04',
      designation: json['designation'] as String?,
      lastLogin: json['last_login'] as String?,
      department: json['department'] as String? ?? '',
      branchCode: json['branch_code'] as String?,
      branchName: json['branch_name'] as String?,
      role: json['role'] as String?,
      assigned: json['assigned'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      onTimeDone: json['on_time_done'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      toBeStarted: json['to_be_started'] as int? ?? 0,
      dropped: json['dropped'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueToday: json['due_today'] as int? ?? 0,
      emergencyHighOpen: json['emergency_high_open'] as int? ?? 0,
      onTime: json['on_time'] as int? ?? 0,
      avgDays: (json['avg_days'] as num?)?.toDouble() ?? 0.0,
      points: json['points'] as int? ?? 0,
    );
  }
}

class TeamTotalsModel {
  final int teamSize;
  final int assigned;
  final int done;
  final int inProgress;
  final int toBeStarted;
  final int dropped;
  final int overdue;
  final int dueToday;
  final int emergencyHighOpen;
  final int points;
  final int completion;
  final int onTime;

  TeamTotalsModel({
    required this.teamSize,
    required this.assigned,
    required this.done,
    required this.inProgress,
    required this.toBeStarted,
    required this.dropped,
    required this.overdue,
    required this.dueToday,
    required this.emergencyHighOpen,
    required this.points,
    required this.completion,
    required this.onTime,
  });

  factory TeamTotalsModel.fromJson(Map<String, dynamic> json) {
    return TeamTotalsModel(
      teamSize: json['teamSize'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      toBeStarted: json['to_be_started'] as int? ?? 0,
      dropped: json['dropped'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueToday: json['due_today'] as int? ?? 0,
      emergencyHighOpen: json['emergency_high_open'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      completion: json['completion'] as int? ?? 0,
      onTime: json['on_time'] as int? ?? 0,
    );
  }
}

class DepartmentSummaryModel {
  final String department;
  final int members;
  final int assigned;
  final int done;
  final int overdue;
  final int completion;

  DepartmentSummaryModel({
    required this.department,
    required this.members,
    required this.assigned,
    required this.done,
    required this.overdue,
    required this.completion,
  });

  factory DepartmentSummaryModel.fromJson(Map<String, dynamic> json) {
    return DepartmentSummaryModel(
      department: json['department'] as String? ?? '',
      members: json['members'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      completion: json['completion'] as int? ?? 0,
    );
  }
}

class TeamPerformanceModel {
  final List<TeamMemberModel> members;
  final TeamTotalsModel totals;
  final List<DepartmentSummaryModel> departments;
  final int teamSize;

  TeamPerformanceModel({
    required this.members,
    required this.totals,
    required this.departments,
    required this.teamSize,
  });

  factory TeamPerformanceModel.fromJson(Map<String, dynamic> json) {
    return TeamPerformanceModel(
      members: json['members'] != null && json['members'] is List
          ? (json['members'] as List).map((e) => TeamMemberModel.fromJson(e)).toList()
          : [],
      totals: json['totals'] != null
          ? TeamTotalsModel.fromJson(json['totals'] as Map<String, dynamic>)
          : TeamTotalsModel(
              teamSize: 0, assigned: 0, done: 0, inProgress: 0, toBeStarted: 0, dropped: 0, overdue: 0, dueToday: 0, emergencyHighOpen: 0, points: 0, completion: 0, onTime: 0),
      departments: json['departments'] != null && json['departments'] is List
          ? (json['departments'] as List).map((e) => DepartmentSummaryModel.fromJson(e)).toList()
          : [],
      teamSize: json['teamSize'] as int? ?? 0,
    );
  }
}
