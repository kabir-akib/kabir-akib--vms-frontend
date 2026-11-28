import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Service handling Admin‑only user management endpoints.
/// Provides methods to list all users and create a new user.
class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;

  final ApiClient _client;

  UserService._internal({ApiClient? client}) : _client = client ?? ApiClient();

  @visibleForTesting
  UserService.forTest({required ApiClient client}) : this._internal(client: client);

  List<User> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Loads all users via `GET /api/v1/users`.
  Future<void> loadUsers({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    try {
      final data = await _client.get(AppConfig.usersEndpoint);
      if (data is List) {
        _users = data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Unexpected response format.';
      }
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
    } catch (e) {
      _errorMessage = 'Failed to load users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new user via `POST /api/v1/users`.
  /// Returns the created [User] on success.
  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final payload = User(
      id: '',
      name: name,
      email: email,
      role: role,
      status: 'ACTIVE',
    ).toCreateJson(password: password);

    final data = await _client.post(AppConfig.usersEndpoint, body: payload);
    final created = User.fromJson(data as Map<String, dynamic>);
    // Refresh list after creation.
    await loadUsers(showLoading: false);
    return created;
  }

  void clearSessionData() {
    _users = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
