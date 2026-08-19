import 'recent_activity_model.dart';
import 'login_group_model.dart';

class TeamMemberPerformance {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final int done;
  final int assigned;
  final int onTime;

  TeamMemberPerformance({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.done,
    required this.assigned,
    required this.onTime,
  });

  factory TeamMemberPerformance.fromJson(Map<String, dynamic> json) {
    return TeamMemberPerformance(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#3866d6',
      done: json['done'] as int? ?? 0,
      assigned: json['assigned'] as int? ?? 0,
      onTime: json['on_time'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'avatar_color': avatarColor,
        'done': done,
        'assigned': assigned,
        'on_time': onTime,
      };
}

class TeamData {
  final List<RecentActivityItem> recentActivity;
  final List<TeamMemberPerformance> teamPerformance;
  final List<LoginGroupItem> loginGroups;
  final int teamSize;

  TeamData({
    required this.recentActivity,
    required this.teamPerformance,
    required this.loginGroups,
    required this.teamSize,
  });

  factory TeamData.fromJson(Map<String, dynamic> json) {
    return TeamData(
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((e) => RecentActivityItem.fromJson(e))
              .toList() ??
          [],
      teamPerformance: (json['teamPerformance'] as List<dynamic>?)
              ?.map((e) => TeamMemberPerformance.fromJson(e))
              .toList() ??
          [],
      loginGroups: (json['loginGroups'] as List<dynamic>?)
              ?.map((e) => LoginGroupItem.fromJson(e))
              .toList() ??
          [],
      teamSize: json['teamSize'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'recentActivity': recentActivity.map((e) => e.toJson()).toList(),
        'teamPerformance': teamPerformance.map((e) => e.toJson()).toList(),
        'loginGroups': loginGroups.map((e) => e.toJson()).toList(),
        'teamSize': teamSize,
      };
}
