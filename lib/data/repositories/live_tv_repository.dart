// lib/data/repositories/live_tv_repository.dart

import '../models/channel_model.dart';
import '../services/secure_api_client.dart';
import '../services/secure_storage_service.dart';

class LiveTvRepository {
  const LiveTvRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  final SecureApiClient apiClient;
  final SecureStorageService secureStorage;

  Future<ChannelCatalogModel> fetchCatalog() async {
    final profile = await secureStorage.readUserProfile();

    final Map<String, dynamic> payload = {
      'locale': 'en_US',
      'platform': 'ottking-tv',
    };

    if (profile != null && profile.email.isNotEmpty) {
      payload['email'] = profile.email;
    }

    final data = await apiClient.post('catalog', payload);
    return ChannelCatalogModel.fromJson(data);
  }

  Future<Map<String, dynamic>> authenticate(
      String email, String password) async {
    return apiClient.post('auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register(
      String email, String password) async {
    return apiClient.post('auth/register', {
      'email': email,
      'password': password,
    });
  }
}
