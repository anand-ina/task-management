import 'ticket_model.dart';

class SuggestionSlipRowRequest {
  final String type;
  final String studentName;
  final String classSection;
  final String aboutKind;
  final int? aboutUserId;
  final String category;
  final String description;
  final String visibility;
  final List<TicketAttachmentModel> attachments;
  final bool isAnonymous;

  const SuggestionSlipRowRequest({
    required this.type,
    required this.studentName,
    required this.classSection,
    required this.aboutKind,
    this.aboutUserId,
    required this.category,
    required this.description,
    required this.visibility,
    this.attachments = const [],
    required this.isAnonymous,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type,
      'studentName': studentName,
      'classSection': classSection,
      'aboutKind': aboutKind,
      'category': category,
      'description': description,
      'visibility': visibility,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'isAnonymous': isAnonymous,
    };
    if (aboutUserId != null) {
      map['aboutUserId'] = aboutUserId;
    }
    return map;
  }
}

class BatchTicketRequest {
  final int? branchId;
  final String receivedAt;
  final List<SuggestionSlipRowRequest> rows;

  const BatchTicketRequest({
    this.branchId,
    required this.receivedAt,
    required this.rows,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'receivedAt': receivedAt,
      'rows': rows.map((r) => r.toJson()).toList(),
    };
    if (branchId != null) {
      map['branchId'] = branchId;
    }
    return map;
  }
}
