class HourlyItemModel {
  final int id;
  final String body;

  const HourlyItemModel({
    required this.id,
    required this.body,
  });

  factory HourlyItemModel.fromJson(Map<String, dynamic> json) {
    return HourlyItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      body: json['body']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'body': body,
  };
}

class HourlySlotModel {
  final String slot;
  final bool lunch;
  final List<HourlyItemModel> items;

  const HourlySlotModel({
    required this.slot,
    this.lunch = false,
    required this.items,
  });

  HourlySlotModel copyWith({
    String? slot,
    bool? lunch,
    List<HourlyItemModel>? items,
  }) {
    return HourlySlotModel(
      slot: slot ?? this.slot,
      lunch: lunch ?? this.lunch,
      items: items ?? this.items,
    );
  }

  factory HourlySlotModel.fromJson(Map<String, dynamic> json) {
    return HourlySlotModel(
      slot: json['slot']?.toString() ?? '',
      lunch: json['lunch'] == true,
      items: json['items'] is List
          ? (json['items'] as List)
              .map((e) => HourlyItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'lunch': lunch,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class HourlyLogModel {
  final String date;
  final List<HourlySlotModel> slots;
  final String? extSlot;
  final List<HourlyItemModel> extItems;
  final String? lunch;
  final bool isSubmitted;

  const HourlyLogModel({
    required this.date,
    required this.slots,
    this.extSlot,
    this.extItems = const [],
    this.lunch,
    this.isSubmitted = false,
  });

  static const List<String> defaultStandardSlots = [
    '08:30-09:30',
    '09:30-10:30',
    '10:30-11:30',
    '11:30-12:30',
    '12:30-13:30',
    '13:30-14:30',
    '14:30-15:30',
    '15:30-16:30',
    '16:30-17:30',
    '17:30-18:30',
  ];

  factory HourlyLogModel.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] is List
        ? (json['slots'] as List)
            .map((e) => HourlySlotModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <HourlySlotModel>[];

    final lunchVal = json['lunch']?.toString();

    final slotMap = {for (var s in rawSlots) s.slot: s};
    final combinedSlots = defaultStandardSlots.map((standardSlot) {
      if (slotMap.containsKey(standardSlot)) {
        final existing = slotMap[standardSlot]!;
        final isLunch = existing.lunch || (lunchVal != null && lunchVal == standardSlot);
        return existing.copyWith(lunch: isLunch);
      }
      return HourlySlotModel(
        slot: standardSlot,
        lunch: lunchVal == standardSlot,
        items: const [],
      );
    }).toList();

    final isSub = json['isSubmitted'] == true ||
        json['submitted'] == true ||
        (json['submittedAt'] != null && json['submittedAt'].toString().isNotEmpty);

    return HourlyLogModel(
      date: json['date']?.toString() ?? '',
      slots: combinedSlots,
      extSlot: json['extSlot']?.toString(),
      extItems: json['extItems'] is List
          ? (json['extItems'] as List)
              .map((e) => HourlyItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      lunch: lunchVal,
      isSubmitted: isSub,
    );
  }

  HourlyLogModel copyWith({
    String? date,
    List<HourlySlotModel>? slots,
    String? extSlot,
    List<HourlyItemModel>? extItems,
    String? lunch,
    bool? isSubmitted,
  }) {
    return HourlyLogModel(
      date: date ?? this.date,
      slots: slots ?? this.slots,
      extSlot: extSlot ?? this.extSlot,
      extItems: extItems ?? this.extItems,
      lunch: lunch ?? this.lunch,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  int get totalSlots => slots.length;
  int get filledSlots => slots.where((s) => s.lunch || s.items.isNotEmpty).length;
}
