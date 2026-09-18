class AdminAuditLogModel {
  final int id;
  final String action;
  final String detail;
  final DateTime at;
  final int actorId;
  final int targetUserId;
  final String actor;
  final String target;

  const AdminAuditLogModel({
    required this.id,
    required this.action,
    required this.detail,
    required this.at,
    required this.actorId,
    required this.targetUserId,
    required this.actor,
    required this.target,
  });

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['at'] != null
          ? DateTime.parse(json['at'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AdminAuditLogModel(
      id: json['id'] as int? ?? 0,
      action: json['action'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      at: parsedDate,
      actorId: json['actor_id'] as int? ?? 0,
      targetUserId: json['target_user_id'] as int? ?? 0,
      actor: json['actor'] as String? ?? '',
      target: json['target'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'detail': detail,
        'at': at.toIso8601String(),
        'actor_id': actorId,
        'target_user_id': targetUserId,
        'actor': actor,
        'target': target,
      };
}
