import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/models/vehicle.dart';
import 'package:vms_frontend/services/api_client.dart';
import 'package:vms_frontend/services/api_exception.dart';
import 'package:vms_frontend/services/vehicle_api_service.dart';
import 'package:vms_frontend/services/vehicle_service.dart';

void main() {
  final sampleVehicleJson = {
    'id': 'v-1',
    'vehicleNumber': 'STK-1042',
    'company': 'Stark Logistics',
    'type': 'TRUCK',
    'typeLabel': 'Truck',
    'brand': 'Scania',
    'model': 'R500',
    'displayName': 'Scania R500',
    'status': 'ACTIVE',
    'statusLabel': 'Active',
  };

  group('VehicleService CRUD Integration', () {
    test('loadVehicles transitions from loading to success and populates metrics',
        () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles') {
          return http.Response(
            jsonEncode({'success': true, 'data': [sampleVehicleJson]}),
            200,
          );
        }
        if (request.url.path == '/api/v1/vehicles/metrics') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalVehicles': 1,
                'activeVehicles': 1,
                'maintenanceVehicles': 0,
                'inactiveVehicles': 0,
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/vehicles/companies') {
          return http.Response(
            jsonEncode({'success': true, 'data': ['Stark Logistics']}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = VehicleService.forTest(
        apiService: VehicleApiService(
          client: ApiClient(client: mockHttp, authToken: 'test-token'),
        ),
      );

      await service.loadVehicles();

      expect(service.isLoading, isFalse);
      expect(service.hasError, isFalse);
      expect(service.isSuccess, isTrue);
      expect(service.vehicles, hasLength(1));
      expect(service.vehicles.first.vehicleNumber, 'STK-1042');
      expect(service.totalVehicles, 1);
      expect(service.availableCompanies, ['Stark Logistics']);
    });

    test('loadVehicles sets empty state when backend returns empty list', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/vehicles') {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        if (request.url.path == '/api/v1/vehicles/metrics') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'totalVehicles': 0,
                'activeVehicles': 0,
                'maintenanceVehicles': 0,
                'inactiveVehicles': 0,
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final service = VehicleService.forTest(
        apiService: VehicleApiService(
          client: ApiClient(client: mockHttp, authToken: 'test-token'),
        ),
      );

      await service.loadVehicles();

      expect(service.isLoading, isFalse);
      expect(service.hasError, isFalse);
      expect(service.isEmpty, isTrue);
      expect(service.vehicles, isEmpty);
    });

    test('registerVehicle preserves list state and surfaces field errors on 400/409',
        () async {
      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/vehicles') {
          return http.Response(
            jsonEncode({'success': true, 'data': [sampleVehicleJson]}),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/api/v1/vehicles') {
          return http.Response(
            jsonEncode({
              'status': 409,
              'error': 'Duplicate Vehicle Number',
              'message': "Vehicle with number 'STK-1042' already exists in the fleet.",
              'path': '/api/v1/vehicles',
            }),
            409,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });

      final service = VehicleService.forTest(
        apiService: VehicleApiService(
          client: ApiClient(client: mockHttp, authToken: 'test-token'),
        ),
      );

      await service.loadVehicles();
      expect(service.vehicles, hasLength(1));

      final duplicate = Vehicle(
        id: '',
        vehicleNumber: 'STK-1042',
        company: 'Stark Logistics',
        type: VehicleType.truck,
        brand: 'Scania',
        model: 'R500',
        status: VehicleStatus.active,
      );

      await expectLater(
        service.registerVehicle(duplicate),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 409)
              .having(
                (e) => e.userMessage,
                'userMessage',
                contains('STK-1042'),
              ),
        ),
      );

      // List state must remain intact (not replaced by an error state)
      expect(service.hasError, isFalse);
      expect(service.vehicles, hasLength(1));
    });

    test('deleteVehicle removes vehicle only after backend DELETE succeeds',
        () async {
      bool allowDelete = false;
      bool deletedOnServer = false;

      final mockHttp = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/v1/vehicles') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': deletedOnServer ? [] : [sampleVehicleJson],
            }),
            200,
          );
        }
        if (request.method == 'DELETE' && request.url.path == '/api/v1/vehicles/v-1') {
          if (!allowDelete) {
            return http.Response(
              jsonEncode({
                'status': 500,
                'error': 'Internal Server Error',
                'message': 'Database unavailable',
              }),
              500,
            );
          }
          deletedOnServer = true;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });

      final service = VehicleService.forTest(
        apiService: VehicleApiService(
          client: ApiClient(client: mockHttp, authToken: 'test-token'),
        ),
      );

      await service.loadVehicles();
      expect(service.vehicles, hasLength(1));

      // Failure: vehicle must stay in local list
      await expectLater(
        service.deleteVehicle('v-1'),
        throwsA(isA<ApiException>()),
      );
      expect(service.vehicles, hasLength(1));
      expect(service.hasError, isFalse);

      // Success: vehicle is removed after backend DELETE succeeds
      allowDelete = true;
      await service.deleteVehicle('v-1');
      expect(service.vehicles, isEmpty);
      expect(service.isEmpty, isTrue);
    });

    test('ApiException.userMessage formats multiple backend validation fieldErrors',
        () {
      final ex = ApiException(
        statusCode: 400,
        message: 'One or more request fields have validation errors',
        error: 'Validation Failed',
        fieldErrors: {
          'vehicleNumber': 'Vehicle number is required',
          'company': 'Company is required',
        },
      );

      expect(
        ex.userMessage,
        'Vehicle number is required\nCompany is required',
      );
    });
  });
}
