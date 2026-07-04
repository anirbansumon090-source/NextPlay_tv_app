// lib/data/services/secure_storage_service.dart

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/channel_model.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;


  Future<void> saveAuthToken(String token) =>
      _storage.write(key: 'auth_token', value: token);

  Future<String?> readAuthToken() => _storage.read(key: 'auth_token');

  Future<bool> hasUserSession() async {
    final token = await readAuthToken();
    return token != null && token.isNotEmpty;
  }


  Future<void> saveUserProfile(UserProfileModel profile) =>
      _storage.write(key: 'user_profile', value: jsonEncode(profile.toJson()));

  Future<UserProfileModel?> readUserProfile() async {
    final raw = await _storage.read(key: 'user_profile');
    if (raw == null || raw.isEmpty) return null;
    return UserProfileModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

 
  Future<void> clearSession() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_profile');
  }
}
