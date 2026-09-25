import 'ticket_model.dart';
import 'package:intl/intl.dart';

class DraftItemModel {
  final int id;
  final String kind;
  final String label;
  final String? updatedAt;
  final DraftPayloadModel? payload;

  const DraftItemModel({
    required this.id,
    required this.kind,
    required this.label,
    this.updatedAt,
    this.payload,
  });

  factory DraftItemModel.fromJson(Map<String, dynamic> json) {
    return DraftItemModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kind: json['kind']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? DraftPayloadModel.fromJson(json['payload'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'label': label,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (payload != null) 'payload': payload!.toJson(),
    };
  }

  String get formattedDisplayDate {
    if (updatedAt == null || updatedAt!.isEmpty) return '';
    try {
      final dt = DateTime.parse(updatedAt!).toLocal();
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      return updatedAt!;
    }
  }
}

class DraftPayloadModel {
  final String type;
  final String source;
  final String channel;
  final String? channelDetail;
  final String? receivedAt;
  final int? branchId;
  final String? studentName;
  final String? classSection;
  final String? admissionNo;
  final String? parentName;
  final String? parentMobile;
  final bool isAnonymous;
  final String? visibility;
  final String? aboutKind;
  final int? aboutUserId;
  final int? aboutDepartmentId;
  final String? aboutText;
  final String? category;
  final String? priority;
  final String? description;
  final List<TicketAttachmentModel> attachments;

  const DraftPayloadModel({
    this.type = 'complaint',
    this.source = 'parent',
    this.channel = 'whatsapp_group',
    this.channelDetail,
    this.receivedAt,
    this.branchId,
    this.studentName,
    this.classSection,
    this.admissionNo,
    this.parentName,
    this.parentMobile,
    this.isAnonymous = false,
    this.visibility = 'general',
    this.aboutKind = 'staff',
    this.aboutUserId,
    this.aboutDepartmentId,
    this.aboutText,
    this.category = 'Other',
    this.priority = 'medium',
    this.description,
    this.attachments = const [],
  });

  factory DraftPayloadModel.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    List<TicketAttachmentModel> parsedAttachments = [];
    if (json['attachments'] is List) {
      parsedAttachments = (json['attachments'] as List)
          .whereType<Map<String, dynamic>>()
          .map((a) => TicketAttachmentModel.fromJson(a))
          .toList();
    }

    return DraftPayloadModel(
      type: json['type']?.toString() ?? 'complaint',
      source: json['source']?.toString() ?? 'parent',
      channel: json['channel']?.toString() ?? 'whatsapp_group',
      channelDetail: json['channelDetail']?.toString(),
      receivedAt: json['receivedAt']?.toString(),
      branchId: parseId(json['branchId']),
      studentName: json['studentName']?.toString(),
      classSection: json['classSection']?.toString(),
      admissionNo: json['admissionNo']?.toString(),
      parentName: json['parentName']?.toString(),
      parentMobile: json['parentMobile']?.toString(),
      isAnonymous: json['isAnonymous'] == true || json['isAnonymous']?.toString() == 'true',
      visibility: json['visibility']?.toString() ?? 'general',
      aboutKind: json['aboutKind']?.toString() ?? 'staff',
      aboutUserId: parseId(json['aboutUserId']),
      aboutDepartmentId: parseId(json['aboutDepartmentId']),
      aboutText: json['aboutText']?.toString(),
      category: json['category']?.toString() ?? 'Other',
      priority: json['priority']?.toString() ?? 'medium',
      description: json['description']?.toString(),
      attachments: parsedAttachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'source': source,
      'channel': channel,
      'channelDetail': channelDetail ?? '',
      'receivedAt': receivedAt ?? '',
      if (branchId != null) 'branchId': branchId,
      'studentName': studentName ?? '',
      'classSection': classSection ?? '',
      'admissionNo': admissionNo ?? '',
      'parentName': parentName ?? '',
      'parentMobile': parentMobile ?? '',
      'isAnonymous': isAnonymous,
      'visibility': visibility ?? 'general',
      'aboutKind': aboutKind ?? 'staff',
      if (aboutUserId != null) 'aboutUserId': aboutUserId,
      if (aboutDepartmentId != null) 'aboutDepartmentId': aboutDepartmentId,
      'aboutText': aboutText ?? '',
      'category': category ?? 'Other',
      'priority': priority ?? 'medium',
      'description': description ?? '',
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }
}

class DraftSaveRequest {
  final String kind;
  final String label;
  final DraftPayloadModel payload;

  const DraftSaveRequest({
    this.kind = 'ticket',
    required this.label,
    required this.payload,
  });

  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'label': label,
      'payload': payload.toJson(),
    };
  }
}
