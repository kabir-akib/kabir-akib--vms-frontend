/// Authenticated user profile returned by Spring Boot `/api/v1/auth/login` and `/api/v1/auth/me`.
class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
      };
}

/// Authenticated session holding the server-issued opaque Bearer token and user profile.
class AuthSession {
  final String token;
  final String tokenType;
  final DateTime? expiresAt;
  final AuthUser user;

  const AuthSession({
    required this.token,
    required this.tokenType,
    this.expiresAt,
    required this.user,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!.toUtc());

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};
    return AuthSession(
      token: json['token']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      user: AuthUser.fromJson(userJson),
    );
  }
}
