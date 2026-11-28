import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/vehicle_maintenance.dart';
import 'api_client.dart';

/// Service coordinating vehicle maintenance service logs and costs.
class MaintenanceService extends ChangeNotifier {
  static final MaintenanceService _instance = MaintenanceService._internal();
  factory MaintenanceService() => _instance;

  final ApiClient _client;

  MaintenanceService._internal({ApiClient? client})
      : _client = client ?? ApiClient();

  @visibleForTesting
  MaintenanceService.forTest({required ApiClient client})
      : this._internal(client: client);

  /// Fetches maintenance history for a vehicle: `GET /api/v1/vehicles/{vehicleId}/maintenance`
  Future<List<VehicleMaintenance>> getMaintenanceHistory(String vehicleId) async {
    final data = await _client.get(AppConfig.vehicleMaintenanceUrl(vehicleId));
    if (data is List) {
      return data
          .map((e) => VehicleMaintenance.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Creates a maintenance record: `POST /api/v1/vehicles/{vehicleId}/maintenance`
  Future<VehicleMaintenance> createMaintenance(
    String vehicleId,
    VehicleMaintenance maintenance,
  ) async {
    final data = await _client.post(
      AppConfig.vehicleMaintenanceUrl(vehicleId),
      body: maintenance.toJson(),
    );
    return VehicleMaintenance.fromJson(data as Map<String, dynamic>);
  }

  /// Updates a maintenance record: `PUT /api/v1/vehicles/{vehicleId}/maintenance/{id}`
  Future<VehicleMaintenance> updateMaintenance(
    String vehicleId,
    String maintenanceId,
    VehicleMaintenance maintenance,
  ) async {
    final data = await _client.put(
      '${AppConfig.vehicleMaintenanceUrl(vehicleId)}/$maintenanceId',
      body: maintenance.toJson(),
    );
    return VehicleMaintenance.fromJson(data as Map<String, dynamic>);
  }

  /// Deletes a maintenance record: `DELETE /api/v1/vehicles/{vehicleId}/maintenance/{id}`
  Future<void> deleteMaintenance(String vehicleId, String maintenanceId) async {
    await _client.delete('${AppConfig.vehicleMaintenanceUrl(vehicleId)}/$maintenanceId');
  }
}
