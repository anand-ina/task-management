class ReportingPersonModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final List<int> primary;
  final List<int> secondary;
  final int level;

  const ReportingPersonModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.primary,
    required this.secondary,
    required this.level,
  });

  factory ReportingPersonModel.fromJson(Map<String, dynamic> json) {
    return ReportingPersonModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#132A50',
      primary: (json['primary'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      secondary: (json['secondary'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      level: json['level'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'avatar_color': avatarColor,
        'primary': primary,
        'secondary': secondary,
        'level': level,
      };

  ReportingPersonModel copyWith({
    int? id,
    String? name,
    String? initials,
    String? avatarColor,
    List<int>? primary,
    List<int>? secondary,
    int? level,
  }) {
    return ReportingPersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      avatarColor: avatarColor ?? this.avatarColor,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      level: level ?? this.level,
    );
  }

  String get levelLabel {
    switch (level) {
      case 1: return 'Director';
      case 2: return 'Center Head';
      case 3: return 'Manager';
      case 4: return 'Team Lead';
      case 5: return 'Executive';
      default: return 'L$level';
    }
  }
}
