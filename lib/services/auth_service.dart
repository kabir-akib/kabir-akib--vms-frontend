import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/auth_session.dart';
import 'api_client.dart';

/// Abstraction over secure token persistence so tests can swap in-memory storage.
abstract class SecureTokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

class FlutterSecureTokenStorage implements SecureTokenStorage {
  static const String _tokenKey = 'vms_auth_token';
  final FlutterSecureStorage _storage;

  const FlutterSecureTokenStorage([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  ]);

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

/// Coordinates authentication state, secure token storage, and session lifecycle.
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  AuthSession? _session;
  bool _isRestoring = false;

  AuthService._internal({
    ApiClient? apiClient,
    SecureTokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const FlutterSecureTokenStorage() {
    ApiClient.setUnauthorizedHandler(handleUnauthorized);
  }

  /// Creates an isolated instance for unit and widget tests.
  @visibleForTesting
  AuthService.forTest({
    required ApiClient apiClient,
    required SecureTokenStorage tokenStorage,
  }) : this._internal(apiClient: apiClient, tokenStorage: tokenStorage);

  AuthSession? get session => _session;
  AuthUser? get currentUser => _session?.user;
  bool get isAuthenticated =>
      _session != null && _session!.token.isNotEmpty && !_session!.isExpired;
  bool get isRestoring => _isRestoring;

  /// Restores a previously remembered session token and validates it with `/api/v1/auth/me`.
  Future<bool> restoreSession() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final storedToken = await _tokenStorage.readToken();
      if (storedToken == null || storedToken.isEmpty) {
        _clearLocalSession();
        return false;
      }

      _apiClient.setAuthToken(storedToken);
      final data = await _apiClient.get(AppConfig.meEndpoint);
      if (data is Map<String, dynamic>) {
        final user = AuthUser.fromJson(data);
        _session = AuthSession(
          token: storedToken,
          tokenType: 'Bearer',
          user: user,
        );
        return true;
      }

      await _clearSessionAndStorage();
      return false;
    } catch (_) {
      await _clearSessionAndStorage();
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Authenticates against `POST /api/v1/auth/login` and stores the issued Bearer token.
  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final data = await _apiClient.post(
      AppConfig.loginEndpoint,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected authentication response from server.');
    }

    final session = AuthSession.fromJson(data);
    if (session.token.isEmpty) {
      throw StateError('Authentication response did not include an access token.');
    }

    _session = session;
    _apiClient.setAuthToken(session.token);

    if (rememberMe) {
      await _tokenStorage.writeToken(session.token);
    } else {
      await _tokenStorage.deleteToken();
    }

    notifyListeners();
    return session;
  }

  /// Revokes the active server token and clears local session state.
  Future<void> logout() async {
    try {
      if (_apiClient.authToken != null && _apiClient.authToken!.isNotEmpty) {
        await _apiClient.post(AppConfig.logoutEndpoint);
      }
    } catch (_) {
      // Always clear local session even if server revocation fails or token already expired.
    } finally {
      await _clearSessionAndStorage();
      notifyListeners();
    }
  }

  /// Clears local session state when a protected endpoint responds with HTTP 401.
  void handleUnauthorized() {
    if (_session == null && _apiClient.authToken == null) {
      return;
    }
    _clearLocalSession();
    _tokenStorage.deleteToken();
    notifyListeners();
  }

  void _clearLocalSession() {
    _session = null;
    _apiClient.setAuthToken(null);
  }

  Future<void> _clearSessionAndStorage() async {
    _clearLocalSession();
    await _tokenStorage.deleteToken();
  }
}
