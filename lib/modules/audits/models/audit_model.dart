class AuditPersonModel {
  final int id;
  final String name;
  final String? email;
  final String? role;

  AuditPersonModel({
    required this.id,
    required this.name,
    this.email,
    this.role,
  });

  factory AuditPersonModel.fromJson(Map<String, dynamic> json) {
    return AuditPersonModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['user_name'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String?,
    );
  }
}

class AuditBranchModel {
  final int id;
  final String code;
  final String name;

  AuditBranchModel({
    required this.id,
    required this.code,
    required this.name,
  });

  factory AuditBranchModel.fromJson(Map<String, dynamic> json) {
    return AuditBranchModel(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  String get displayName => code.isNotEmpty ? '$code — $name' : name;
}

class AuditMetaModel {
  final List<AuditPersonModel> people;
  final List<AuditBranchModel> branches;
  final bool canSchedule;

  AuditMetaModel({
    required this.people,
    required this.branches,
    this.canSchedule = true,
  });

  factory AuditMetaModel.fromJson(Map<String, dynamic> json) {
    final peopleList = json['people'] is List
        ? (json['people'] as List)
            .map((e) => AuditPersonModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList()
        : <AuditPersonModel>[];

    final branchesList = json['branches'] is List
        ? (json['branches'] as List)
            .map((e) => AuditBranchModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList()
        : <AuditBranchModel>[];

    return AuditMetaModel(
      people: peopleList,
      branches: branchesList,
      canSchedule: json['canSchedule'] as bool? ?? json['can_schedule'] as bool? ?? true,
    );
  }
}

class AuditChecklistItemModel {
  final int id;
  final int auditId;
  final String text;
  final bool done;
  final int commentCount;
  final int attachmentCount;

  AuditChecklistItemModel({
    required this.id,
    required this.auditId,
    required this.text,
    this.done = false,
    this.commentCount = 0,
    this.attachmentCount = 0,
  });

  factory AuditChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return AuditChecklistItemModel(
      id: json['id'] as int? ?? 0,
      auditId: json['audit_id'] as int? ?? 0,
      text: json['text'] as String? ?? json['title'] as String? ?? '',
      done: json['done'] as bool? ?? json['is_done'] as bool? ?? false,
      commentCount: json['comment_count'] as int? ?? 0,
      attachmentCount: json['attachment_count'] as int? ?? 0,
    );
  }

  AuditChecklistItemModel copyWith({bool? done}) {
    return AuditChecklistItemModel(
      id: id,
      auditId: auditId,
      text: text,
      done: done ?? this.done,
      commentCount: commentCount,
      attachmentCount: attachmentCount,
    );
  }
}

class AuditItemModel {
  final int id;
  final String title;
  final String? scopeNote;
  final int? auditorId;
  final String? auditorName;
  final int? auditeeBranchId;
  final String? auditeeBranchName;
  final int? auditeeUserId;
  final String? auditeeUserName;
  final String? scheduledDate;
  final String? dueDate;
  final String status;
  final bool canClose;
  final String? closedAt;
  final String? closedBy;
  final List<AuditChecklistItemModel> items;

  AuditItemModel({
    required this.id,
    required this.title,
    this.scopeNote,
    this.auditorId,
    this.auditorName,
    this.auditeeBranchId,
    this.auditeeBranchName,
    this.auditeeUserId,
    this.auditeeUserName,
    this.scheduledDate,
    this.dueDate,
    this.status = 'scheduled',
    this.canClose = false,
    this.closedAt,
    this.closedBy,
    this.items = const [],
  });

  factory AuditItemModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] is List
        ? (json['items'] as List)
            .map((e) => AuditChecklistItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
            .toList()
        : (json['checklist'] is List
            ? (json['checklist'] as List).asMap().entries.map((entry) {
                if (entry.value is Map<String, dynamic>) {
                  return AuditChecklistItemModel.fromJson(entry.value);
                }
                return AuditChecklistItemModel(
                  id: entry.key + 1,
                  auditId: json['id'] as int? ?? 0,
                  text: entry.value.toString(),
                  done: false,
                );
              }).toList()
            : <AuditChecklistItemModel>[]);

    return AuditItemModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      scopeNote: json['scope_note'] as String? ?? json['scopeNote'] as String?,
      auditorId: json['auditor_id'] as int? ?? json['auditorId'] as int?,
      auditorName: json['auditor_name'] as String? ?? json['auditorName'] as String?,
      auditeeBranchId: json['auditee_branch_id'] as int? ?? json['auditeeBranchId'] as int?,
      auditeeBranchName: json['auditee_branch_name'] as String? ?? json['branch_name'] as String?,
      auditeeUserId: json['auditee_user_id'] as int? ?? json['auditeeUserId'] as int?,
      auditeeUserName: json['auditee_user_name'] as String? ?? json['user_name'] as String?,
      scheduledDate: json['scheduled_date'] as String? ?? json['scheduledDate'] as String?,
      dueDate: json['due_date'] as String? ?? json['dueDate'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      canClose: json['canClose'] as bool? ?? json['can_close'] as bool? ?? false,
      closedAt: json['closed_at'] as String?,
      closedBy: json['closed_by']?.toString(),
      items: itemsList,
    );
  }
}
