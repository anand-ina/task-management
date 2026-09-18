class CreatedTicketTaskItem {
  final String ticketNo;
  final String? taskNo;

  const CreatedTicketTaskItem({
    required this.ticketNo,
    this.taskNo,
  });

  factory CreatedTicketTaskItem.fromJson(Map<String, dynamic> json) {
    return CreatedTicketTaskItem(
      ticketNo: (json['ticket_no'] ?? json['ticketNo'] ?? '').toString(),
      taskNo: json['task_no'] != null || json['taskNo'] != null
          ? (json['task_no'] ?? json['taskNo']).toString()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_no': ticketNo,
      if (taskNo != null) 'task_no': taskNo,
    };
  }
}

class BatchTicketResponse {
  final List<CreatedTicketTaskItem> created;

  const BatchTicketResponse({
    required this.created,
  });

  factory BatchTicketResponse.fromJson(Map<String, dynamic> json) {
    final list = json['created'] as List<dynamic>? ?? [];
    return BatchTicketResponse(
      created: list
          .map((item) => CreatedTicketTaskItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'created': created.map((i) => i.toJson()).toList(),
    };
  }
}
