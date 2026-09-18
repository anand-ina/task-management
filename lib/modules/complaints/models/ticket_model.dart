class TicketAssigneeModel {
  final int id;
  final String name;
  final String initials;
  final String color;

  const TicketAssigneeModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
  });

  factory TicketAssigneeModel.fromJson(Map<String, dynamic> json) {
    return TicketAssigneeModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      initials: json['initials']?.toString() ?? '',
      color: json['color']?.toString() ?? '#3B82F6',
    );
  }
}

class TicketAttachmentModel {
  final int? id;
  final String filename;
  final String? url;
  final String? mime;
  final int? size;
  final String? createdAt;
  final String? uploadedByName;

  const TicketAttachmentModel({
    this.id,
    required this.filename,
    this.url,
    this.mime,
    this.size,
    this.createdAt,
    this.uploadedByName,
  });

  factory TicketAttachmentModel.fromJson(Map<String, dynamic> json) {
    return TicketAttachmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      filename: json['filename']?.toString() ?? '',
      url: json['url']?.toString(),
      mime: json['mime']?.toString(),
      size: json['size'] is int ? json['size'] : int.tryParse(json['size']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
      uploadedByName: json['uploaded_by_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      if (url != null) 'url': url,
      if (mime != null) 'mime': mime,
      if (size != null) 'size': size,
    };
  }
}

class TicketEventModel {
  final int id;
  final String kind;
  final String note;
  final String createdAt;
  final String? actor;

  const TicketEventModel({
    required this.id,
    required this.kind,
    required this.note,
    required this.createdAt,
    this.actor,
  });

  factory TicketEventModel.fromJson(Map<String, dynamic> json) {
    return TicketEventModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kind: json['kind']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      actor: json['actor']?.toString(),
    );
  }
}

class TicketItemModel {
  final int id;
  final int tenantId;
  final String ticketNo;
  final String type;
  final String source;
  final String channel;
  final String? channelDetail;
  final String? channelLabel;
  final String receivedAt;
  final int branchId;
  final String? branchCode;
  final String? branchName;
  final String? studentName;
  final String? classSection;
  final String? admissionNo;
  final String? parentName;
  final String? parentMobile;
  final String? countryCode;
  final bool isAnonymous;
  final String visibility;
  final String aboutKind;
  final int? aboutUserId;
  final String? aboutUserName;
  final int? aboutDepartmentId;
  final String? aboutDepartmentName;
  final String? aboutText;
  final String category;
  final String priority;
  final String description;
  final String status;
  final int? ownerId;
  final String? ownerName;
  final int? taskId;
  final String? taskNo;
  final String? taskStatus;
  final String? taskDueDate;
  final int? taskProgress;
  final List<TicketAssigneeModel> taskAssignees;
  final String? resolution;
  final int? raisedBy;
  final String? raisedByName;
  final String createdAt;
  final bool parentHidden;
  final bool canManage;
  final bool canAward;
  final List<TicketAttachmentModel> attachments;
  final List<TicketEventModel> events;

  const TicketItemModel({
    required this.id,
    required this.tenantId,
    required this.ticketNo,
    required this.type,
    required this.source,
    required this.channel,
    this.channelDetail,
    this.channelLabel,
    required this.receivedAt,
    required this.branchId,
    this.branchCode,
    this.branchName,
    this.studentName,
    this.classSection,
    this.admissionNo,
    this.parentName,
    this.parentMobile,
    this.countryCode,
    required this.isAnonymous,
    required this.visibility,
    required this.aboutKind,
    this.aboutUserId,
    this.aboutUserName,
    this.aboutDepartmentId,
    this.aboutDepartmentName,
    this.aboutText,
    required this.category,
    required this.priority,
    required this.description,
    required this.status,
    this.ownerId,
    this.ownerName,
    this.taskId,
    this.taskNo,
    this.taskStatus,
    this.taskDueDate,
    this.taskProgress,
    this.taskAssignees = const [],
    this.resolution,
    this.raisedBy,
    this.raisedByName,
    required this.createdAt,
    this.parentHidden = false,
    this.canManage = true,
    this.canAward = false,
    this.attachments = const [],
    this.events = const [],
  });

  factory TicketItemModel.fromJson(Map<String, dynamic> json) {
    List<TicketAssigneeModel> assigneesList = [];
    if (json['task_assignees'] is List) {
      assigneesList = (json['task_assignees'] as List)
          .map((e) => TicketAssigneeModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    List<TicketAttachmentModel> attachmentsList = [];
    if (json['attachments'] is List) {
      attachmentsList = (json['attachments'] as List)
          .map((e) => TicketAttachmentModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    List<TicketEventModel> eventsList = [];
    if (json['events'] is List) {
      eventsList = (json['events'] as List)
          .map((e) => TicketEventModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    return TicketItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] : int.tryParse(json['tenant_id']?.toString() ?? '0') ?? 0,
      ticketNo: json['ticket_no']?.toString() ?? '',
      type: json['type']?.toString() ?? 'complaint',
      source: json['source']?.toString() ?? 'parent',
      channel: json['channel']?.toString() ?? 'other',
      channelDetail: json['channel_detail']?.toString(),
      channelLabel: json['channel_label']?.toString(),
      receivedAt: json['received_at']?.toString() ?? '',
      branchId: json['branch_id'] is int ? json['branch_id'] : int.tryParse(json['branch_id']?.toString() ?? '0') ?? 0,
      branchCode: json['branch_code']?.toString(),
      branchName: json['branch_name']?.toString(),
      studentName: json['student_name']?.toString(),
      classSection: json['class_section']?.toString(),
      admissionNo: json['admission_no']?.toString(),
      parentName: json['parent_name']?.toString(),
      parentMobile: json['parent_mobile']?.toString(),
      countryCode: json['country_code']?.toString(),
      isAnonymous: json['is_anonymous'] == true || json['is_anonymous'] == 1,
      visibility: json['visibility']?.toString() ?? 'general',
      aboutKind: json['about_kind']?.toString() ?? 'general',
      aboutUserId: json['about_user_id'] is int ? json['about_user_id'] : int.tryParse(json['about_user_id']?.toString() ?? ''),
      aboutUserName: json['about_user_name']?.toString(),
      aboutDepartmentId: json['about_department_id'] is int ? json['about_department_id'] : int.tryParse(json['about_department_id']?.toString() ?? ''),
      aboutDepartmentName: json['about_department_name']?.toString(),
      aboutText: json['about_text']?.toString(),
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'new',
      ownerId: json['owner_id'] is int ? json['owner_id'] : int.tryParse(json['owner_id']?.toString() ?? ''),
      ownerName: json['owner_name']?.toString(),
      taskId: json['task_id'] is int ? json['task_id'] : int.tryParse(json['task_id']?.toString() ?? ''),
      taskNo: json['task_no']?.toString(),
      taskStatus: json['task_status']?.toString(),
      taskDueDate: json['task_due_date']?.toString(),
      taskProgress: json['task_progress'] is int ? json['task_progress'] : int.tryParse(json['task_progress']?.toString() ?? ''),
      taskAssignees: assigneesList,
      resolution: json['resolution']?.toString(),
      raisedBy: json['raised_by'] is int ? json['raised_by'] : int.tryParse(json['raised_by']?.toString() ?? ''),
      raisedByName: json['raised_by_name']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      parentHidden: json['parent_hidden'] == true || json['parent_hidden'] == 1,
      canManage: json['can_manage'] != false,
      canAward: json['can_award'] == true,
      attachments: attachmentsList,
      events: eventsList,
    );
  }
}

class TicketCountsModel {
  final int newCount;
  final int inProgress;
  final int overdue;
  final int resolvedMonth;
  final int pendingReward;
  final dynamic avgDays;

  const TicketCountsModel({
    this.newCount = 0,
    this.inProgress = 0,
    this.overdue = 0,
    this.resolvedMonth = 0,
    this.pendingReward = 0,
    this.avgDays,
  });

  factory TicketCountsModel.fromJson(Map<String, dynamic> json) {
    return TicketCountsModel(
      newCount: json['new'] is int ? json['new'] : int.tryParse(json['new']?.toString() ?? '0') ?? 0,
      inProgress: json['in_progress'] is int ? json['in_progress'] : int.tryParse(json['in_progress']?.toString() ?? '0') ?? 0,
      overdue: json['overdue'] is int ? json['overdue'] : int.tryParse(json['overdue']?.toString() ?? '0') ?? 0,
      resolvedMonth: json['resolved_month'] is int ? json['resolved_month'] : int.tryParse(json['resolved_month']?.toString() ?? '0') ?? 0,
      pendingReward: json['pending_reward'] is int ? json['pending_reward'] : int.tryParse(json['pending_reward']?.toString() ?? '0') ?? 0,
      avgDays: json['avg_days'],
    );
  }
}

class TicketListResponse {
  final List<TicketItemModel> items;
  final TicketCountsModel counts;

  const TicketListResponse({
    required this.items,
    required this.counts,
  });

  factory TicketListResponse.fromJson(Map<String, dynamic> json) {
    List<TicketItemModel> itemsList = [];
    if (json['items'] is List) {
      itemsList = (json['items'] as List)
          .map((e) => TicketItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    TicketCountsModel countsModel = const TicketCountsModel();
    if (json['counts'] is Map<String, dynamic>) {
      countsModel = TicketCountsModel.fromJson(json['counts'] as Map<String, dynamic>);
    }

    return TicketListResponse(
      items: itemsList,
      counts: countsModel,
    );
  }
}
