// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/live_tv_repository.dart';
import 'data/services/encryption_service.dart';
import 'data/services/secure_api_client.dart';
import 'data/services/secure_storage_service.dart';
import 'presentation/providers/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force landscape globally for TV
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  final secureStorage = SecureStorageService();
  final encryptionService = EncryptionService();

  final apiClient = SecureApiClient(
    encryptionService: encryptionService,
    secureStorage: secureStorage,
    baseUrl: AppConstants.defaultApiBaseUrl,
  );

  final repository = LiveTvRepository(
    apiClient: apiClient,
    secureStorage: secureStorage,
  );

  final appState = AppState(
    repository: repository,
    prefs: prefs,
    secureStorage: secureStorage,
  );

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const OttKingApp(),
    ),
  );
}