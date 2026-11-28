import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/dashboard_summary.dart';
import '../models/vehicle_document.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Service coordinating executive fleet dashboard state.
class DashboardService extends ChangeNotifier {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;

  final ApiClient _client;

  DashboardService._internal({ApiClient? client})
      : _client = client ?? ApiClient();

  @visibleForTesting
  DashboardService.forTest({required ApiClient client})
      : this._internal(client: client);

  DashboardSummary _summary = const DashboardSummary();
  List<VehicleDocumentExpiry> _expiryAlerts = [];
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary get summary => _summary;
  List<VehicleDocumentExpiry> get expiryAlerts => List.unmodifiable(_expiryAlerts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Loads executive summary metrics and expiry alerts from Spring Boot.
  Future<void> loadDashboard({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _client.get(AppConfig.dashboardSummaryEndpoint),
        _client.get('${AppConfig.documentsEndpoint}/expiry-alerts', queryParameters: {'days': 30}),
      ]);

      if (results[0] is Map<String, dynamic>) {
        _summary = DashboardSummary.fromJson(results[0] as Map<String, dynamic>);
      }

      if (results[1] is List) {
        _expiryAlerts = (results[1] as List)
            .map((e) => VehicleDocumentExpiry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.userMessage;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSessionData() {
    _summary = const DashboardSummary();
    _expiryAlerts = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
