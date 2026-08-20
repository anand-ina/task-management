class ProfileStatsModel {
  final int total;
  final int completed;
  final int overdue;
  final int points;
  final int onTimeRate;
  final int completionRate;
  final int streak;

  ProfileStatsModel({
    required this.total,
    required this.completed,
    required this.overdue,
    required this.points,
    required this.onTimeRate,
    required this.completionRate,
    required this.streak,
  });

  factory ProfileStatsModel.fromJson(Map<String, dynamic> json) {
    return ProfileStatsModel(
      total: json['total'] is int ? json['total'] : (int.tryParse(json['total']?.toString() ?? '0') ?? 0),
      completed: json['completed'] is int ? json['completed'] : (int.tryParse(json['completed']?.toString() ?? '0') ?? 0),
      overdue: json['overdue'] is int ? json['overdue'] : (int.tryParse(json['overdue']?.toString() ?? '0') ?? 0),
      points: json['points'] is int ? json['points'] : (int.tryParse(json['points']?.toString() ?? '0') ?? 0),
      onTimeRate: json['onTimeRate'] is int ? json['onTimeRate'] : (int.tryParse(json['onTimeRate']?.toString() ?? '0') ?? 0),
      completionRate: json['completionRate'] is int ? json['completionRate'] : (int.tryParse(json['completionRate']?.toString() ?? '0') ?? 0),
      streak: json['streak'] is int ? json['streak'] : (int.tryParse(json['streak']?.toString() ?? '0') ?? 0),
    );
  }
}

class MyProfileModel {
  final int id;
  final String name;
  final String firstName;
  final String? lastName;
  final String email;
  final String phone;
  final String designation;
  final String employmentType;
  final String? responsibilities;
  final String avatarColor;
  final String initials;
  final String department;
  final String branchName;
  final String roleLabel;
  final ProfileStatsModel stats;

  MyProfileModel({
    required this.id,
    required this.name,
    required this.firstName,
    this.lastName,
    required this.email,
    required this.phone,
    required this.designation,
    required this.employmentType,
    this.responsibilities,
    required this.avatarColor,
    required this.initials,
    required this.department,
    required this.branchName,
    required this.roleLabel,
    required this.stats,
  });

  factory MyProfileModel.fromJson(Map<String, dynamic> json) {
    return MyProfileModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name']?.toString() ?? 'Vamsi',
      firstName: json['first_name']?.toString() ?? 'Vamsi',
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString() ?? 'vamsi@samskar.edu',
      phone: json['phone']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Director',
      employmentType: json['employment_type']?.toString() ?? 'non_teaching',
      responsibilities: json['responsibilities']?.toString(),
      avatarColor: json['avatar_color']?.toString() ?? '#1f9d57',
      initials: json['initials']?.toString() ?? 'VA',
      department: json['department']?.toString() ?? 'Administration',
      branchName: json['branch_name']?.toString() ?? 'Head Office',
      roleLabel: json['role_label']?.toString() ?? 'Director',
      stats: json['stats'] is Map<String, dynamic>
          ? ProfileStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : ProfileStatsModel(total: 6, completed: 2, overdue: 1, points: -4, onTimeRate: 100, completionRate: 33, streak: 0),
    );
  }
}
