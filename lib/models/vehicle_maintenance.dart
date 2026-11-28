/// Categories of vehicle maintenance matching Spring Boot [MaintenanceType].
enum MaintenanceType {
  routineService('ROUTINE_SERVICE', 'Routine Service'),
  repair('REPAIR', 'Repair'),
  inspection('INSPECTION', 'Inspection'),
  oilChange('OIL_CHANGE', 'Oil Change'),
  other('OTHER', 'Other');

  final String apiValue;
  final String label;

  const MaintenanceType(this.apiValue, this.label);

  static MaintenanceType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return MaintenanceType.routineService;
    final normalized = value.trim().toUpperCase();
    for (final t in MaintenanceType.values) {
      if (t.apiValue == normalized || t.name.toUpperCase() == normalized || t.label.toUpperCase() == normalized) {
        return t;
      }
    }
    return MaintenanceType.routineService;
  }
}

/// Represents a vehicle maintenance service entry matching Spring Boot [VehicleMaintenanceResponse].
class VehicleMaintenance {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final String vehicleDisplayName;
  final DateTime maintenanceDate;
  final MaintenanceType maintenanceType;
  final String? maintenanceTypeLabel;
  final double cost;
  final String vendorName;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VehicleMaintenance({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.vehicleDisplayName,
    required this.maintenanceDate,
    required this.maintenanceType,
    this.maintenanceTypeLabel,
    required this.cost,
    required this.vendorName,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleMaintenance.fromJson(Map<String, dynamic> json) {
    return VehicleMaintenance(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      vehicleDisplayName: json['vehicleDisplayName']?.toString() ?? '',
      maintenanceDate: json['maintenanceDate'] != null
          ? DateTime.parse(json['maintenanceDate'].toString())
          : DateTime.now(),
      maintenanceType: MaintenanceType.fromString(json['maintenanceType']?.toString()),
      maintenanceTypeLabel: json['maintenanceTypeLabel']?.toString(),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      vendorName: json['vendorName']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenanceDate': maintenanceDate.toIso8601String().split('T').first,
      'maintenanceType': maintenanceType.apiValue,
      'cost': cost,
      'vendorName': vendorName,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
