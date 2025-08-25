import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Admin-only service to manage and inspect the OpenRouter proxy backend
/// - Reads PROXY_ENDPOINT from .env
/// - Uses PROXY_ADMIN_TOKEN for authenticated admin operations (never ship real token)
/// - Endpoints are configurable via PROXY_STATUS_PATH and PROXY_ADMIN_SET_KEY_PATH
class AdminProxyService {
  AdminProxyService._();
  static final AdminProxyService instance = AdminProxyService._();

  Dio _buildClient({bool forStream = false}) {
    final baseUrl = dotenv.env['PROXY_ENDPOINT'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('PROXY_ENDPOINT not set');
    }
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'X-Admin-Token': dotenv.env['PROXY_ADMIN_TOKEN'] ?? '',
      },
    ));
  }

  String get _statusPath => dotenv.env['PROXY_STATUS_PATH'] ?? '/status';
  String get _setKeyPath => dotenv.env['PROXY_ADMIN_SET_KEY_PATH'] ?? '/admin/api-key';

  /// Fetch proxy status JSON
  Future<Map<String, dynamic>?> getStatus() async {
    try {
      final dio = _buildClient();
      final res = await dio.get(_statusPath);
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) return data;
      }
      return null;
    } catch (e) {
      developer.log('AdminProxyService.getStatus failed: $e', name: 'AdminProxyService');
      return null;
    }
  }

  /// Securely set/update backend OpenRouter API key via proxy admin endpoint
  /// Returns true if the backend acknowledges the change.
  Future<bool> setBackendApiKey(String apiKey) async {
    try {
      final adminToken = dotenv.env['PROXY_ADMIN_TOKEN'] ?? '';
      if (adminToken.isEmpty) {
        throw Exception('Missing PROXY_ADMIN_TOKEN. Set it in .env for local dev only.');
      }

      final dio = _buildClient();
      final res = await dio.post(
        _setKeyPath,
        data: {
          'apiKey': apiKey,
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      developer.log('AdminProxyService.setBackendApiKey failed: $e', name: 'AdminProxyService');
      return false;
    }
  }
}

