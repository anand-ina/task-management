import 'ticket_model.dart';

class CreateTicketRequest {
  final String type; // 'complaint', 'feedback', 'appreciation'
  final String source; // 'parent', 'student'
  final String channel; // 'whatsapp_group', 'suggestion_box', 'walk_in', 'phone', 'other'
  final String? channelDetail;
  final String receivedAt; // ISO format e.g. "2026-09-18T10:42"
  final int branchId;
  final String studentName;
  final String classSection;
  final String? admissionNo;
  final String? parentName;
  final String? parentMobile;
  final bool isAnonymous;
  final String visibility; // 'general', 'confidential'
  final String aboutKind; // 'staff', 'department', 'transport', 'facility', 'general'
  final int? aboutUserId;
  final int? aboutDepartmentId;
  final String? aboutText;
  final String category;
  final String priority; // 'emergency', 'top_most', 'high', 'medium', 'low'
  final String description;
  final List<TicketAttachmentModel> attachments;

  const CreateTicketRequest({
    required this.type,
    required this.source,
    required this.channel,
    this.channelDetail,
    required this.receivedAt,
    required this.branchId,
    required this.studentName,
    required this.classSection,
    this.admissionNo,
    this.parentName,
    this.parentMobile,
    this.isAnonymous = false,
    this.visibility = 'general',
    required this.aboutKind,
    this.aboutUserId,
    this.aboutDepartmentId,
    this.aboutText,
    required this.category,
    required this.priority,
    required this.description,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'source': source,
      'channel': channel,
      if (channelDetail != null && channelDetail!.isNotEmpty) 'channelDetail': channelDetail,
      'receivedAt': receivedAt,
      'branchId': branchId,
      'studentName': studentName,
      'classSection': classSection,
      'admissionNo': admissionNo ?? '',
      'parentName': parentName ?? '',
      'parentMobile': parentMobile ?? '',
      'isAnonymous': isAnonymous,
      'visibility': visibility,
      'aboutKind': aboutKind,
      if (aboutUserId != null) 'aboutUserId': aboutUserId,
      if (aboutDepartmentId != null) 'aboutDepartmentId': aboutDepartmentId,
      'aboutText': aboutText ?? '',
      'category': category,
      'priority': priority,
      'description': description,
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
}
