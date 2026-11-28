/// Status for vehicle-driver assignments matching Spring Boot [AssignmentStatus].
enum AssignmentStatus {
  active('ACTIVE', 'Active'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  final String apiValue;
  final String label;

  const AssignmentStatus(this.apiValue, this.label);

  static AssignmentStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return AssignmentStatus.active;
    final normalized = value.trim().toUpperCase();
    for (final s in AssignmentStatus.values) {
      if (s.apiValue == normalized || s.name.toUpperCase() == normalized) {
        return s;
      }
    }
    return AssignmentStatus.active;
  }
}

/// Driver-Vehicle Assignment entity matching Spring Boot [AssignmentResponse].
class DriverAssignment {
  final String id;
  final String driverId;
  final String driverName;
  final String? drivingLicenceNumber;
  final String vehicleId;
  final String vehicleNumber;
  final String? vehicleDisplayName;
  final DateTime? assignedDate;
  final DateTime? endDate;
  final AssignmentStatus status;
  final String statusLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverAssignment({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.drivingLicenceNumber,
    required this.vehicleId,
    required this.vehicleNumber,
    this.vehicleDisplayName,
    this.assignedDate,
    this.endDate,
    required this.status,
    required this.statusLabel,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == AssignmentStatus.active;

  factory DriverAssignment.fromJson(Map<String, dynamic> json) {
    return DriverAssignment(
      id: json['id']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? '',
      drivingLicenceNumber: json['drivingLicenceNumber']?.toString(),
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      vehicleDisplayName: json['vehicleDisplayName']?.toString(),
      assignedDate: json['assignedDate'] != null
          ? DateTime.tryParse(json['assignedDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      status: AssignmentStatus.fromString(json['status']?.toString()),
      statusLabel: json['statusLabel']?.toString() ?? 'Active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
