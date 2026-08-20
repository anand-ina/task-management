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
    List<RecentActivityItem> recentList = (json['recentActivity'] as List<dynamic>?)
            ?.map((e) => RecentActivityItem.fromJson(e))
            .toList() ??
        [];

    if (recentList.isEmpty) {
      recentList = [
        RecentActivityItem(
          id: 1,
          actor: 'Nageshwari',
          initials: 'NA',
          avatarColor: '#ec4899',
          taskNo: '269/26',
          title: 'Hiring for Grade V-English -1 Position Science-1 Position Mother Teacher-2 Positions',
          description: 'Hiring for Grade V-English -1 Position Science-1 Position Mother Teacher-2 Positions',
          status: 'In Progress',
          priority: 'High',
          progress: 50,
          dueDate: '24 Jun 2026',
          completedDate: '—',
          branchCode: 'SS01',
          branchName: 'Moti Nagar & Sanath Nagar',
          note: 'working on "Hiring for Grade V-English -1 Position S"',
          at: '24 Jun 2026',
        ),
        RecentActivityItem(
          id: 2,
          actor: 'Ankima',
          initials: 'AN',
          avatarColor: '#ec4899',
          taskNo: '415/26',
          title: 'Fist of rice july month report preparation',
          description: 'Fist of rice july month report preparation',
          status: 'In Progress',
          priority: 'Medium',
          progress: 20,
          dueDate: '24 Jun 2026',
          completedDate: '—',
          branchCode: 'SS00',
          branchName: 'Head Office',
          note: 'working on "Fist of rice july month report preparati"',
          at: '24 Jun 2026',
        ),
        RecentActivityItem(
          id: 3,
          actor: 'Ankima',
          initials: 'AN',
          avatarColor: '#ec4899',
          taskNo: '248/26',
          title: 'Admission enquiry follow up calls from d',
          description: 'Admission enquiry follow up calls from d',
          status: 'Completed',
          priority: 'High',
          progress: 100,
          dueDate: '24 Jun 2026',
          completedDate: '24 Jun 2026',
          branchCode: 'SS01',
          branchName: 'Moti Nagar & Sanath Nagar',
          note: 'closed "Admission enquiry follow up calls from d"',
          at: '24 Jun 2026',
        ),
        RecentActivityItem(
          id: 4,
          actor: 'Narasimha',
          initials: 'NA',
          avatarColor: '#d97706',
          taskNo: '304/26',
          title: 'New bus stickering Design',
          description: 'New bus stickering Design',
          status: 'In Progress',
          priority: 'Top Most',
          progress: 70,
          dueDate: '23 Jun 2026',
          completedDate: '—',
          branchCode: 'SS00',
          branchName: 'Head Office',
          note: 'working on "New bus stickering Design"',
          at: '23 Jun 2026',
        ),
        RecentActivityItem(
          id: 5,
          actor: 'Vamsi',
          initials: 'VA',
          avatarColor: '#3b82f6',
          taskNo: '249/26',
          title: 'Spectrum education IIT foundation extra ',
          description: 'Spectrum education IIT foundation extra ',
          status: 'In Progress',
          priority: 'Emergency',
          progress: 90,
          dueDate: '23 Jun 2026',
          completedDate: '—',
          branchCode: 'SS00',
          branchName: 'Head Office',
          note: 'working on "Spectrum education IIT foundation extra "',
          at: '23 Jun 2026',
        ),
        RecentActivityItem(
          id: 6,
          actor: 'Revathi',
          initials: 'RE',
          avatarColor: '#8b5cf6',
          taskNo: '441/26',
          title: 'Preparing schedules for Audit - fees col',
          description: 'Preparing schedules for Audit - fees col',
          status: 'In Progress',
          priority: 'High',
          progress: 40,
          dueDate: '22 Jun 2026',
          completedDate: '—',
          branchCode: 'SS02',
          branchName: 'Peerzadiguda',
          note: 'working on "Preparing schedules for Audit - fees col"',
          at: '22 Jun 2026',
        ),
        RecentActivityItem(
          id: 7,
          actor: 'Ankima',
          initials: 'AN',
          avatarColor: '#ec4899',
          taskNo: '440/26',
          title: 'Weekly andmonthly report as per vamsi si',
          description: 'Weekly andmonthly report as per vamsi si',
          status: 'In Progress',
          priority: 'Medium',
          progress: 10,
          dueDate: '22 Jun 2026',
          completedDate: '—',
          branchCode: 'SS00',
          branchName: 'Head Office',
          note: 'picked up "Weekly andmonthly report as per vamsi si"',
          at: '22 Jun 2026',
        ),
        RecentActivityItem(
          id: 8,
          actor: 'Gyapika',
          initials: 'GY',
          avatarColor: '#10b981',
          taskNo: '439/26',
          title: 'Prepared excel sheet of grade wise admis',
          description: 'Prepared excel sheet of grade wise admis',
          status: 'Completed',
          priority: 'Low',
          progress: 100,
          dueDate: '21 Jun 2026',
          completedDate: '21 Jun 2026',
          branchCode: 'SS01',
          branchName: 'Moti Nagar & Sanath Nagar',
          note: 'closed "Prepared excel sheet of grade wise admis"',
          at: '21 Jun 2026',
        ),
      ];
    }

    List<TeamMemberPerformance> teamList = (json['teamPerformance'] as List<dynamic>?)
            ?.map((e) => TeamMemberPerformance.fromJson(e))
            .toList() ??
        [];

    if (teamList.isEmpty) {
      teamList = [
        TeamMemberPerformance(
          id: 5,
          name: 'Narasimha',
          initials: 'NA',
          avatarColor: '#d98a04',
          done: 130,
          assigned: 203,
          onTime: 99,
        ),
        TeamMemberPerformance(
          id: 10,
          name: 'Ankima',
          initials: 'AN',
          avatarColor: '#cf3d8a',
          done: 76,
          assigned: 114,
          onTime: 97,
        ),
        TeamMemberPerformance(
          id: 3,
          name: 'Murali',
          initials: 'MU',
          avatarColor: '#e5484d',
          done: 40,
          assigned: 62,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 14,
          name: 'Anusha',
          initials: 'AN',
          avatarColor: '#e5484d',
          done: 34,
          assigned: 39,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 9,
          name: 'sudhamahi',
          initials: 'SU',
          avatarColor: '#1f9d57',
          done: 31,
          assigned: 37,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 21,
          name: 'Rajkumar',
          initials: 'RA',
          avatarColor: '#3866d6',
          done: 30,
          assigned: 42,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 8,
          name: 'Chandra Kala',
          initials: 'CK',
          avatarColor: '#1f9d57',
          done: 28,
          assigned: 52,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 13,
          name: 'Revathi',
          initials: 'RE',
          avatarColor: '#cf3d8a',
          done: 25,
          assigned: 40,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 7,
          name: 'Gyapika',
          initials: 'GY',
          avatarColor: '#d98a04',
          done: 19,
          assigned: 26,
          onTime: 100,
        ),
        TeamMemberPerformance(
          id: 17,
          name: 'Tejaswi',
          initials: 'TE',
          avatarColor: '#0e9aa7',
          done: 10,
          assigned: 31,
          onTime: 100,
        ),
      ];
    }

    List<LoginGroupItem> groupList = (json['loginGroups'] as List<dynamic>?)
            ?.map((e) => LoginGroupItem.fromJson(e))
            .toList() ??
        [];

    if (groupList.isEmpty) {
      groupList = [
        LoginGroupItem(
          key: 'today',
          label: 'Active today',
          color: '#1f9d57',
          members: [
            LoginGroupMember(name: 'Madhumathi', initials: 'MA', color: '#e5484d'),
            LoginGroupMember(name: 'Vamsi', initials: 'VA', color: '#1f9d57'),
            LoginGroupMember(name: 'Gyapika', initials: 'GY', color: '#d98a04'),
          ],
        ),
        LoginGroupItem(
          key: 'd1_3',
          label: '1–3 days away',
          color: '#3866d6',
          members: [
            LoginGroupMember(name: 'Murali', initials: 'MU', color: '#e5484d'),
            LoginGroupMember(name: 'Anamika', initials: 'AN', color: '#d98a04'),
            LoginGroupMember(name: 'Swapnika', initials: 'SW', color: '#e5484d'),
            LoginGroupMember(name: 'Narasimha', initials: 'NA', color: '#d98a04'),
          ],
        ),
        LoginGroupItem(
          key: 'd4_6',
          label: '4–6 days away',
          color: '#d98a04',
          members: [],
        ),
        LoginGroupItem(
          key: 'd7',
          label: '7+ days away',
          color: '#e5484d',
          members: [
            LoginGroupMember(name: 'Rajkumar', initials: 'RA', color: '#3866d6'),
            LoginGroupMember(name: 'Narender', initials: 'NA', color: '#3866d6'),
          ],
        ),
        LoginGroupItem(
          key: 'never',
          label: 'Never signed in',
          color: '#8a93a8',
          members: [
            LoginGroupMember(name: 'Chandra Kala', initials: 'CK', color: '#1f9d57'),
            LoginGroupMember(name: 'sudhamahi', initials: 'SU', color: '#1f9d57'),
            LoginGroupMember(name: 'Ankima', initials: 'AN', color: '#cf3d8a'),
            LoginGroupMember(name: 'Renuka', initials: 'RE', color: '#1f9d57'),
            LoginGroupMember(name: 'Nageshwari', initials: 'NA', color: '#cf3d8a'),
            LoginGroupMember(name: 'Revathi', initials: 'RE', color: '#cf3d8a'),
            LoginGroupMember(name: 'Lalitha', initials: 'LA', color: '#8b5cf6'),
            LoginGroupMember(name: 'Syed Ahmed', initials: 'SA', color: '#e5484d'),
            LoginGroupMember(name: 'Tejaswi', initials: 'TE', color: '#0e9aa7'),
            LoginGroupMember(name: 'Durga Bhavani', initials: 'DB', color: '#d98a04'),
            LoginGroupMember(name: 'Aruna', initials: 'AR', color: '#cf3d8a'),
            LoginGroupMember(name: 'Aravinda', initials: 'AR', color: '#1f9d57'),
            LoginGroupMember(name: 'Kalpana', initials: 'KA', color: '#ef7d16'),
            LoginGroupMember(name: 'Surekha', initials: 'SU', color: '#cf3d8a'),
            LoginGroupMember(name: 'Priyanka', initials: 'PR', color: '#0e9aa7'),
            LoginGroupMember(name: 'Parimala', initials: 'PA', color: '#3866d6'),
            LoginGroupMember(name: 'Anusha', initials: 'AN', color: '#e5484d'),
          ],
        ),
      ];
    }

    final size = json['teamSize'] as int? ?? 26;

    return TeamData(
      recentActivity: recentList,
      teamPerformance: teamList,
      loginGroups: groupList,
      teamSize: size,
    );
  }

  Map<String, dynamic> toJson() => {
        'recentActivity': recentActivity.map((e) => e.toJson()).toList(),
        'teamPerformance': teamPerformance.map((e) => e.toJson()).toList(),
        'loginGroups': loginGroups.map((e) => e.toJson()).toList(),
        'teamSize': teamSize,
      };
}
