int _toInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value) ?? (double.tryParse(value)?.toInt() ?? defaultValue);
  }
  return defaultValue;
}

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

class TicketInsightsResponse {
  final int year;
  final List<InsightsMonthItem> byMonth;
  final List<InsightsCategoryItem> byCategory;
  final List<InsightsStaffItem> byStaff;
  final List<InsightsStudentItem> byStudent;
  final InsightsTotalsItem totals;

  const TicketInsightsResponse({
    this.year = 2026,
    this.byMonth = const [],
    this.byCategory = const [],
    this.byStaff = const [],
    this.byStudent = const [],
    this.totals = const InsightsTotalsItem(),
  });

  factory TicketInsightsResponse.fromJson(Map<String, dynamic> json) {
    return TicketInsightsResponse(
      year: _toInt(json['year'], DateTime.now().year),
      byMonth: (json['byMonth'] as List<dynamic>?)
              ?.map((e) => InsightsMonthItem.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList() ??
          [],
      byCategory: (json['byCategory'] as List<dynamic>?)
              ?.map((e) => InsightsCategoryItem.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList() ??
          [],
      byStaff: (json['byStaff'] as List<dynamic>?)
              ?.map((e) => InsightsStaffItem.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList() ??
          [],
      byStudent: (json['byStudent'] as List<dynamic>?)
              ?.map((e) => InsightsStudentItem.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList() ??
          [],
      totals: json['totals'] is Map<String, dynamic>
          ? InsightsTotalsItem.fromJson(json['totals'] as Map<String, dynamic>)
          : const InsightsTotalsItem(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'byMonth': byMonth.map((e) => e.toJson()).toList(),
      'byCategory': byCategory.map((e) => e.toJson()).toList(),
      'byStaff': byStaff.map((e) => e.toJson()).toList(),
      'byStudent': byStudent.map((e) => e.toJson()).toList(),
      'totals': totals.toJson(),
    };
  }
}

class InsightsMonthItem {
  final String month;
  final int complaints;
  final int feedback;
  final int appreciations;

  const InsightsMonthItem({
    required this.month,
    this.complaints = 0,
    this.feedback = 0,
    this.appreciations = 0,
  });

  int get total => complaints + feedback + appreciations;

  factory InsightsMonthItem.fromJson(Map<String, dynamic> json) {
    return InsightsMonthItem(
      month: json['month']?.toString() ?? '',
      complaints: _toInt(json['complaints']),
      feedback: _toInt(json['feedback']),
      appreciations: _toInt(json['appreciations']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'complaints': complaints,
      'feedback': feedback,
      'appreciations': appreciations,
    };
  }
}

class InsightsCategoryItem {
  final String category;
  final int count;

  const InsightsCategoryItem({
    required this.category,
    this.count = 0,
  });

  factory InsightsCategoryItem.fromJson(Map<String, dynamic> json) {
    return InsightsCategoryItem(
      category: json['category']?.toString() ?? '',
      count: _toInt(json['n'] ?? json['count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'n': count,
    };
  }
}

class InsightsStaffItem {
  final int id;
  final String name;
  final int appreciations;
  final int complaints;
  final int feedback;

  const InsightsStaffItem({
    required this.id,
    required this.name,
    this.appreciations = 0,
    this.complaints = 0,
    this.feedback = 0,
  });

  factory InsightsStaffItem.fromJson(Map<String, dynamic> json) {
    return InsightsStaffItem(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      appreciations: _toInt(json['appreciations']),
      complaints: _toInt(json['complaints']),
      feedback: _toInt(json['feedback']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'appreciations': appreciations,
      'complaints': complaints,
      'feedback': feedback,
    };
  }
}

class InsightsStudentItem {
  final String studentName;
  final String classSection;
  final int complaints;
  final int feedback;
  final int appreciations;
  final String lastAt;

  const InsightsStudentItem({
    required this.studentName,
    required this.classSection,
    this.complaints = 0,
    this.feedback = 0,
    this.appreciations = 0,
    required this.lastAt,
  });

  factory InsightsStudentItem.fromJson(Map<String, dynamic> json) {
    return InsightsStudentItem(
      studentName: json['student_name']?.toString() ?? json['studentName']?.toString() ?? '',
      classSection: json['class_section']?.toString() ?? json['classSection']?.toString() ?? '',
      complaints: _toInt(json['complaints']),
      feedback: _toInt(json['feedback']),
      appreciations: _toInt(json['appreciations']),
      lastAt: json['last_at']?.toString() ?? json['lastAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_name': studentName,
      'class_section': classSection,
      'complaints': complaints,
      'feedback': feedback,
      'appreciations': appreciations,
      'last_at': lastAt,
    };
  }
}

class InsightsTotalsItem {
  final int total;
  final int complaints;
  final int feedback;
  final int appreciations;
  final int resolved;
  final int pendingReward;
  final num? avgDays;
  final int fromParents;
  final int fromStudents;
  final int fromStaff;
  final int open;
  final int overdue;

  const InsightsTotalsItem({
    this.total = 0,
    this.complaints = 0,
    this.feedback = 0,
    this.appreciations = 0,
    this.resolved = 0,
    this.pendingReward = 0,
    this.avgDays,
    this.fromParents = 0,
    this.fromStudents = 0,
    this.fromStaff = 0,
    this.open = 0,
    this.overdue = 0,
  });

  factory InsightsTotalsItem.fromJson(Map<String, dynamic> json) {
    return InsightsTotalsItem(
      total: _toInt(json['total']),
      complaints: _toInt(json['complaints']),
      feedback: _toInt(json['feedback']),
      appreciations: _toInt(json['appreciations']),
      resolved: _toInt(json['resolved']),
      pendingReward: _toInt(json['pending_reward']),
      avgDays: _toNum(json['avg_days']),
      fromParents: _toInt(json['from_parents']),
      fromStudents: _toInt(json['from_students']),
      fromStaff: _toInt(json['from_staff']),
      open: _toInt(json['open']),
      overdue: _toInt(json['overdue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'complaints': complaints,
      'feedback': feedback,
      'appreciations': appreciations,
      'resolved': resolved,
      'pending_reward': pendingReward,
      'avg_days': avgDays,
      'from_parents': fromParents,
      'from_students': fromStudents,
      'from_staff': fromStaff,
      'open': open,
      'overdue': overdue,
    };
  }
}
