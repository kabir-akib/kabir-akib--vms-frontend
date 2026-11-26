/// Application configuration for environment and backend connectivity.
class AppConfig {
  /// Base URL for the Spring Boot VMS Backend API.
  ///
  /// Can be configured at build-time using `--dart-define`:
  /// ```bash
  /// flutter build web --dart-define=API_BASE_URL=https://api.vms.starkgroup.com
  /// ```
  /// Defaults to `http://localhost:8080` for local development.
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// API endpoints matching Spring Boot backend exactly.
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  static const String meEndpoint = '/api/v1/auth/me';
  static const String vehiclesEndpoint = '/api/v1/vehicles';
  static const String metricsEndpoint = '/api/v1/vehicles/metrics';
  static const String companiesEndpoint = '/api/v1/vehicles/companies';

  /// Default timeout for HTTP requests.
  static const Duration requestTimeout = Duration(seconds: 12);
}

