class RecurringTaskModel {
  final int id;
  final String title;
  final String frequency;
  final String frequencyNote;
  final String? location;
  final String? remarks;
  final String assigneeText;
  final String branchCode;
  final String branchName;
  final String assigneeName;
  final String initials;
  final String avatarColor;

  RecurringTaskModel({
    required this.id,
    required this.title,
    required this.frequency,
    required this.frequencyNote,
    this.location,
    this.remarks,
    required this.assigneeText,
    required this.branchCode,
    required this.branchName,
    required this.assigneeName,
    required this.initials,
    required this.avatarColor,
  });

  factory RecurringTaskModel.fromJson(Map<String, dynamic> json) {
    return RecurringTaskModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      frequencyNote: json['frequency_note'] as String? ?? '',
      location: json['location'] as String?,
      remarks: json['remarks'] as String?,
      assigneeText: json['assignee_text'] as String? ?? '',
      branchCode: json['branch_code'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      assigneeName: json['assignee_name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#1f9d57',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'frequency': frequency,
        'frequency_note': frequencyNote,
        'location': location,
        'remarks': remarks,
        'assignee_text': assigneeText,
        'branch_code': branchCode,
        'branch_name': branchName,
        'assignee_name': assigneeName,
        'initials': initials,
        'avatar_color': avatarColor,
      };
}
