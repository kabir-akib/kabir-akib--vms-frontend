/// Operational status for fleet vehicles matching Spring Boot [VehicleStatus].
enum VehicleStatus {
  active('ACTIVE', 'Active', 'Ready and active for daily fleet operations'),
  maintenance('MAINTENANCE', 'Maintenance', 'Under scheduled inspection or repair'),
  inactive('INACTIVE', 'Inactive', 'Idle, unassigned, or decommissioned');

  final String apiValue;
  final String label;
  final String description;

  const VehicleStatus(this.apiValue, this.label, this.description);

  /// Safe deserializer from backend string (e.g. "ACTIVE", "MAINTENANCE", "INACTIVE").
  static VehicleStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return VehicleStatus.active;
    final normalized = value.trim().toUpperCase();
    for (final status in VehicleStatus.values) {
      if (status.apiValue == normalized ||
          status.label.toUpperCase() == normalized ||
          status.name.toUpperCase() == normalized) {
        return status;
      }
    }
    return VehicleStatus.active;
  }
}

/// Category classification for fleet vehicles matching Spring Boot [VehicleType].
enum VehicleType {
  truck('TRUCK', 'Truck'),
  van('VAN', 'Delivery Van'),
  heavyHauler('HEAVY_HAULER', 'Heavy Hauler'),
  sedan('SEDAN', 'Sedan'),
  suv('SUV', 'SUV'),
  electric('ELECTRIC', 'Electric Utility');

  final String apiValue;
  final String label;

  const VehicleType(this.apiValue, this.label);

  /// Safe deserializer from backend string (e.g. "TRUCK", "HEAVY_HAULER", etc.).
  static VehicleType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return VehicleType.truck;
    final normalized = value.trim().toUpperCase().replaceAll(' ', '_');
    for (final type in VehicleType.values) {
      if (type.apiValue == normalized ||
          type.name.toUpperCase() == normalized ||
          type.label.toUpperCase() == normalized) {
        return type;
      }
    }
    // Handle camelCase e.g. heavyHauler
    if (normalized == 'HEAVYHAULER') return VehicleType.heavyHauler;
    return VehicleType.truck;
  }
}

/// Primary vehicle entity for the Stark Group Vehicle Management System (VMS).
///
/// Designed strictly around the backend API contract:
/// - id
/// - vehicleNumber
/// - company
/// - type
/// - brand
/// - model
/// - status
class Vehicle {
  final String id;
  final String vehicleNumber;
  final String company;
  final VehicleType type;
  final String? typeLabel;
  final String brand;
  final String model;
  final String? customDisplayName;
  final VehicleStatus status;
  final String? statusLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    this.typeLabel,
    required this.brand,
    required this.model,
    this.customDisplayName,
    required this.status,
    this.statusLabel,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns clean brand & model combination or backend displayName e.g. "Scania R500 V8"
  String get displayName =>
      customDisplayName != null && customDisplayName!.isNotEmpty
          ? customDisplayName!
          : '$brand $model';

  /// Deserializes backend VehicleResponse JSON exactly.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      type: VehicleType.fromString(json['type']?.toString()),
      typeLabel: json['typeLabel']?.toString(),
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      customDisplayName: json['displayName']?.toString(),
      status: VehicleStatus.fromString(json['status']?.toString()),
      statusLabel: json['statusLabel']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Serializes to backend [VehicleCreateRequest] payload.
  Map<String, dynamic> toCreateJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.apiValue,
      'brand': brand,
      'model': model,
      'status': status.apiValue,
    };
  }

  /// Serializes to backend [VehicleUpdateRequest] payload.
  Map<String, dynamic> toUpdateJson() {
    return {
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.apiValue,
      'brand': brand,
      'model': model,
      'status': status.apiValue,
    };
  }

  /// Immutable copyWith for state updates
  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? company,
    VehicleType? type,
    String? typeLabel,
    String? brand,
    String? model,
    String? customDisplayName,
    VehicleStatus? status,
    String? statusLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      typeLabel: typeLabel ?? this.typeLabel,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      customDisplayName: customDisplayName ?? this.customDisplayName,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
