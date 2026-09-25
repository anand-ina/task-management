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
  final String decision;
  final String? comment;
  final String? decidedAt;
  final String? decidedBy;

  IndentStepModel({
    required this.stepNo,
    required this.approverLevel,
    required this.decision,
    this.comment,
    this.decidedAt,
    this.decidedBy,
  });

  factory IndentStepModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return IndentStepModel(
      stepNo: parseInt(json['step_no'] ?? json['stepNo']),
      approverLevel: parseInt(json['approver_level'] ?? json['approverLevel']),
      decision: json['decision']?.toString() ?? '',
      comment: json['comment']?.toString(),
      decidedAt: json['decided_at']?.toString() ?? json['decidedAt']?.toString(),
      decidedBy: json['decided_by']?.toString() ?? json['decidedBy']?.toString(),
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

