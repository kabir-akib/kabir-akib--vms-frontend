import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/screens/auth/login_screen.dart';
import 'package:vms_frontend/services/api_client.dart';
import 'package:vms_frontend/services/api_exception.dart';
import 'package:vms_frontend/services/auth_service.dart';

class InMemoryTokenStorage implements SecureTokenStorage {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> deleteToken() async {
    _token = null;
  }
}

void main() {
  tearDown(() {
    ApiClient.setSharedAuthToken(null);
    ApiClient.setUnauthorizedHandler(null);
  });

  group('AuthService & ApiClient Bearer Token Integration', () {
    test('login stores token securely and injects Bearer header on vehicle requests',
        () async {
      String? capturedAuthHeader;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'admin@starkgroup.com');
          expect(body['password'], 'stark2026');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Signed in successfully',
              'data': {
                'token': 'opaque-token-123',
                'tokenType': 'Bearer',
                'expiresAt':
                    DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
                'user': {
                  'id': 'u-1',
                  'email': 'admin@starkgroup.com',
                  'fullName': 'Stark Fleet Admin',
                  'role': 'ADMIN',
                },
              },
            }),
            200,
          );
        }

        if (request.url.path == '/api/v1/vehicles') {
          capturedAuthHeader = request.headers['Authorization'];
          return http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
          );
        }

        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final storage = InMemoryTokenStorage();
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      final session = await authService.login(
        email: 'admin@starkgroup.com',
        password: 'stark2026',
        rememberMe: true,
      );

      expect(authService.isAuthenticated, isTrue);
      expect(session.token, 'opaque-token-123');
      expect(authService.currentUser?.email, 'admin@starkgroup.com');
      expect(await storage.readToken(), 'opaque-token-123');

      await apiClient.get('/api/v1/vehicles');
      expect(capturedAuthHeader, 'Bearer opaque-token-123');
    });

    test('login with rememberMe=false keeps session in memory without persisting token',
        () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'session-only-token',
              'tokenType': 'Bearer',
              'user': {
                'id': 'u-1',
                'email': 'admin@starkgroup.com',
                'fullName': 'Stark Fleet Admin',
                'role': 'ADMIN',
              },
            },
          }),
          200,
        );
      });

      final storage = InMemoryTokenStorage();
      await storage.writeToken('stale-token');

      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      await authService.login(
        email: 'admin@starkgroup.com',
        password: 'stark2026',
        rememberMe: false,
      );

      expect(authService.isAuthenticated, isTrue);
      expect(await storage.readToken(), isNull);
    });

    test('login throws ApiException on 401 and does not authenticate', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 401,
            'error': 'Unauthorized',
            'message': 'Invalid email or password',
            'path': '/api/v1/auth/login',
          }),
          401,
        );
      });

      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final storage = InMemoryTokenStorage();
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      await expectLater(
        authService.login(
          email: 'admin@starkgroup.com',
          password: 'wrong',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      expect(authService.isAuthenticated, isFalse);
      expect(await storage.readToken(), isNull);
    });

    test('restoreSession validates stored token via /api/v1/auth/me', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/me' &&
            request.headers['Authorization'] == 'Bearer valid-stored-token') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'u-1',
                'email': 'admin@starkgroup.com',
                'fullName': 'Stark Fleet Admin',
                'role': 'ADMIN',
              },
            }),
            200,
          );
        }
        return http.Response('Unauthorized', 401);
      });

      final storage = InMemoryTokenStorage();
      await storage.writeToken('valid-stored-token');

      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      final restored = await authService.restoreSession();
      expect(restored, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.email, 'admin@starkgroup.com');
    });

    test('logout revokes token on backend and clears local storage', () async {
      bool logoutCalled = false;
      final mockHttp = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'token-to-revoke',
                'tokenType': 'Bearer',
                'user': {
                  'id': 'u-1',
                  'email': 'admin@starkgroup.com',
                  'fullName': 'Stark Fleet Admin',
                  'role': 'ADMIN',
                },
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/auth/logout') {
          logoutCalled = request.headers['Authorization'] == 'Bearer token-to-revoke';
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not found', 404);
      });

      final storage = InMemoryTokenStorage();
      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      await authService.login(
        email: 'admin@starkgroup.com',
        password: 'stark2026',
      );
      await authService.logout();

      expect(logoutCalled, isTrue);
      expect(authService.isAuthenticated, isFalse);
      expect(apiClient.authToken, isNull);
      expect(await storage.readToken(), isNull);
    });
  });

  group('LoginScreen Widget Integration', () {
    testWidgets('shows user-friendly error message when backend returns 401',
        (WidgetTester tester) async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': 401,
            'error': 'Unauthorized',
            'message': 'Invalid email or password',
            'path': '/api/v1/auth/login',
          }),
          401,
        );
      });

      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: InMemoryTokenStorage(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: authService),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In to Fleet Portal'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Invalid email or password. Please check your credentials and try again.',
        ),
        findsOneWidget,
      );
      expect(authService.isAuthenticated, isFalse);
    });

    testWidgets('navigates to shell on successful login',
        (WidgetTester tester) async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'valid-token',
              'tokenType': 'Bearer',
              'user': {
                'id': 'u-1',
                'email': 'admin@starkgroup.com',
                'fullName': 'Stark Fleet Admin',
                'role': 'ADMIN',
              },
            },
          }),
          200,
        );
      });

      final apiClient = ApiClient(client: mockHttp, baseUrl: 'http://localhost:8080');
      final authService = AuthService.forTest(
        apiClient: apiClient,
        tokenStorage: InMemoryTokenStorage(),
      );

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/login',
          routes: {
            '/login': (_) => LoginScreen(authService: authService),
            '/': (_) => const Scaffold(body: Text('Fleet Shell Screen')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign In to Fleet Portal'));
      await tester.pumpAndSettle();

      expect(authService.isAuthenticated, isTrue);
      expect(find.text('Fleet Shell Screen'), findsOneWidget);
    });
  });
}
