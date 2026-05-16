import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env/app_env.dart';
import '../errors/exceptions.dart';
import '../network/api_endpoints.dart';
import '../services/token_service.dart';
import '../utils/api_logger.dart';

class ApiClient {
  final http.Client _client;
  final TokenService _tokenService;

  ApiClient({http.Client? client, required TokenService tokenService})
      : _client = client ?? http.Client(),
        _tokenService = tokenService;

  String get _base => AppEnv.baseUrl;

  Map<String, String> get _baseHeaders =>
      {'Content-Type': 'application/json'};

  Map<String, String> get _authHeaders => {
        ..._baseHeaders,
        if (_tokenService.accessToken != null)
          'Authorization': 'Bearer ${_tokenService.accessToken}',
      };

  Future<Map<String, dynamic>> get(
    String path, {
    bool auth = false,
  }) =>
      _execute(
        () => _client.get(
          Uri.parse('$_base$path'),
          headers: auth ? _authHeaders : _baseHeaders,
        ),
        method: 'GET',
        path: path,
        auth: auth,
      );

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) =>
      _execute(
        () => _client.post(
          Uri.parse('$_base$path'),
          headers: auth ? _authHeaders : _baseHeaders,
          body: jsonEncode(body),
        ),
        method: 'POST',
        path: path,
        auth: auth,
        body: body,
      );

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) =>
      _execute(
        () => _client.put(
          Uri.parse('$_base$path'),
          headers: auth ? _authHeaders : _baseHeaders,
          body: jsonEncode(body),
        ),
        method: 'PUT',
        path: path,
        auth: auth,
        body: body,
      );

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) =>
      _execute(
        () => _client.delete(
          Uri.parse('$_base$path'),
          headers: auth ? _authHeaders : _baseHeaders,
        ),
        method: 'DELETE',
        path: path,
        auth: auth,
      );

  Future<Map<String, dynamic>> uploadFile(String path, String filePath) async {
    final url = '$_base$path';

    Future<http.Response> doUpload() async {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      if (_tokenService.accessToken != null) {
        request.headers['Authorization'] =
            'Bearer ${_tokenService.accessToken}';
      }
      request.files
          .add(await http.MultipartFile.fromPath('image', filePath));
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }

    try {
      var response = await doUpload();
      if (response.statusCode == 401) {
        final refreshed = await _tryRefresh();
        if (!refreshed) throw const TokenExpiredException();
        response = await doUpload();
      }
      ApiLogger.logResponse(
        statusCode: response.statusCode,
        url: url,
        rawBody: response.body,
      );
      return _parse(response);
    } on ServerException {
      rethrow;
    } on TokenExpiredException {
      rethrow;
    } catch (e) {
      ApiLogger.logError(url: url, error: e);
      throw const NetworkException();
    }
  }

  Future<Map<String, dynamic>> _execute(
    Future<http.Response> Function() fn, {
    required String method,
    required String path,
    required bool auth,
    Map<String, dynamic>? body,
  }) async {
    final url = '$_base$path';
    ApiLogger.logRequest(
      method: method,
      url: url,
      headers: auth ? _authHeaders : _baseHeaders,
      body: body,
    );

    try {
      var response = await fn();

      if (response.statusCode == 401 && auth) {
        final refreshed = await _tryRefresh();
        if (!refreshed) throw const TokenExpiredException();
        response = await fn();
      }

      ApiLogger.logResponse(
        statusCode: response.statusCode,
        url: url,
        rawBody: response.body,
      );

      return _parse(response);
    } on ServerException {
      rethrow;
    } on TokenExpiredException {
      rethrow;
    } catch (e) {
      ApiLogger.logError(url: url, error: e);
      throw const NetworkException();
    }
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$_base${ApiEndpoints.refresh}'),
        headers: _baseHeaders,
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode != 200) {
        ApiLogger.logRefresh(success: false);
        return false;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      await _tokenService.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      ApiLogger.logRefresh(success: true);
      return true;
    } catch (_) {
      ApiLogger.logRefresh(success: false);
      return false;
    }
  }

  Map<String, dynamic> _parse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    throw ServerException(
      message: json['message'] as String? ?? 'Unknown error',
      statusCode: response.statusCode,
    );
  }
}
