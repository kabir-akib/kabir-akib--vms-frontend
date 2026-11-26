import '../config/app_config.dart';
import '../models/fleet_metrics.dart';
import '../models/vehicle.dart';
import 'api_client.dart';

/// Data service communicating with Spring Boot `/api/v1/vehicles` endpoints.
///
/// Encapsulates all REST calls so UI screens and widgets remain clean
/// and completely decoupled from network logic.
class VehicleApiService {
  final ApiClient _client;

  VehicleApiService({ApiClient? client})
      : _client = client ?? ApiClient();

  /// Fetches vehicles from Spring Boot: `GET /api/v1/vehicles`
  ///
  /// Supports query parameters:
  /// - `query`: case-insensitive match on number, company, brand, model
  /// - `status`: `ACTIVE`, `MAINTENANCE`, `INACTIVE`
  /// - `company`: operating company filter
  Future<List<Vehicle>> getVehicles({
    String? query,
    VehicleStatus? status,
    String? company,
  }) async {
    final queryParams = <String, dynamic>{
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
      if (status != null) 'status': status.apiValue,
      if (company != null && company.trim().isNotEmpty) 'company': company.trim(),
    };

    final data = await _client.get(
      AppConfig.vehiclesEndpoint,
      queryParameters: queryParams,
    );

    if (data is List) {
      return data
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches a single vehicle by ID: `GET /api/v1/vehicles/{id}`
  Future<Vehicle> getVehicleById(String id) async {
    final data = await _client.get('${AppConfig.vehiclesEndpoint}/$id');
    return Vehicle.fromJson(data as Map<String, dynamic>);
  }

  /// Registers a new vehicle in Spring Boot: `POST /api/v1/vehicles`
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final data = await _client.post(
      AppConfig.vehiclesEndpoint,
      body: vehicle.toCreateJson(),
    );
    return Vehicle.fromJson(data as Map<String, dynamic>);
  }

  /// Updates an existing vehicle: `PUT /api/v1/vehicles/{id}`
  Future<Vehicle> updateVehicle(String id, Vehicle vehicle) async {
    final data = await _client.put(
      '${AppConfig.vehiclesEndpoint}/$id',
      body: vehicle.toUpdateJson(),
    );
    return Vehicle.fromJson(data as Map<String, dynamic>);
  }

  /// Removes a vehicle by ID: `DELETE /api/v1/vehicles/{id}`
  Future<void> deleteVehicle(String id) async {
    await _client.delete('${AppConfig.vehiclesEndpoint}/$id');
  }

  /// Fetches operational fleet KPI metrics: `GET /api/v1/vehicles/metrics`
  Future<FleetMetrics> getFleetMetrics() async {
    final data = await _client.get(AppConfig.metricsEndpoint);
    if (data is Map<String, dynamic>) {
      return FleetMetrics.fromJson(data);
    }
    return const FleetMetrics();
  }

  /// Fetches distinct registered companies: `GET /api/v1/vehicles/companies`
  Future<List<String>> getAvailableCompanies() async {
    final data = await _client.get(AppConfig.companiesEndpoint);
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }
}

