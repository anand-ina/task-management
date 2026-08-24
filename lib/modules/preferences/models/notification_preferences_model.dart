class ChannelPreference {
  bool inapp;
  bool email;
  bool sms;
  bool whatsapp;
  bool push;

  ChannelPreference({
    required this.inapp,
    required this.email,
    required this.sms,
    required this.whatsapp,
    required this.push,
  });

  factory ChannelPreference.fromJson(Map<String, dynamic> json) {
    return ChannelPreference(
      inapp: json['inapp'] == true,
      email: json['email'] == true,
      sms: json['sms'] == true,
      whatsapp: json['whatsapp'] == true,
      push: json['push'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'inapp': inapp,
        'email': email,
        'sms': sms,
        'whatsapp': whatsapp,
        'push': push,
      };
}

class NotificationPreferencesModel {
  final Map<String, ChannelPreference> channels;
  bool dailyDigest;

  NotificationPreferencesModel({
    required this.channels,
    required this.dailyDigest,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    final Map<String, ChannelPreference> chMap = {};
    if (json['channels'] is Map<String, dynamic>) {
      (json['channels'] as Map<String, dynamic>).forEach((key, val) {
        if (val is Map<String, dynamic>) {
          chMap[key] = ChannelPreference.fromJson(val);
        }
      });
    }

    return NotificationPreferencesModel(
      channels: chMap,
      dailyDigest: json['dailyDigest'] == true || json['daily_digest'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> chJson = {};
    channels.forEach((key, val) {
      chJson[key] = val.toJson();
    });
    return {
      'channels': chJson,
      'dailyDigest': dailyDigest,
    };
  }
}
