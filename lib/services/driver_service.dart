import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/driver.dart';
import '../models/driver_assignment.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Service coordinating Driver operations and Vehicle-Driver Assignments.
class DriverService extends ChangeNotifier {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;

  final ApiClient _client;

  DriverService._internal({ApiClient? client})
      : _client = client ?? ApiClient();

  @visibleForTesting
  DriverService.forTest({required ApiClient client})
      : this._internal(client: client);

  List<Driver> _drivers = [];
  List<DriverAssignment> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Driver> get drivers => List.unmodifiable(_drivers);
  List<DriverAssignment> get assignments => List.unmodifiable(_assignments);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  int get totalDrivers => _drivers.length;
  int get activeDrivers => _drivers.where((d) => d.status == DriverStatus.active).length;
  int get activeAssignments => _assignments.where((a) => a.isActive).length;

  /// Loads all drivers and assignments.
  Future<void> loadDrivers({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _client.get(AppConfig.driversEndpoint),
        _client.get(AppConfig.assignmentsEndpoint),
      ]);

      if (results[0] is List) {
        _drivers = (results[0] as List)
            .map((e) => Driver.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (results[1] is List) {
        _assignments = (results[1] as List)
            .map((e) => DriverAssignment.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
    } catch (e) {
      _errorMessage = 'Failed to load drivers: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new driver: `POST /api/v1/drivers`
  Future<Driver> createDriver(Driver driver) async {
    final data = await _client.post(
      AppConfig.driversEndpoint,
      body: driver.toJson(),
    );
    final created = Driver.fromJson(data as Map<String, dynamic>);
    await loadDrivers(showLoading: false);
    return created;
  }

  /// Updates an existing driver: `PUT /api/v1/drivers/{id}`
  Future<Driver> updateDriver(String id, Driver driver) async {
    final data = await _client.put(
      '${AppConfig.driversEndpoint}/$id',
      body: driver.toJson(),
    );
    final updated = Driver.fromJson(data as Map<String, dynamic>);
    await loadDrivers(showLoading: false);
    return updated;
  }

  /// Deletes a driver: `DELETE /api/v1/drivers/{id}`
  Future<void> deleteDriver(String id) async {
    await _client.delete('${AppConfig.driversEndpoint}/$id');
    _drivers.removeWhere((d) => d.id == id);
    notifyListeners();
    await loadDrivers(showLoading: false);
  }

  /// Assigns a driver to a vehicle: `POST /api/v1/assignments`
  Future<DriverAssignment> assignDriver({
    required String driverId,
    required String vehicleId,
    required DateTime assignedDate,
  }) async {
    final data = await _client.post(
      AppConfig.assignmentsEndpoint,
      body: {
        'driverId': driverId,
        'vehicleId': vehicleId,
        'assignedDate': assignedDate.toIso8601String().substring(0, 10),
      },
    );
    final created = DriverAssignment.fromJson(data as Map<String, dynamic>);
    await loadDrivers(showLoading: false);
    return created;
  }

  /// Ends an active assignment: `PATCH /api/v1/assignments/{id}/end`
  Future<DriverAssignment> endAssignment(String assignmentId) async {
    final data = await _client.patch(
      '${AppConfig.assignmentsEndpoint}/$assignmentId/end',
    );
    final ended = DriverAssignment.fromJson(data as Map<String, dynamic>);
    await loadDrivers(showLoading: false);
    return ended;
  }

  /// Gets assignments for a specific vehicle.
  Future<List<DriverAssignment>> getVehicleAssignments(String vehicleId) async {
    final data = await _client.get(AppConfig.vehicleAssignmentsUrl(vehicleId));
    if (data is List) {
      return data
          .map((e) => DriverAssignment.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  void clearSessionData() {
    _drivers = [];
    _assignments = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
