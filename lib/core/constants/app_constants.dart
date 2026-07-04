// lib/core/constants/app_constants.dart

class AppConstants {
  const AppConstants._();

  static const String appName     = 'Next Play';
  static const String appTagline  = 'Smart TV Streaming';

  // API
  static const String defaultApiBaseUrl = 'http://172.16.17.16/app';

  // Security
  static const String apiKeyId       = 'R54P9WJA3K';
  static const String hmacSecret     = '94956c0e9613d718a15a82545563f47e';
  static const String encryptionKey  = '675e95781133ec2f6f3cd93bbba46461'; 

  // Player
  static const String fallbackStreamUrl =
      'https://livetvapp.alwaysdata.net/fallbacks/live.m3u8';

  // Timing
  static const Duration splashDuration  = Duration(seconds: 3);
  static const Duration toastDuration   = Duration(seconds: 3);
  static const int requestTimestampToleranceSeconds = 300;

  // Boot player storage key
  static const String keyBootToPlayer  = 'bootToPlayer';
  static const String keyLastChannelId = 'lastChannelId';
  static const String keyThemeMode     = 'themeMode';
}
