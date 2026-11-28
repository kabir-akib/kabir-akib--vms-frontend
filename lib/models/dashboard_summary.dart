/// High-level executive fleet dashboard metrics matching Spring Boot [DashboardSummaryResponse].
class DashboardSummary {
  final VehicleSummary vehicles;
  final DocumentSummary documents;
  final MaintenanceSummary maintenance;
  final DriverSummary drivers;

  const DashboardSummary({
    this.vehicles = const VehicleSummary(),
    this.documents = const DocumentSummary(),
    this.maintenance = const MaintenanceSummary(),
    this.drivers = const DriverSummary(),
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      vehicles: json['vehicles'] is Map<String, dynamic>
          ? VehicleSummary.fromJson(json['vehicles'] as Map<String, dynamic>)
          : const VehicleSummary(),
      documents: json['documents'] is Map<String, dynamic>
          ? DocumentSummary.fromJson(json['documents'] as Map<String, dynamic>)
          : const DocumentSummary(),
      maintenance: json['maintenance'] is Map<String, dynamic>
          ? MaintenanceSummary.fromJson(json['maintenance'] as Map<String, dynamic>)
          : const MaintenanceSummary(),
      drivers: json['drivers'] is Map<String, dynamic>
          ? DriverSummary.fromJson(json['drivers'] as Map<String, dynamic>)
          : const DriverSummary(),
    );
  }
}

class VehicleSummary {
  final int totalVehicles;
  final int activeVehicles;
  final int inactiveVehicles;
  final int maintenanceVehicles;

  const VehicleSummary({
    this.totalVehicles = 0,
    this.activeVehicles = 0,
    this.inactiveVehicles = 0,
    this.maintenanceVehicles = 0,
  });

  factory VehicleSummary.fromJson(Map<String, dynamic> json) {
    return VehicleSummary(
      totalVehicles: (json['totalVehicles'] as num?)?.toInt() ?? 0,
      activeVehicles: (json['activeVehicles'] as num?)?.toInt() ?? 0,
      inactiveVehicles: (json['inactiveVehicles'] as num?)?.toInt() ?? 0,
      maintenanceVehicles: (json['maintenanceVehicles'] as num?)?.toInt() ?? 0,
    );
  }
}

class DocumentSummary {
  final int totalDocuments;
  final int expiredDocuments;
  final int expiringSoonDocuments;

  const DocumentSummary({
    this.totalDocuments = 0,
    this.expiredDocuments = 0,
    this.expiringSoonDocuments = 0,
  });

  factory DocumentSummary.fromJson(Map<String, dynamic> json) {
    return DocumentSummary(
      totalDocuments: (json['totalDocuments'] as num?)?.toInt() ?? 0,
      expiredDocuments: (json['expiredDocuments'] as num?)?.toInt() ?? 0,
      expiringSoonDocuments: (json['expiringSoonDocuments'] as num?)?.toInt() ?? 0,
    );
  }
}

class MaintenanceSummary {
  final int totalRecords;
  final double totalCost;
  final int recentRecordsLast30Days;

  const MaintenanceSummary({
    this.totalRecords = 0,
    this.totalCost = 0.0,
    this.recentRecordsLast30Days = 0,
  });

  factory MaintenanceSummary.fromJson(Map<String, dynamic> json) {
    return MaintenanceSummary(
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      recentRecordsLast30Days:
          (json['recentRecordsLast30Days'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverSummary {
  final int totalDrivers;
  final int activeDrivers;
  final int inactiveDrivers;

  const DriverSummary({
    this.totalDrivers = 0,
    this.activeDrivers = 0,
    this.inactiveDrivers = 0,
  });

  factory DriverSummary.fromJson(Map<String, dynamic> json) {
    return DriverSummary(
      totalDrivers: (json['totalDrivers'] as num?)?.toInt() ?? 0,
      activeDrivers: (json['activeDrivers'] as num?)?.toInt() ?? 0,
      inactiveDrivers: (json['inactiveDrivers'] as num?)?.toInt() ?? 0,
    );
  }
}
