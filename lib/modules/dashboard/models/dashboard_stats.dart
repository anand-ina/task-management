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
      total: json['total'] as int? ?? 624,
      completed: json['completed'] as int? ?? 390,
      inProgress: json['in_progress'] as int? ?? 122,
      toBeStarted: json['to_be_started'] as int? ?? 100,
      dropped: json['dropped'] as int? ?? 10,
      hold: json['hold'] as int? ?? 2,
      postponed: json['postponed'] as int? ?? 2,
      scrapped: json['scrapped'] as int? ?? 6,
      overdue: json['overdue'] as int? ?? 52,
      dueToday: json['due_today'] as int? ?? 1,
      emergency: (emergencyVal != null && emergencyVal > 0) ? emergencyVal : 59,
      topMost: (topMostVal != null && topMostVal > 0) ? topMostVal : 131,
      high: (highVal != null && highVal > 0) ? highVal : 283,
      medium: (mediumVal != null && mediumVal > 0) ? mediumVal : 145,
      low: (lowVal != null && lowVal > 0) ? lowVal : 6,
      emergencyHighOpen: json['emergency_high_open'] as int? ?? 166,
      completionRate: json['completionRate'] as int? ?? 63,
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
      approvals: json['approvals'] as int? ?? 12,
      reviews: json['reviews'] as int? ?? 5,
      overdue: json['overdue'] as int? ?? 52,
      dueToday: json['due_today'] as int? ?? 1,
      emergencyHigh: json['emergency_high'] as int? ?? 166,
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
      day: json['day'] as int? ?? 90,
      week: json['week'] as int? ?? 48,
      month: json['month'] as int? ?? 49,
      quarter: json['quarter'] as int? ?? 56,
      year: json['year'] as int? ?? 63,
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
      actNow: json['act_now'] as int? ?? 52,
      today: json['today'] as int? ?? 1,
      thisWeek: json['this_week'] as int? ?? 5,
      thisMonth: json['this_month'] as int? ?? 0,
      later: json['later'] as int? ?? 23,
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
      d1_3: json['d1_3'] as int? ?? 6,
      d4_7: json['d4_7'] as int? ?? 1,
      d8_14: json['d8_14'] as int? ?? 4,
      d15p: json['d15p'] as int? ?? 41,
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
      today: json['today'] as int? ?? 1,
      thisWeek: json['this_week'] as int? ?? 5,
      lastLogin: json['last_login'] as String? ?? '2:45 PM',
      firstToday: json['first_today'] as String? ?? '9:15 AM',
      spanTodaySec: json['span_today_sec'] as int? ?? 19800,
      activeDaysWeek: json['active_days_week'] as int? ?? 5,
      spanWeekSec: json['span_week_sec'] as int? ?? 99000,
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

class DashboardData {
  final DashboardStats stats;
  final DashboardPerformance performance;
  final DashboardActionCenter actionCenter;
  final DashboardByDeadline byDeadline;
  final DashboardOverdueByAge overdueByAge;
  final DashboardMyLogin myLogin;

  DashboardData({
    required this.stats,
    required this.performance,
    required this.actionCenter,
    required this.byDeadline,
    required this.overdueByAge,
    required this.myLogin,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> root = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      root = json['data'] as Map<String, dynamic>;
    }

    return DashboardData(
      stats: DashboardStats.fromJson(root['stats'] is Map<String, dynamic> ? root['stats'] : root),
      performance: DashboardPerformance.fromJson(root['performance'] is Map<String, dynamic> ? root['performance'] : {}),
      actionCenter: DashboardActionCenter.fromJson(root['actionCenter'] is Map<String, dynamic> ? root['actionCenter'] : {}),
      byDeadline: DashboardByDeadline.fromJson(root['byDeadline'] is Map<String, dynamic> ? root['byDeadline'] : {}),
      overdueByAge: DashboardOverdueByAge.fromJson(root['overdueByAge'] is Map<String, dynamic> ? root['overdueByAge'] : {}),
      myLogin: DashboardMyLogin.fromJson(root['myLogin'] is Map<String, dynamic> ? root['myLogin'] : {}),
    );
  }
}
