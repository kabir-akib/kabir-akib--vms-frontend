/// Categories of vehicle compliance documents matching Spring Boot [DocumentType].
enum DocumentType {
  registrationCertificate('REGISTRATION_CERTIFICATE', 'Registration Certificate'),
  taxToken('TAX_TOKEN', 'Tax Token'),
  insurance('INSURANCE', 'Insurance'),
  fitnessCertificate('FITNESS_CERTIFICATE', 'Fitness Certificate'),
  other('OTHER', 'Other');

  final String apiValue;
  final String label;

  const DocumentType(this.apiValue, this.label);

  static DocumentType fromString(String? value) {
    if (value == null || value.trim().isEmpty) return DocumentType.other;
    final normalized = value.trim().toUpperCase();
    for (final t in DocumentType.values) {
      if (t.apiValue == normalized || t.name.toUpperCase() == normalized || t.label.toUpperCase() == normalized) {
        return t;
      }
    }
    return DocumentType.other;
  }
}

/// Expiry status matching Spring Boot [DocumentExpiryStatus].
enum DocumentExpiryStatus {
  expired('EXPIRED', 'Expired'),
  expiringSoon('EXPIRING_SOON', 'Expiring Soon'),
  valid('VALID', 'Valid');

  final String apiValue;
  final String label;

  const DocumentExpiryStatus(this.apiValue, this.label);

  static DocumentExpiryStatus fromString(String? value) {
    if (value == null || value.trim().isEmpty) return DocumentExpiryStatus.valid;
    final normalized = value.trim().toUpperCase();
    for (final s in DocumentExpiryStatus.values) {
      if (s.apiValue == normalized || s.name.toUpperCase() == normalized || s.label.toUpperCase() == normalized) {
        return s;
      }
    }
    return DocumentExpiryStatus.valid;
  }
}

/// Represents an uploaded compliance document for a vehicle.
class VehicleDocument {
  final String id;
  final String vehicleId;
  final String vehicleNumber;
  final DocumentType documentType;
  final String? documentTypeLabel;
  final String originalFilename;
  final String? storedFileRef;
  final String? contentType;
  final int fileSize;
  final DateTime? uploadDate;
  final DateTime? expiryDate;
  final String? downloadUrl;

  const VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.documentType,
    this.documentTypeLabel,
    required this.originalFilename,
    this.storedFileRef,
    this.contentType,
    required this.fileSize,
    this.uploadDate,
    this.expiryDate,
    this.downloadUrl,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      documentType: DocumentType.fromString(json['documentType']?.toString()),
      documentTypeLabel: json['documentTypeLabel']?.toString(),
      originalFilename: json['originalFilename']?.toString() ?? '',
      storedFileRef: json['storedFileRef']?.toString(),
      contentType: json['contentType']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      uploadDate: json['uploadDate'] != null ? DateTime.tryParse(json['uploadDate'].toString()) : null,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      downloadUrl: json['downloadUrl']?.toString(),
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Document expiry alert representation matching Spring Boot [VehicleDocumentExpiryResponse].
class VehicleDocumentExpiry {
  final String documentId;
  final DocumentType documentType;
  final String? documentTypeLabel;
  final String originalFilename;
  final String vehicleId;
  final String vehicleNumber;
  final String company;
  final String brand;
  final String model;
  final String vehicleDisplayName;
  final DateTime? expiryDate;
  final int daysUntilExpiry;
  final DocumentExpiryStatus expiryStatus;
  final String? expiryStatusLabel;

  const VehicleDocumentExpiry({
    required this.documentId,
    required this.documentType,
    this.documentTypeLabel,
    required this.originalFilename,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.company,
    required this.brand,
    required this.model,
    required this.vehicleDisplayName,
    this.expiryDate,
    required this.daysUntilExpiry,
    required this.expiryStatus,
    this.expiryStatusLabel,
  });

  factory VehicleDocumentExpiry.fromJson(Map<String, dynamic> json) {
    return VehicleDocumentExpiry(
      documentId: json['documentId']?.toString() ?? '',
      documentType: DocumentType.fromString(json['documentType']?.toString()),
      documentTypeLabel: json['documentTypeLabel']?.toString(),
      originalFilename: json['originalFilename']?.toString() ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      vehicleDisplayName: json['vehicleDisplayName']?.toString() ?? '',
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt() ?? 0,
      expiryStatus: DocumentExpiryStatus.fromString(json['expiryStatus']?.toString()),
      expiryStatusLabel: json['expiryStatusLabel']?.toString(),
    );
  }
}
