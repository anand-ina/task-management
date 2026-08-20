class ReportStatsModel {
  final int total;
  final int submitted;
  final int draft;
  final int submittedToday;
  final int dsr;
  final int wsr;
  final int msr;

  ReportStatsModel({
    required this.total,
    required this.submitted,
    required this.draft,
    required this.submittedToday,
    required this.dsr,
    required this.wsr,
    required this.msr,
  });

  factory ReportStatsModel.fromJson(Map<String, dynamic> json) {
    return ReportStatsModel(
      total: json['total'] as int? ?? 0,
      submitted: json['submitted'] as int? ?? 0,
      draft: json['draft'] as int? ?? 0,
      submittedToday: json['submitted_today'] as int? ?? 0,
      dsr: json['dsr'] as int? ?? 0,
      wsr: json['wsr'] as int? ?? 0,
      msr: json['msr'] as int? ?? 0,
    );
  }
}
