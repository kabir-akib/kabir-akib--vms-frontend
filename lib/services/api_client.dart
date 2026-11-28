import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'api_exception.dart';

/// HTTP Client abstraction for communicating with the Spring Boot REST API.
class ApiClient {
  static String? _sharedAuthToken;
  static void Function()? _onUnauthorized;

  final http.Client _client;
  final String _baseUrl;
  String? _instanceAuthToken;

  ApiClient({http.Client? client, String? baseUrl, String? authToken})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.baseUrl,
        _instanceAuthToken = authToken;

  String get baseUrl => _baseUrl;

  String? get authToken => _instanceAuthToken ?? _sharedAuthToken;

  static void setSharedAuthToken(String? token) {
    _sharedAuthToken = token;
  }

  static void setUnauthorizedHandler(void Function()? handler) {
    _onUnauthorized = handler;
  }

  void setAuthToken(String? token) {
    _instanceAuthToken = token;
    _sharedAuthToken = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';

    if (queryParameters == null || queryParameters.isEmpty) {
      return Uri.parse(fullUrl);
    }

    final queryMap = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryMap[key] = value.toString();
      }
    });

    return Uri.parse(fullUrl).replace(queryParameters: queryMap);
  }

  /// Performs an HTTP GET request and returns decoded response data.
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, uri.path);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out while contacting server at $_baseUrl.',
        path: uri.path,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error: Unable to reach backend at $_baseUrl. '
            'Please verify the Spring Boot server is running. (${e.message})',
        path: uri.path,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to communicate with backend: $e',
        path: uri.path,
      );
    }
  }

  /// Performs an HTTP POST request with a JSON body.
  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, uri.path);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out while contacting server at $_baseUrl.',
        path: uri.path,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error: Unable to reach backend at $_baseUrl. '
            'Please verify the Spring Boot server is running. (${e.message})',
        path: uri.path,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to communicate with backend: $e',
        path: uri.path,
      );
    }
  }

  /// Performs an HTTP PUT request with a JSON body.
  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, uri.path);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out while contacting server at $_baseUrl.',
        path: uri.path,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error: Unable to reach backend at $_baseUrl. '
            'Please verify the Spring Boot server is running. (${e.message})',
        path: uri.path,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to communicate with backend: $e',
        path: uri.path,
      );
    }
  }

  /// Performs an HTTP PATCH request with a JSON body.
  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .patch(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, uri.path);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out while contacting server at $_baseUrl.',
        path: uri.path,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error: Unable to reach backend at $_baseUrl. '
            'Please verify the Spring Boot server is running. (${e.message})',
        path: uri.path,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to communicate with backend: $e',
        path: uri.path,
      );
    }
  }

  /// Performs an HTTP DELETE request.
  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, uri.path);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out while contacting server at $_baseUrl.',
        path: uri.path,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error: Unable to reach backend at $_baseUrl. '
            'Please verify the Spring Boot server is running. (${e.message})',
        path: uri.path,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to communicate with backend: $e',
        path: uri.path,
      );
    }
  }

  /// Performs a multipart form upload for files (e.g. documents).
  Future<dynamic> uploadMultipart(
    String path, {
    required Map<String, String> fields,
    required List<int> fileBytes,
    required String filename,
    String fileField = 'file',
  }) async {
    final uri = _buildUri(path);
    try {
      final request = http.MultipartRequest('POST', uri);
      final token = authToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse =
          await request.send().timeout(AppConfig.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, uri.path);
    } on TimeoutException {
      throw ApiException(
        message: 'Request timed out while uploading document to $_baseUrl.',
        path: uri.path,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Network error during upload to $_baseUrl: (${e.message})',
        path: uri.path,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to upload document: $e',
        path: uri.path,
      );
    }
  }

  /// Handles Spring Boot [ApiResponse<T>] and [ErrorResponse] payloads.
  dynamic _handleResponse(http.Response response, String path) {
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }

    final statusCode = response.statusCode;

    // Successful responses: 200 OK, 201 Created, 204 No Content
    if (statusCode >= 200 && statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data')) {
          return decoded['data'];
        }
        return decoded;
      }
      return decoded;
    }

    // Error responses from Spring Boot
    String errorMessage = 'Request failed with status $statusCode';
    String? errorType;
    Map<String, String>? fieldErrors;

    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
        errorMessage = decoded['message'].toString();
      }
      if (decoded['error'] != null) {
        errorType = decoded['error'].toString();
      }
      if (decoded['fieldErrors'] is Map) {
        fieldErrors = Map<String, String>.from(
          (decoded['fieldErrors'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        );
      }
    }

    if (statusCode == 401 && !path.endsWith(AppConfig.loginEndpoint)) {
      _onUnauthorized?.call();
    }

    throw ApiException(
      statusCode: statusCode,
      message: errorMessage,
      error: errorType,
      path: path,
      fieldErrors: fieldErrors,
    );
  }
}
