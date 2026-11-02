class IndentLineItem {
  final int qty;
  final double amount;
  final double unitPrice;
  final String description;

  IndentLineItem({
    required this.qty,
    required this.amount,
    required this.unitPrice,
    required this.description,
  });

  factory IndentLineItem.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return IndentLineItem(
      qty: parseInt(json['qty']),
      amount: parseNum(json['amount']),
      unitPrice: parseNum(json['unitPrice'] ?? json['unit_price']),
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qty': qty,
      'amount': amount,
      'unitPrice': unitPrice,
      'description': description,
    };
  }
}

class IndentStepModel {
  final int stepNo;
  final int approverLevel;
  final String approverRole;
  final String? roleLabel;
  final bool isOptional;
  final String decision;
  final String? comment;
  final String? decidedAt;
  final String? decidedBy;
  final int? decidedByUserId;

  IndentStepModel({
    required this.stepNo,
    required this.approverLevel,
    this.approverRole = '',
    this.roleLabel,
    this.isOptional = false,
    required this.decision,
    this.comment,
    this.decidedAt,
    this.decidedBy,
    this.decidedByUserId,
  });

  bool get isPrincipalStep => approverRole == 'principal' || approverRole == 'center_head';
  bool get isDirectorStep => approverRole == 'director';
  bool get isFinanceStep => approverRole == 'finance_manager';

  /// Same label logic as the web portal (role_label first, then role / level).
  String get displayLabel {
    if (roleLabel != null && roleLabel!.isNotEmpty) return roleLabel!;
    if (isDirectorStep || approverLevel >= 5) return 'Director';
    if (isPrincipalStep || approverLevel == 4) return 'Center Head';
    return 'Finance Manager';
  }

  factory IndentStepModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final rawUserId = json['decided_by_user_id'] ?? json['decidedByUserId'];
    return IndentStepModel(
      stepNo: parseInt(json['step_no'] ?? json['stepNo']),
      approverLevel: parseInt(json['approver_level'] ?? json['approverLevel']),
      approverRole: json['approver_role']?.toString() ?? json['approverRole']?.toString() ?? '',
      roleLabel: json['role_label']?.toString() ?? json['roleLabel']?.toString(),
      isOptional: json['is_optional'] == true || json['isOptional'] == true,
      decision: json['decision']?.toString() ?? '',
      comment: json['comment']?.toString(),
      decidedAt: json['decided_at']?.toString() ?? json['decidedAt']?.toString(),
      decidedBy: json['decided_by']?.toString() ?? json['decidedBy']?.toString(),
      decidedByUserId: rawUserId == null ? null : parseInt(rawUserId),
    );
  }
}

class IndentAuditModel {
  final int id;
  final String action;
  final String? actorName;
  final String? comment;
  final String? createdAt;

  IndentAuditModel({
    required this.id,
    required this.action,
    this.actorName,
    this.comment,
    this.createdAt,
  });

  factory IndentAuditModel.fromJson(Map<String, dynamic> json) {
    return IndentAuditModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      action: json['action']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? json['actorName']?.toString(),
      comment: json['comment']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }
}

/// Response of POST /indents/{id}/decide
class IndentDecisionResponseModel {
  final String status;
  final String? voucherNo;
  final String? nextLevel;

  IndentDecisionResponseModel({required this.status, this.voucherNo, this.nextLevel});

  factory IndentDecisionResponseModel.fromJson(Map<String, dynamic> json) {
    return IndentDecisionResponseModel(
      status: json['status']?.toString() ?? '',
      voucherNo: json['voucherNo']?.toString() ?? json['voucher_no']?.toString(),
      nextLevel: json['nextLevel']?.toString() ?? json['next_level']?.toString(),
    );
  }
}

class IndentItemModel {
  final int id;
  final String indentNo;
  final String title;
  final String? purpose;
  final double amount;
  final String currency;
  final List<IndentLineItem> items;
  final int? branchId;
  final int? departmentId;
  final String? neededBy;
  final String status;
  final int? currentStep;
  final int? capLevel;
  final int? raiserLevel;
  final String? voucherNo;
  final String? createdAt;
  final String? decidedAt;
  final String? raisedBy;
  final String? branchName;
  final String? departmentName;
  final List<IndentStepModel> steps;
  final List<IndentAuditModel> audits;
  final bool isOverridden;
  final String? overrideDecision;
  final String? overrideComment;
  final String? overriddenAt;
  final String? overrideByName;

  IndentItemModel({
    required this.id,
    required this.indentNo,
    required this.title,
    this.purpose,
    required this.amount,
    this.currency = 'INR',
    this.items = const [],
    this.branchId,
    this.departmentId,
    this.neededBy,
    required this.status,
    this.currentStep,
    this.capLevel,
    this.raiserLevel,
    this.voucherNo,
    this.createdAt,
    this.decidedAt,
    this.raisedBy,
    this.branchName,
    this.departmentName,
    this.steps = const [],
    this.audits = const [],
    this.isOverridden = false,
    this.overrideDecision,
    this.overrideComment,
    this.overriddenAt,
    this.overrideByName,
  });

  factory IndentItemModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    List<IndentLineItem> parseItems(dynamic val) {
      if (val is List) {
        return val.map((e) => IndentLineItem.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
      return [];
    }

    List<IndentStepModel> parseSteps(dynamic val) {
      if (val is List) {
        return val.map((e) => IndentStepModel.fromJson(e is Map<String, dynamic> ? e : {})).toList();
      }
      return [];
    }

    return IndentItemModel(
      id: parseInt(json['id']),
      indentNo: json['indent_no']?.toString() ?? json['indentNo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      purpose: json['purpose']?.toString(),
      amount: parseNum(json['amount']),
      currency: json['currency']?.toString() ?? 'INR',
      items: parseItems(json['items']),
      branchId: json['branch_id'] is num ? (json['branch_id'] as num).toInt() : null,
      departmentId: json['department_id'] is num ? (json['department_id'] as num).toInt() : null,
      neededBy: json['needed_by']?.toString() ?? json['neededBy']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      currentStep: json['current_step'] is num ? (json['current_step'] as num).toInt() : null,
      capLevel: json['cap_level'] is num ? (json['cap_level'] as num).toInt() : null,
      raiserLevel: json['raiser_level'] is num ? (json['raiser_level'] as num).toInt() : null,
      voucherNo: json['voucher_no']?.toString() ?? json['voucherNo']?.toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
      decidedAt: json['decided_at']?.toString() ?? json['decidedAt']?.toString(),
      raisedBy: json['raised_by']?.toString() ?? json['raisedBy']?.toString(),
      branchName: json['branch_name']?.toString() ?? json['branchName']?.toString(),
      departmentName: json['department_name']?.toString() ?? json['departmentName']?.toString(),
      steps: parseSteps(json['steps']),
      audits: json['audits'] is List
          ? (json['audits'] as List)
              .map((e) => IndentAuditModel.fromJson(e is Map<String, dynamic> ? e : {}))
              .toList()
          : const [],
      isOverridden: json['is_overridden'] == true || json['isOverridden'] == true,
      overrideDecision: json['override_decision']?.toString(),
      overrideComment: json['override_comment']?.toString(),
      overriddenAt: json['overridden_at']?.toString(),
      overrideByName: json['override_by_name']?.toString(),
    );
  }
}

class CreateIndentResponseModel {
  final int id;
  final String indentNo;
  final String status;
  final String? voucherNo;

  CreateIndentResponseModel({
    required this.id,
    required this.indentNo,
    required this.status,
    this.voucherNo,
  });

  factory CreateIndentResponseModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return CreateIndentResponseModel(
      id: parseInt(json['id']),
      indentNo: json['indentNo']?.toString() ?? json['indent_no']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      voucherNo: json['voucherNo']?.toString() ?? json['voucher_no']?.toString(),
    );
  }
}

