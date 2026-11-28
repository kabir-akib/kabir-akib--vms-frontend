import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/vehicle_document.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Service coordinating document uploads, compliance tracking, and expiry alerts.
class DocumentService extends ChangeNotifier {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;

  final ApiClient _client;

  DocumentService._internal({ApiClient? client})
      : _client = client ?? ApiClient();

  @visibleForTesting
  DocumentService.forTest({required ApiClient client})
      : this._internal(client: client);

  List<VehicleDocumentExpiry> _allExpiryAlerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleDocumentExpiry> get allExpiryAlerts => List.unmodifiable(_allExpiryAlerts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Loads fleet-wide document expiry alerts: `GET /api/v1/documents/expiry-alerts?days=30`
  Future<void> loadExpiryAlerts({int days = 30, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final data = await _client.get(
        '${AppConfig.documentsEndpoint}/expiry-alerts',
        queryParameters: {'days': days},
      );

      if (data is List) {
        _allExpiryAlerts = data
            .map((e) => VehicleDocumentExpiry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
    } catch (e) {
      _errorMessage = 'Failed to load document alerts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches documents for a vehicle: `GET /api/v1/vehicles/{vehicleId}/documents`
  Future<List<VehicleDocument>> getDocumentsForVehicle(String vehicleId) async {
    final data = await _client.get(AppConfig.vehicleDocumentsUrl(vehicleId));
    if (data is List) {
      return data
          .map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches expiry status for documents of a single vehicle: `GET /api/v1/documents/vehicles/{vehicleId}/expiry`
  Future<List<VehicleDocumentExpiry>> getVehicleDocumentExpiries(String vehicleId, {int days = 30}) async {
    final data = await _client.get(
      '${AppConfig.documentsEndpoint}/vehicles/$vehicleId/expiry',
      queryParameters: {'days': days},
    );
    if (data is List) {
      return data
          .map((e) => VehicleDocumentExpiry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Uploads a compliance document with optional expiry date: `POST /api/v1/vehicles/{vehicleId}/documents`
  Future<VehicleDocument> uploadDocument({
    required String vehicleId,
    required DocumentType documentType,
    required List<int> fileBytes,
    required String filename,
    DateTime? expiryDate,
  }) async {
    final fields = <String, String>{
      'documentType': documentType.apiValue,
      if (expiryDate != null)
        'expiryDate': expiryDate.toIso8601String().substring(0, 10),
    };

    final data = await _client.uploadMultipart(
      AppConfig.vehicleDocumentsUrl(vehicleId),
      fields: fields,
      fileBytes: fileBytes,
      filename: filename,
    );

    return VehicleDocument.fromJson(data as Map<String, dynamic>);
  }

  /// Deletes a document: `DELETE /api/v1/vehicles/{vehicleId}/documents/{documentId}`
  Future<void> deleteDocument(String vehicleId, String documentId) async {
    await _client.delete('${AppConfig.vehicleDocumentsUrl(vehicleId)}/$documentId');
  }

  void clearSessionData() {
    _allExpiryAlerts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
