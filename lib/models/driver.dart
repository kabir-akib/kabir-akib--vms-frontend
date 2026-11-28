/// Driver operational status matching Spring Boot [DriverStatus].
enum DriverStatus {
  active('ACTIVE', 'Active'),
  inactive('INACTIVE', 'Inactive'),
  suspended('SUSPENDED', 'Suspended');

  final String apiValue;
  final String label;

  const DriverStatus(this.apiValue, this.label);

  static DriverStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return DriverStatus.active;
    final normalized = value.trim().toUpperCase();
    for (final s in DriverStatus.values) {
      if (s.apiValue == normalized || s.name.toUpperCase() == normalized) {
        return s;
      }
    }
    return DriverStatus.active;
  }
}

/// Driver entity matching Spring Boot [DriverResponse].
class Driver {
  final String id;
  final String name;
  final String phoneNumber;
  final String drivingLicenceNumber;
  final DateTime? licenceExpiryDate;
  final String? address;
  final DriverStatus status;
  final String statusLabel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Driver({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.drivingLicenceNumber,
    this.licenceExpiryDate,
    this.address,
    required this.status,
    required this.statusLabel,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLicenceExpired {
    if (licenceExpiryDate == null) return false;
    return licenceExpiryDate!.isBefore(DateTime.now());
  }

  bool get isLicenceExpiringSoon {
    if (licenceExpiryDate == null) return false;
    final days = licenceExpiryDate!.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 30;
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      drivingLicenceNumber: json['drivingLicenceNumber']?.toString() ?? '',
      licenceExpiryDate: json['licenceExpiryDate'] != null
          ? DateTime.tryParse(json['licenceExpiryDate'].toString())
          : null,
      address: json['address']?.toString(),
      status: DriverStatus.fromString(json['status']?.toString()),
      statusLabel: json['statusLabel']?.toString() ?? 'Active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'drivingLicenceNumber': drivingLicenceNumber,
      if (licenceExpiryDate != null)
        'licenceExpiryDate': licenceExpiryDate!.toIso8601String().substring(0, 10),
      if (address != null && address!.isNotEmpty) 'address': address,
      'status': status.apiValue,
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? drivingLicenceNumber,
    DateTime? licenceExpiryDate,
    String? address,
    DriverStatus? status,
    String? statusLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      drivingLicenceNumber: drivingLicenceNumber ?? this.drivingLicenceNumber,
      licenceExpiryDate: licenceExpiryDate ?? this.licenceExpiryDate,
      address: address ?? this.address,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
