import 'dart:convert';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import 'encryption_service.dart';
import 'secure_storage_service.dart';

class SecureApiClient {
  SecureApiClient({
    required this.encryptionService,
    required this.secureStorage,
    String? baseUrl,
  }) : _baseUrl = _normalise(baseUrl ?? AppConstants.defaultApiBaseUrl) {
    _initSecureClient();
  }

  final EncryptionService encryptionService;
  final SecureStorageService secureStorage;
  final String _baseUrl;
  late final HttpClient _httpClient;

  static String _normalise(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;


  void _initSecureClient() {
    _httpClient = HttpClient();
    
    _httpClient.findProxy = (uri) => "DIRECT";

    _httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      
      return true; 
    };
  }


  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    if (endpoint == 'catalog') {
      final profile = await secureStorage.readUserProfile();
      if (profile != null && profile.email.isNotEmpty) {
        payload['email'] = profile.email;
      }
    }
    
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final body = jsonEncode(payload);
    final encryptedBody = encryptionService.encrypt(body);
    final signaturePayload = '$timestamp|$endpoint|$encryptedBody';
    final signature = encryptionService.sign(signaturePayload);

    final uri = Uri.parse('$_baseUrl/$endpoint');

    
    final HttpClientRequest request;
    try {
      request = await _httpClient.postUrl(uri);
    } on SocketException catch (e) {
      throw Exception('Network error connecting to ${uri.host}: ${e.message}');
    }

    
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-api-key', AppConstants.apiKeyId);
    request.headers.set('x-timestamp', timestamp);
    request.headers.set('x-signature', signature);

    final authToken = await secureStorage.readAuthToken();
    if (authToken != null && authToken.isNotEmpty) {
      request.headers.set('Authorization', 'Bearer $authToken');
    }

 
    final String requestBody = jsonEncode({'encrypted_payload': encryptedBody});
    request.write(requestBody);
    
    final HttpClientResponse response = await request.close();

  
    final String responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      String detail = responseBody;
      try {
        final parsed = jsonDecode(responseBody);
        if (parsed is Map<String, dynamic> && parsed['error'] is String) {
          detail = parsed['error'] as String;
        }
      } catch (_) {}
      throw Exception('API error ${response.statusCode}: $detail');
    }

    final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
    final encryptedResponse = decoded['encrypted_payload'] as String;
    final signedResponse = decoded['signature'] as String;
    final decrypted = encryptionService.decrypt(encryptedResponse);

    if (!encryptionService.verify(decrypted, signedResponse)) {
      throw Exception('Response signature verification failed');
    }

    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
}
