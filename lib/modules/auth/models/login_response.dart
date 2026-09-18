class LoginResponse {
  final String token;
  final bool mustChangePassword;
  final Map<String, dynamic>? user;
  final String? role;
  final String? roleLabel;

  LoginResponse({
    required this.token,
    this.mustChangePassword = false,
    this.user,
    this.role,
    this.roleLabel,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? userMap;
    if (json['user'] is Map<String, dynamic>) {
      userMap = json['user'] as Map<String, dynamic>;
    } else if (json['data'] is Map<String, dynamic> && json['data']['user'] is Map<String, dynamic>) {
      userMap = json['data']['user'] as Map<String, dynamic>;
    }

    String? resolvedRole;
    String? resolvedRoleLabel;
    if (userMap != null) {
      resolvedRole = userMap['role']?.toString() ?? userMap['user_role']?.toString();
      resolvedRoleLabel = userMap['roleLabel']?.toString() ??
          userMap['role_label']?.toString() ??
          userMap['designation']?.toString();
    } else {
      resolvedRole = json['role']?.toString() ?? json['user_role']?.toString();
      resolvedRoleLabel = json['roleLabel']?.toString() ??
          json['role_label']?.toString() ??
          json['designation']?.toString();
    }

    return LoginResponse(
      token: json['token'] as String? ?? json['accessToken'] as String? ?? json['jwt'] as String? ?? '',
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      user: userMap,
      role: resolvedRole,
      roleLabel: resolvedRoleLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'mustChangePassword': mustChangePassword,
      'user': user,
      'role': role,
      'roleLabel': roleLabel,
    };
  }
}
