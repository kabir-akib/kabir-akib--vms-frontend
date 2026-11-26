/// Fleet operational metrics matching backend [FleetMetricsResponse].
class FleetMetrics {
  final int totalVehicles;
  final int activeVehicles;
  final int maintenanceVehicles;
  final int inactiveVehicles;

  const FleetMetrics({
    this.totalVehicles = 0,
    this.activeVehicles = 0,
    this.maintenanceVehicles = 0,
    this.inactiveVehicles = 0,
  });

  factory FleetMetrics.fromJson(Map<String, dynamic> json) {
    return FleetMetrics(
      totalVehicles: (json['totalVehicles'] as num?)?.toInt() ?? 0,
      activeVehicles: (json['activeVehicles'] as num?)?.toInt() ?? 0,
      maintenanceVehicles: (json['maintenanceVehicles'] as num?)?.toInt() ?? 0,
      inactiveVehicles: (json['inactiveVehicles'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalVehicles': totalVehicles,
      'activeVehicles': activeVehicles,
      'maintenanceVehicles': maintenanceVehicles,
      'inactiveVehicles': inactiveVehicles,
    };
  }

  /// Calculates metrics from a local list of vehicles as a fallback.
  factory FleetMetrics.fromVehicles(List<dynamic> vehicles) {
    int total = vehicles.length;
    int active = 0;
    int maintenance = 0;
    int inactive = 0;

    for (final v in vehicles) {
      final status = v.status.toString().toUpperCase();
      if (status.contains('ACTIVE')) {
        active++;
      } else if (status.contains('MAINTENANCE')) {
        maintenance++;
      } else if (status.contains('INACTIVE')) {
        inactive++;
      }
    }

    return FleetMetrics(
      totalVehicles: total,
      activeVehicles: active,
      maintenanceVehicles: maintenance,
      inactiveVehicles: inactive,
    );
  }
}

