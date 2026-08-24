class BulkColumnModel {
  final String field;
  final String header;
  final String? example;
  final String? note;

  BulkColumnModel({
    required this.field,
    required this.header,
    this.example,
    this.note,
  });

  factory BulkColumnModel.fromJson(Map<String, dynamic> json) {
    return BulkColumnModel(
      field: json['field'] as String? ?? '',
      header: json['header'] as String? ?? '',
      example: json['example'] as String?,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field,
        'header': header,
        'example': example,
        'note': note,
      };
}

class BulkTemplateModel {
  final List<BulkColumnModel> columns;
  final List<String> accepted;
  final String? note;

  BulkTemplateModel({
    required this.columns,
    required this.accepted,
    this.note,
  });

  factory BulkTemplateModel.fromJson(Map<String, dynamic> json) {
    List<BulkColumnModel> cols = [];
    if (json['columns'] is List) {
      cols = (json['columns'] as List)
          .map((e) => BulkColumnModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    List<String> acc = [];
    if (json['accepted'] is List) {
      acc = (json['accepted'] as List).map((e) => e.toString()).toList();
    }

    return BulkTemplateModel(
      columns: cols,
      accepted: acc,
      note: json['note'] as String?,
    );
  }
}

class BulkRowModel {
  final int line;
  final String? taskNo;
  final String title;
  final String? assigneeName;
  final List<int> assigneeIds;
  final List<String> assigneeNames;
  final List<String> unmatchedNames;
  final String? assignedByText;
  final int? branchId;
  final String? branchName;
  final String? priority;
  final String? status;
  final int progress;
  final String? entryDate;
  final String? dueDate;
  final String? completedDate;
  final String? remarks;
  final List<String> issues;
  final bool ok;

  BulkRowModel({
    required this.line,
    this.taskNo,
    required this.title,
    this.assigneeName,
    required this.assigneeIds,
    required this.assigneeNames,
    required this.unmatchedNames,
    this.assignedByText,
    this.branchId,
    this.branchName,
    this.priority,
    this.status,
    required this.progress,
    this.entryDate,
    this.dueDate,
    this.completedDate,
    this.remarks,
    required this.issues,
    required this.ok,
  });

  factory BulkRowModel.fromJson(Map<String, dynamic> json) {
    List<int> aIds = [];
    if (json['assigneeIds'] is List) {
      aIds = (json['assigneeIds'] as List)
          .map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    List<String> aNames = [];
    if (json['assigneeNames'] is List) {
      aNames = (json['assigneeNames'] as List).map((e) => e.toString()).toList();
    }

    List<String> uNames = [];
    if (json['unmatchedNames'] is List) {
      uNames = (json['unmatchedNames'] as List).map((e) => e.toString()).toList();
    }

    List<String> iss = [];
    if (json['issues'] is List) {
      iss = (json['issues'] as List).map((e) => e.toString()).toList();
    }

    return BulkRowModel(
      line: json['line'] as int? ?? 0,
      taskNo: json['taskNo'] as String?,
      title: json['title'] as String? ?? '',
      assigneeName: json['assigneeName'] as String?,
      assigneeIds: aIds,
      assigneeNames: aNames,
      unmatchedNames: uNames,
      assignedByText: json['assignedByText'] as String?,
      branchId: json['branchId'] as int?,
      branchName: json['branchName'] as String?,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      entryDate: json['entryDate'] as String?,
      dueDate: json['dueDate'] as String?,
      completedDate: json['completedDate'] as String?,
      remarks: json['remarks'] as String?,
      issues: iss,
      ok: json['ok'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'line': line,
        'taskNo': taskNo,
        'title': title,
        'assigneeName': assigneeName,
        'assigneeIds': assigneeIds,
        'assigneeNames': assigneeNames,
        'unmatchedNames': unmatchedNames,
        'assignedByText': assignedByText,
        'branchId': branchId,
        'branchName': branchName,
        'priority': priority,
        'status': status,
        'progress': progress,
        'entryDate': entryDate,
        'dueDate': dueDate,
        'completedDate': completedDate,
        'remarks': remarks,
        'issues': issues,
        'ok': ok,
      };
}

class BulkPreviewModel {
  final Map<String, String> mapping;
  final int headerRow;
  final int total;
  final int importable;
  final int skipped;
  final List<String> unmatchedNames;
  final List<BulkRowModel> rows;

  BulkPreviewModel({
    required this.mapping,
    required this.headerRow,
    required this.total,
    required this.importable,
    required this.skipped,
    required this.unmatchedNames,
    required this.rows,
  });

  factory BulkPreviewModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> map = {};
    if (json['mapping'] is Map) {
      (json['mapping'] as Map).forEach((key, value) {
        map[key.toString()] = value.toString();
      });
    }

    List<String> uNames = [];
    if (json['unmatchedNames'] is List) {
      uNames = (json['unmatchedNames'] as List).map((e) => e.toString()).toList();
    }

    List<BulkRowModel> rws = [];
    if (json['rows'] is List) {
      rws = (json['rows'] as List)
          .map((e) => BulkRowModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    return BulkPreviewModel(
      mapping: map,
      headerRow: json['headerRow'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      importable: json['importable'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      unmatchedNames: uNames,
      rows: rws,
    );
  }
}

class BulkCommitResponseModel {
  final bool ok;
  final int imported;
  final List<String> taskNos;

  BulkCommitResponseModel({
    required this.ok,
    required this.imported,
    required this.taskNos,
  });

  factory BulkCommitResponseModel.fromJson(Map<String, dynamic> json) {
    List<String> tNos = [];
    if (json['taskNos'] is List) {
      tNos = (json['taskNos'] as List).map((e) => e.toString()).toList();
    }

    return BulkCommitResponseModel(
      ok: json['ok'] as bool? ?? false,
      imported: json['imported'] as int? ?? 0,
      taskNos: tNos,
    );
  }
}
