class ChannelItemModel {
  final String value;
  final String label;

  const ChannelItemModel({
    required this.value,
    required this.label,
  });

  factory ChannelItemModel.fromJson(Map<String, dynamic> json) {
    return ChannelItemModel(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class TicketOwnerModel {
  final int id;
  final String name;

  const TicketOwnerModel({
    required this.id,
    required this.name,
  });

  factory TicketOwnerModel.fromJson(Map<String, dynamic> json) {
    return TicketOwnerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class TicketMetaModel {
  final List<String> categories;
  final List<ChannelItemModel> channels;
  final Map<String, int> slaDays;
  final int appreciationPoints;
  final String nextTicketNo;
  final String nextTaskNo;
  final TicketOwnerModel? owner;

  const TicketMetaModel({
    this.categories = const [],
    this.channels = const [],
    this.slaDays = const {
      'emergency': 0,
      'top_most': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    },
    this.appreciationPoints = 50,
    this.nextTicketNo = '',
    this.nextTaskNo = '',
    this.owner,
  });

  int getSlaDaysForPriority(String priority) {
    final key = priority.toLowerCase().replaceAll(' ', '_');
    return slaDays[key] ?? slaDays[priority.toLowerCase()] ?? 3;
  }

  factory TicketMetaModel.fromJson(Map<String, dynamic> json) {
    List<String> categoriesList = [];
    if (json['categories'] is List) {
      categoriesList = (json['categories'] as List).map((e) => e.toString()).toList();
    }

    List<ChannelItemModel> channelsList = [];
    if (json['channels'] is List) {
      channelsList = (json['channels'] as List)
          .map((e) => ChannelItemModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }

    Map<String, int> sla = {
      'emergency': 0,
      'top_most': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
    };
    if (json['slaDays'] is Map) {
      final map = json['slaDays'] as Map;
      map.forEach((k, v) {
        if (v is int) {
          sla[k.toString()] = v;
        } else if (v != null) {
          final parsed = int.tryParse(v.toString());
          if (parsed != null) sla[k.toString()] = parsed;
        }
      });
    }

    return TicketMetaModel(
      categories: categoriesList,
      channels: channelsList,
      slaDays: sla,
      appreciationPoints: json['appreciationPoints'] is int
          ? json['appreciationPoints']
          : int.tryParse(json['appreciationPoints']?.toString() ?? '50') ?? 50,
      nextTicketNo: json['nextTicketNo']?.toString() ?? '',
      nextTaskNo: json['nextTaskNo']?.toString() ?? '',
      owner: json['owner'] is Map<String, dynamic>
          ? TicketOwnerModel.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }
}
