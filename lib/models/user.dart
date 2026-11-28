/// User entity matching backend `/api/v1/users` responses.
///
/// Fields correspond to the backend DTO:
/// - id
/// - name
/// - email
/// - role (ADMIN | EMPLOYEE)
/// - status (ACTIVE | DISABLED)
/// - createdAt
///
/// The backend returns role and status as uppercase strings.
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.createdAt,
  });

  /// Deserialize JSON from the backend.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  /// Serialize for `POST /api/v1/users` – the backend expects only
  /// name, email, password and role fields.
  Map<String, dynamic> toCreateJson({required String password}) {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
  }
}
