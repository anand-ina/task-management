class LoginResponse {
  final String token;
  final bool mustChangePassword;

  LoginResponse({
    required this.token,
    this.mustChangePassword = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'mustChangePassword': mustChangePassword,
    };
  }
}
