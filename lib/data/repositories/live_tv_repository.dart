// lib/data/repositories/live_tv_repository.dart

import '../models/channel_model.dart';
import '../services/secure_api_client.dart';
import '../services/secure_storage_service.dart';
import '../../utils/device_utils.dart';


class LiveTvRepository {
  const LiveTvRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  final SecureApiClient apiClient;
  final SecureStorageService secureStorage;
  
		Future<String> _getDeviceId() async {
    return await DeviceUtils.getUniqueId(); 
  			}

  
  Future<ChannelCatalogModel> fetchCatalog() async {
    final profile = await secureStorage.readUserProfile();
    String deviceId = await _getDeviceId(); 

    final Map<String, dynamic> payload = {
      'locale': 'en_US',
      'platform': 'ottking-tv',
      'device_id': deviceId,
    };

    if (profile != null && profile.email.isNotEmpty) {
      payload['email'] = profile.email;
      payload['session_token']=profile.token;
    }

    final data = await apiClient.post('catalog', payload);
    return ChannelCatalogModel.fromJson(data);
  }

  Future<Map<String, dynamic>> authenticate(
      String email, String password) async {
    String deviceId = await _getDeviceId(); // আইডি সংগ্রহ করুন
    return apiClient.post('auth/login', {
      'email': email,
      'password': password,
     'device_id': deviceId,
    });
  }

  Future<Map<String, dynamic>> register(
      String email, String password) async {
    String deviceId = await _getDeviceId(); // আইডি সংগ্রহ করুন
    return apiClient.post('auth/register', {
      'email': email,
      'password': password,
      'device_id': deviceId,
    });
  }
}
