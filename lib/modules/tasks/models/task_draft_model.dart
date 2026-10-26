import 'dart:convert';
import 'package:intl/intl.dart';

class TaskDraftModel {
  final int id;
  final String kind;
  final String label;
  final TaskDraftPayload payload;
  final String? updatedAt;
  final String? createdAt;

  TaskDraftModel({
    required this.id,
    required this.kind,
    required this.label,
    required this.payload,
    this.updatedAt,
    this.createdAt,
  });

  factory TaskDraftModel.fromJson(Map<String, dynamic> json) {
    dynamic payloadRaw = json['payload'];
    if (payloadRaw is String) {
      try {
        payloadRaw = jsonDecode(payloadRaw);
      } catch (_) {}
    }
    return TaskDraftModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kind: json['kind']?.toString() ?? 'task',
      label: json['label']?.toString() ?? '',
      payload: payloadRaw is Map<String, dynamic>
          ? TaskDraftPayload.fromJson(payloadRaw)
          : (payloadRaw is Map
              ? TaskDraftPayload.fromJson(Map<String, dynamic>.from(payloadRaw))
              : TaskDraftPayload()),
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'label': label,
      'payload': payload.toJson(),
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  String get formattedDisplayDate {
    final dateStr = updatedAt ?? createdAt;
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

class TaskDraftPayload {
  final String title;
  final String description;
  final int? branchId;
  final String priority;
  final String category;
  final String? dueDate;
  final String remarks;
  final bool isRecurring;
  final String frequency;
  final String recurTime;
  final int weekday;
  final int monthday;
  final String specificDate;
  final bool splitPerAssignee;
  final String assignedById;
  final List<int> assigneeIds;
  final List<String> assigneeNames;
  final List<Map<String, dynamic>> checklist;
  final List<Map<String, dynamic>> attachments;

  TaskDraftPayload({
    this.title = '',
    this.description = '',
    this.branchId,
    this.priority = 'high',
    this.category = 'General',
    this.dueDate,
    this.remarks = '',
    this.isRecurring = false,
    this.frequency = 'daily',
    this.recurTime = '18:00',
    this.weekday = 1,
    this.monthday = 1,
    this.specificDate = '',
    this.splitPerAssignee = true,
    this.assignedById = '',
    this.assigneeIds = const [],
    this.assigneeNames = const [],
    this.checklist = const [],
    this.attachments = const [],
  });

  factory TaskDraftPayload.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val != 0;
      final str = val?.toString().toLowerCase().trim();
      return str == 'true' || str == '1' || str == 'yes';
    }

    return TaskDraftPayload(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      branchId: json['branchId'] is int
          ? json['branchId'] as int
          : int.tryParse(json['branchId']?.toString() ?? ''),
      priority: json['priority']?.toString().isNotEmpty == true ? json['priority'].toString() : 'high',
      category: json['category']?.toString().isNotEmpty == true ? json['category'].toString() : 'General',
      dueDate: json['dueDate']?.toString() ?? json['due_date']?.toString(),
      remarks: json['remarks']?.toString() ?? '',
      isRecurring: parseBool(json['isRecurring'] ?? json['is_recurring']),
      frequency: json['frequency']?.toString() ?? 'daily',
      recurTime: json['recurTime']?.toString() ?? json['recur_time']?.toString() ?? '18:00',
      weekday: json['weekday'] is int
          ? json['weekday'] as int
          : int.tryParse(json['weekday']?.toString() ?? '1') ?? 1,
      monthday: json['monthday'] is int
          ? json['monthday'] as int
          : int.tryParse(json['monthday']?.toString() ?? '1') ?? 1,
      specificDate: json['specificDate']?.toString() ?? json['specific_date']?.toString() ?? '',
      splitPerAssignee: json['splitPerAssignee'] != null
          ? parseBool(json['splitPerAssignee'])
          : (json['split_per_assignee'] != null ? parseBool(json['split_per_assignee']) : true),
      assignedById: json['assignedById']?.toString() ?? json['assigned_by_id']?.toString() ?? '',
      assigneeIds: (json['assigneeIds'] is List)
          ? (json['assigneeIds'] as List)
              .map((e) => e is int ? e : (int.tryParse(e?.toString() ?? '') ?? 0))
              .where((e) => e > 0)
              .toList()
          : ((json['assignee_ids'] is List)
              ? (json['assignee_ids'] as List)
                  .map((e) => e is int ? e : (int.tryParse(e?.toString() ?? '') ?? 0))
                  .where((e) => e > 0)
                  .toList()
              : const []),
      assigneeNames: (json['assigneeNames'] is List)
          ? (json['assigneeNames'] as List)
              .map((e) => e is Map ? (e['name']?.toString() ?? '') : e?.toString() ?? '')
              .where((name) => name.isNotEmpty)
              .toList()
          : ((json['assignee_names'] is List)
              ? (json['assignee_names'] as List)
                  .map((e) => e is Map ? (e['name']?.toString() ?? '') : e?.toString() ?? '')
                  .where((name) => name.isNotEmpty)
                  .toList()
              : const []),
      checklist: (json['checklist'] is List)
          ? (json['checklist'] as List)
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{'item': e.toString()})
              .toList()
          : const [],
      attachments: (json['attachments'] is List)
          ? (json['attachments'] as List)
              .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      if (branchId != null) 'branchId': branchId,
      'priority': priority,
      'category': category,
      if (dueDate != null) 'dueDate': dueDate,
      'remarks': remarks,
      'isRecurring': isRecurring,
      'frequency': frequency,
      'recurTime': recurTime,
      'weekday': weekday,
      'monthday': monthday,
      'specificDate': specificDate,
      'splitPerAssignee': splitPerAssignee,
      'assignedById': assignedById,
      'assigneeIds': assigneeIds,
      'assigneeNames': assigneeNames,
      'checklist': checklist,
      'attachments': attachments,
    };
  }
}
