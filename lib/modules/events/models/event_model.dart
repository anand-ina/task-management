class EventModel {
  final int id;
  final String title;
  final String eventDate;
  final String? description;
  final String? departments;
  final String? department;
  final String? branchName;
  final String? owner;
  final int? ownerUserId;
  final String reviewStatus;
  final int total;
  final int done;
  final bool isMine;
  final bool isOwner;
  final bool iDelegated;

  EventModel({
    required this.id,
    required this.title,
    required this.eventDate,
    this.description,
    this.departments,
    this.department,
    this.branchName,
    this.owner,
    this.ownerUserId,
    required this.reviewStatus,
    required this.total,
    required this.done,
    required this.isMine,
    required this.isOwner,
    required this.iDelegated,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      description: json['description'] as String?,
      departments: json['departments'] as String?,
      department: json['department'] as String?,
      branchName: json['branch_name'] as String?,
      owner: json['owner'] as String?,
      ownerUserId: json['owner_user_id'] as int?,
      reviewStatus: json['review_status'] as String? ?? 'draft',
      total: json['total'] as int? ?? 0,
      done: json['done'] as int? ?? 0,
      isMine: json['is_mine'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
      iDelegated: json['i_delegated'] as bool? ?? false,
    );
  }
}
