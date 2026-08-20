class MeetingAvailabilityModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String status;

  MeetingAvailabilityModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.status,
  });

  factory MeetingAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return MeetingAvailabilityModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#d98a04',
      status: json['status'] as String? ?? 'free',
    );
  }
}
