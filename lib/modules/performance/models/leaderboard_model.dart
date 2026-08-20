class LeaderboardMemberModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String department;
  final int done;
  final int assigned;
  final int overdue;
  final int points;

  LeaderboardMemberModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.department,
    required this.done,
    required this.assigned,
    required this.overdue,
    required this.points,
  });

  factory LeaderboardMemberModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardMemberModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#d98a04',
      department: json['department'] as String? ?? '',
      done: json['done'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
    );
  }
}
