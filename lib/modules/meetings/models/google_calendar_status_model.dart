class GoogleCalendarStatusModel {
  final bool enabled;
  final bool connected;
  final String? googleAccountEmail;
  final String? calendarId;
  final String? status;
  final String? lastSyncedAt;
  final bool systemConnected;
  final String? systemAccountEmail;

  const GoogleCalendarStatusModel({
    this.enabled = false,
    this.connected = false,
    this.googleAccountEmail,
    this.calendarId,
    this.status,
    this.lastSyncedAt,
    this.systemConnected = false,
    this.systemAccountEmail,
  });

  factory GoogleCalendarStatusModel.fromJson(Map<String, dynamic> json) {
    return GoogleCalendarStatusModel(
      enabled: json['enabled'] == true,
      connected: json['connected'] == true,
      googleAccountEmail: json['googleAccountEmail']?.toString(),
      calendarId: json['calendarId']?.toString(),
      status: json['status']?.toString(),
      lastSyncedAt: json['lastSyncedAt']?.toString(),
      systemConnected: json['systemConnected'] == true,
      systemAccountEmail: json['systemAccountEmail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'connected': connected,
      'googleAccountEmail': googleAccountEmail,
      'calendarId': calendarId,
      'status': status,
      'lastSyncedAt': lastSyncedAt,
      'systemConnected': systemConnected,
      'systemAccountEmail': systemAccountEmail,
    };
  }
}
