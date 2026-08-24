class DashboardStats {
  final int total;
  final int completed;
  final int inProgress;
  final int toBeStarted;
  final int dropped;
  final int hold;
  final int postponed;
  final int scrapped;
  final int overdue;
  final int dueToday;
  final int emergency;
  final int topMost;
  final int high;
  final int medium;
  final int low;
  final int emergencyHighOpen;
  final int completionRate;

  DashboardStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.toBeStarted,
    required this.dropped,
    required this.hold,
    required this.postponed,
    required this.scrapped,
    required this.overdue,
    required this.dueToday,
    required this.emergency,
    required this.topMost,
    required this.high,
    required this.medium,
    required this.low,
    required this.emergencyHighOpen,
    required this.completionRate,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final emergencyVal = json['emergency'] as int?;
    final topMostVal = json['top_most'] as int?;
    final highVal = json['high'] as int?;
    final mediumVal = json['medium'] as int?;
    final lowVal = json['low'] as int?;

    return DashboardStats(
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      toBeStarted: json['to_be_started'] as int? ?? 0,
      dropped: json['dropped'] as int? ?? 0,
      hold: json['hold'] as int? ?? 0,
      postponed: json['postponed'] as int? ?? 0,
      scrapped: json['scrapped'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueToday: json['due_today'] as int? ?? 0,
      emergency: (emergencyVal != null && emergencyVal > 0) ? emergencyVal : 0,
      topMost: (topMostVal != null && topMostVal > 0) ? topMostVal : 0,
      high: (highVal != null && highVal > 0) ? highVal : 0,
      medium: (mediumVal != null && mediumVal > 0) ? mediumVal : 0,
      low: (lowVal != null && lowVal > 0) ? lowVal : 6,
      emergencyHighOpen: json['emergency_high_open'] as int? ?? 0,
      completionRate: json['completionRate'] as int? ?? 0,
    );
  }
}

class DashboardActionCenter {
  final int approvals;
  final int reviews;
  final int overdue;
  final int dueToday;
  final int emergencyHigh;

  DashboardActionCenter({
    required this.approvals,
    required this.reviews,
    required this.overdue,
    required this.dueToday,
    required this.emergencyHigh,
  });

  factory DashboardActionCenter.fromJson(Map<String, dynamic> json) {
    return DashboardActionCenter(
      approvals: json['approvals'] as int? ?? 0,
      reviews: json['reviews'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueToday: json['due_today'] as int? ?? 0,
      emergencyHigh: json['emergency_high'] as int? ?? 0,
    );
  }
}

class DashboardPerformance {
  final int? day;
  final int? week;
  final int? month;
  final int? quarter;
  final int? year;

  DashboardPerformance({
    this.day,
    this.week,
    this.month,
    this.quarter,
    this.year,
  });

  factory DashboardPerformance.fromJson(Map<String, dynamic> json) {
    return DashboardPerformance(
      day: json['day'] as int? ?? 0,
      week: json['week'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      quarter: json['quarter'] as int? ?? 0,
      year: json['year'] as int? ?? 0,
    );
  }
}

class DashboardByDeadline {
  final int actNow;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int later;

  DashboardByDeadline({
    required this.actNow,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.later,
  });

  factory DashboardByDeadline.fromJson(Map<String, dynamic> json) {
    return DashboardByDeadline(
      actNow: json['act_now'] as int? ?? 0,
      today: json['today'] as int? ?? 0,
      thisWeek: json['this_week'] as int? ?? 0,
      thisMonth: json['this_month'] as int? ?? 0,
      later: json['later'] as int? ?? 0,
    );
  }
}

class DashboardOverdueByAge {
  final int d1_3;
  final int d4_7;
  final int d8_14;
  final int d15p;

  DashboardOverdueByAge({
    required this.d1_3,
    required this.d4_7,
    required this.d8_14,
    required this.d15p,
  });

  factory DashboardOverdueByAge.fromJson(Map<String, dynamic> json) {
    return DashboardOverdueByAge(
      d1_3: json['d1_3'] as int? ?? 0,
      d4_7: json['d4_7'] as int? ?? 0,
      d8_14: json['d8_14'] as int? ?? 0,
      d15p: json['d15p'] as int? ?? 0,
    );
  }
}

class DashboardMyLogin {
  final int today;
  final int thisWeek;
  final String lastLogin;
  final String firstToday;
  final int spanTodaySec;
  final int activeDaysWeek;
  final int spanWeekSec;

  DashboardMyLogin({
    required this.today,
    required this.thisWeek,
    required this.lastLogin,
    required this.firstToday,
    required this.spanTodaySec,
    required this.activeDaysWeek,
    required this.spanWeekSec,
  });

  factory DashboardMyLogin.fromJson(Map<String, dynamic> json) {
    return DashboardMyLogin(
      today: json['today'] as int? ?? 0,
      thisWeek: json['this_week'] as int? ?? 0,
      lastLogin: json['last_login'] as String? ?? '0:00 PM',
      firstToday: json['first_today'] as String? ?? '0:00 AM',
      spanTodaySec: json['span_today_sec'] as int? ?? 0,
      activeDaysWeek: json['active_days_week'] as int? ?? 0,
      spanWeekSec: json['span_week_sec'] as int? ?? 0,
    );
  }

  String get activeTodayHoursMinutes {
    final hours = spanTodaySec ~/ 3600;
    final minutes = (spanTodaySec % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get activeWeekHoursMinutes {
    final hours = spanWeekSec ~/ 3600;
    final minutes = (spanWeekSec % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
}

class DashboardTimelineItem {
  final String title;
  final String at;
  final String location;
  final String kind;
  final bool submitted;

  DashboardTimelineItem({
    required this.title,
    required this.at,
    required this.location,
    required this.kind,
    required this.submitted,
  });

  factory DashboardTimelineItem.fromJson(Map<String, dynamic> json) {
    return DashboardTimelineItem(
      title: json['title'] as String? ?? '',
      at: json['at'] as String? ?? '',
      location: json['location'] as String? ?? '',
      kind: json['kind'] as String? ?? '',
      submitted: json['submitted'] as bool? ?? false,
    );
  }
}

class DashboardData {
  final DashboardStats stats;
  final DashboardPerformance performance;
  final DashboardActionCenter actionCenter;
  final DashboardByDeadline byDeadline;
  final DashboardOverdueByAge overdueByAge;
  final DashboardMyLogin myLogin;
  final List<DashboardTimelineItem> timeline;

  DashboardData({
    required this.stats,
    required this.performance,
    required this.actionCenter,
    required this.byDeadline,
    required this.overdueByAge,
    required this.myLogin,
    this.timeline = const [],
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> root = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      root = json['data'] as Map<String, dynamic>;
    }

    final timelineList = (root['timeline'] as List<dynamic>?)
            ?.map((e) => DashboardTimelineItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DashboardData(
      stats: DashboardStats.fromJson(root['stats'] is Map<String, dynamic> ? root['stats'] : root),
      performance: DashboardPerformance.fromJson(root['performance'] is Map<String, dynamic> ? root['performance'] : {}),
      actionCenter: DashboardActionCenter.fromJson(root['actionCenter'] is Map<String, dynamic> ? root['actionCenter'] : {}),
      byDeadline: DashboardByDeadline.fromJson(root['byDeadline'] is Map<String, dynamic> ? root['byDeadline'] : {}),
      overdueByAge: DashboardOverdueByAge.fromJson(root['overdueByAge'] is Map<String, dynamic> ? root['overdueByAge'] : {}),
      myLogin: DashboardMyLogin.fromJson(root['myLogin'] is Map<String, dynamic> ? root['myLogin'] : {}),
      timeline: timelineList,
    );
  }
}
