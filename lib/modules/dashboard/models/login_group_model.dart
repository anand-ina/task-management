class LoginGroupMember {
  final String name;
  final String initials;
  final String color;

  LoginGroupMember({
    required this.name,
    required this.initials,
    required this.color,
  });

  factory LoginGroupMember.fromJson(Map<String, dynamic> json) {
    return LoginGroupMember(
      name: json['name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      color: json['color'] as String? ?? '#1f9d57',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'initials': initials,
        'color': color,
      };
}

class LoginGroupItem {
  final String key;
  final String label;
  final String color;
  final List<LoginGroupMember> members;

  LoginGroupItem({
    required this.key,
    required this.label,
    required this.color,
    required this.members,
  });

  factory LoginGroupItem.fromJson(Map<String, dynamic> json) {
    return LoginGroupItem(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '#8a93a8',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => LoginGroupMember.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'color': color,
        'members': members.map((e) => e.toJson()).toList(),
      };
}
