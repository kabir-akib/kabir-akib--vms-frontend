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

  /// Authentication endpoints
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  static const String meEndpoint = '/api/v1/auth/me';

  /// User management endpoints
  static const String usersEndpoint = '/api/v1/users';

  /// Dashboard endpoints
  static const String dashboardSummaryEndpoint = '/api/v1/dashboard/summary';

  /// Vehicle endpoints
  static const String vehiclesEndpoint = '/api/v1/vehicles';
  static const String metricsEndpoint = '/api/v1/vehicles/metrics';
  static const String companiesEndpoint = '/api/v1/vehicles/companies';

  /// Driver & Assignment endpoints
  static const String driversEndpoint = '/api/v1/drivers';
  static const String assignmentsEndpoint = '/api/v1/assignments';

  /// Document endpoints
  static const String documentsEndpoint = '/api/v1/documents';

  /// Sub-resource paths
  static String vehicleDocuments(String vehicleId) =>
      '$vehiclesEndpoint/$vehicleId/documents';
  static String vehicleMaintenance(String vehicleId) =>
      '$vehiclesEndpoint/$vehicleId/maintenance';
  static String vehicleAssignments(String vehicleId) =>
      '$vehiclesEndpoint/$vehicleId/assignments';
  static String vehicleStatus(String vehicleId) =>
      '$vehiclesEndpoint/$vehicleId/status';
  static String driverAssignments(String driverId) =>
      '$driversEndpoint/$driverId/assignments';

  // Aliases used by services
  static String vehicleDocumentsUrl(String vehicleId) =>
      vehicleDocuments(vehicleId);
  static String vehicleMaintenanceUrl(String vehicleId) =>
      vehicleMaintenance(vehicleId);
  static String vehicleAssignmentsUrl(String vehicleId) =>
      vehicleAssignments(vehicleId);

  /// Default timeout for HTTP requests.
  static const Duration requestTimeout = Duration(seconds: 15);
}
