class ResponsibilityPersonModel {
  final int id;
  final String name;
  final String initials;
  final String avatarColor;
  final String designation;
  final String department;
  final String branchName;
  final String branchCode;
  final int level;
  final String roleLabel;

  const ResponsibilityPersonModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.designation,
    required this.department,
    required this.branchName,
    required this.branchCode,
    required this.level,
    required this.roleLabel,
  });

  factory ResponsibilityPersonModel.fromJson(Map<String, dynamic> json) {
    return ResponsibilityPersonModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      avatarColor: json['avatar_color'] as String? ?? '#132a50',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      branchName: json['branch_name'] as String? ?? '',
      branchCode: json['branch_code'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      roleLabel: json['role_label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'avatar_color': avatarColor,
        'designation': designation,
        'department': department,
        'branch_name': branchName,
        'branch_code': branchCode,
        'level': level,
        'role_label': roleLabel,
      };
}

class ResponsibilityItemModel {
  final int id;
  final String kind;
  final String text;
  final int sort;

  const ResponsibilityItemModel({
    required this.id,
    required this.kind,
    required this.text,
    required this.sort,
  });

  factory ResponsibilityItemModel.fromJson(Map<String, dynamic> json) {
    return ResponsibilityItemModel(
      id: json['id'] as int? ?? 0,
      kind: json['kind'] as String? ?? 'primary',
      text: json['text'] as String? ?? '',
      sort: json['sort'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'text': text,
        'sort': sort,
      };
}

class ResponsibilitiesResponseModel {
  final ResponsibilityPersonModel? person;
  final bool canEdit;
  final List<ResponsibilityItemModel> primary;
  final List<ResponsibilityItemModel> secondary;

  const ResponsibilitiesResponseModel({
    this.person,
    this.canEdit = true,
    this.primary = const [],
    this.secondary = const [],
  });

  factory ResponsibilitiesResponseModel.fromJson(Map<String, dynamic> json) {
    return ResponsibilitiesResponseModel(
      person: json['person'] != null
          ? ResponsibilityPersonModel.fromJson(json['person'] as Map<String, dynamic>)
          : null,
      canEdit: json['canEdit'] as bool? ?? true,
      primary: (json['primary'] as List<dynamic>?)
              ?.map((p) => ResponsibilityItemModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      secondary: (json['secondary'] as List<dynamic>?)
              ?.map((s) => ResponsibilityItemModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ResponsibilitiesResponseModel copyWith({
    ResponsibilityPersonModel? person,
    bool? canEdit,
    List<ResponsibilityItemModel>? primary,
    List<ResponsibilityItemModel>? secondary,
  }) {
    return ResponsibilitiesResponseModel(
      person: person ?? this.person,
      canEdit: canEdit ?? this.canEdit,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
    );
  }

  Map<String, dynamic> toJson() => {
        'person': person?.toJson(),
        'canEdit': canEdit,
        'primary': primary.map((p) => p.toJson()).toList(),
        'secondary': secondary.map((s) => s.toJson()).toList(),
      };
}
