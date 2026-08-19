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
      emergency: json['emergency'] as int? ?? 0,
      topMost: json['top_most'] as int? ?? 0,
      high: json['high'] as int? ?? 0,
      medium: json['medium'] as int? ?? 0,
      low: json['low'] as int? ?? 0,
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
      day: json['day'] as int?,
      week: json['week'] as int?,
      month: json['month'] as int?,
      quarter: json['quarter'] as int?,
      year: json['year'] as int?,
    );
  }
}

class DashboardData {
  final DashboardStats stats;
  final DashboardPerformance performance;
  final DashboardActionCenter actionCenter;

  DashboardData({
    required this.stats,
    required this.performance,
    required this.actionCenter,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(json['stats'] ?? {}),
      performance: DashboardPerformance.fromJson(json['performance'] ?? {}),
      actionCenter: DashboardActionCenter.fromJson(json['actionCenter'] ?? {}),
    );
  }
}
