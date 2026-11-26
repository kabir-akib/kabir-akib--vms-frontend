import 'package:flutter/foundation.dart';
import '../models/fleet_metrics.dart';
import '../models/vehicle.dart';
import 'api_exception.dart';
import 'vehicle_api_service.dart';

/// Central Vehicle state coordinator for the Stark Group VMS frontend.
///
/// Connects UI widgets to the Spring Boot REST API layer, maintaining:
/// - Loading state ([isLoading])
/// - Error state ([errorMessage])
/// - Empty state ([isEmpty])
/// - Success state ([isSuccess])
/// - Cached vehicles, metrics, and registered company lists.
class VehicleService extends ChangeNotifier {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;

  final VehicleApiService _apiService;

  VehicleService._internal({VehicleApiService? apiService})
      : _apiService = apiService ?? VehicleApiService();

  @visibleForTesting
  VehicleService.forTest({required VehicleApiService apiService})
      : this._internal(apiService: apiService);

  // Internal state
  List<Vehicle> _vehicles = [];
  FleetMetrics _metrics = const FleetMetrics();
  List<String> _companies = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Active filter state
  String _activeQuery = '';
  VehicleStatus? _activeStatus;
  String? _activeCompany;

  // Getters
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  FleetMetrics get metrics => _metrics;
  List<String> get availableCompanies => List.unmodifiable(_companies);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && !hasError && _vehicles.isEmpty;
  bool get isSuccess => !_isLoading && !hasError;

  int get totalVehicles => _metrics.totalVehicles;
  int get activeVehicles => _metrics.activeVehicles;
  int get maintenanceVehicles => _metrics.maintenanceVehicles;
  int get inactiveVehicles => _metrics.inactiveVehicles;

  String get activeQuery => _activeQuery;
  VehicleStatus? get activeStatus => _activeStatus;
  String? get activeCompany => _activeCompany;

  /// Loads vehicles and operational metrics from the Spring Boot REST API.
  Future<void> loadVehicles({
    String? query,
    VehicleStatus? status,
    String? company,
    bool showLoading = true,
  }) async {
    _activeQuery = query ?? _activeQuery;
    _activeStatus = status;
    _activeCompany = company;

    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Fetch vehicles, metrics, and company list concurrently from backend
      final results = await Future.wait([
        _apiService.getVehicles(
          query: _activeQuery,
          status: _activeStatus,
          company: _activeCompany,
        ),
        _apiService.getFleetMetrics().catchError(
          (_) => FleetMetrics.fromVehicles(_vehicles),
        ),
        _apiService.getAvailableCompanies().catchError((_) => <String>[]),
      ]);

      _vehicles = results[0] as List<Vehicle>;
      _metrics = results[1] as FleetMetrics;

      final fetchedCompanies = results[2] as List<String>;
      if (fetchedCompanies.isNotEmpty) {
        _companies = fetchedCompanies;
      } else {
        // Fallback from loaded vehicles
        _companies = _vehicles.map((v) => v.company).toSet().toList()..sort();
      }

      // If metrics returned all 0s but vehicles exist, calculate locally
      if (_metrics.totalVehicles == 0 && _vehicles.isNotEmpty) {
        _metrics = FleetMetrics.fromVehicles(_vehicles);
      }

      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registers a new vehicle through Spring Boot `POST /api/v1/vehicles`.
  Future<Vehicle> registerVehicle(Vehicle vehicle) async {
    final created = await _apiService.createVehicle(vehicle);
    await loadVehicles(showLoading: false);
    return created;
  }

  /// Updates an existing vehicle through Spring Boot `PUT /api/v1/vehicles/{id}`.
  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    final updated = await _apiService.updateVehicle(id, vehicle);
    await loadVehicles(showLoading: false);
    return updated;
  }

  /// Deletes a vehicle by ID through Spring Boot `DELETE /api/v1/vehicles/{id}`.
  ///
  /// Only removes the vehicle from local state after backend deletion succeeds.
  Future<void> deleteVehicle(String id) async {
    await _apiService.deleteVehicle(id);
    _vehicles.removeWhere((v) => v.id == id);
    _metrics = FleetMetrics.fromVehicles(_vehicles);
    notifyListeners();
    await loadVehicles(showLoading: false);
  }

  /// Clears active error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears cached vehicle, metrics, and filter state on sign-out.
  void clearSessionData() {
    _vehicles = [];
    _metrics = const FleetMetrics();
    _companies = [];
    _isLoading = false;
    _errorMessage = null;
    _activeQuery = '';
    _activeStatus = null;
    _activeCompany = null;
    notifyListeners();
  }
}

