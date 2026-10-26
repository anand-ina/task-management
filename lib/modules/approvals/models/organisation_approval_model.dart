import 'package:intl/intl.dart';

class OrganisationApprovalModel {
  final int id;
  final String status;
  final String? note;
  final String? createdAt;
  final int? taskId;
  final String? taskNo;
  final String? title;
  final String? priority;
  final int? branchId;
  final String? branchName;
  final String? branchCode;
  final int? requestedById;
  final String? requestedBy;
  final int? approverId;
  final String? approverName;

  OrganisationApprovalModel({
    required this.id,
    required this.status,
    this.note,
    this.createdAt,
    this.taskId,
    this.taskNo,
    this.title,
    this.priority,
    this.branchId,
    this.branchName,
    this.branchCode,
    this.requestedById,
    this.requestedBy,
    this.approverId,
    this.approverName,
  });

  factory OrganisationApprovalModel.fromJson(Map<String, dynamic> json) {
    return OrganisationApprovalModel(
      id: json['id'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      taskId: json['task_id'] as int?,
      taskNo: json['task_no'] as String?,
      title: json['title'] as String?,
      priority: json['priority'] as String?,
      branchId: json['branch_id'] as int?,
      branchName: json['branch_name'] as String?,
      branchCode: json['branch_code'] as String?,
      requestedById: json['requested_by_id'] as int?,
      requestedBy: json['requested_by'] as String?,
      approverId: json['approver_id'] as int?,
      approverName: json['approver_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'note': note,
      'created_at': createdAt,
      'task_id': taskId,
      'task_no': taskNo,
      'title': title,
      'priority': priority,
      'branch_id': branchId,
      'branch_name': branchName,
      'branch_code': branchCode,
      'requested_by_id': requestedById,
      'requested_by': requestedBy,
      'approver_id': approverId,
      'approver_name': approverName,
    };
  }

  String get formattedRequestedOn {
    if (createdAt == null || createdAt!.isEmpty) return '—';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      return DateFormat('d MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return createdAt!;
    }
  }
}
