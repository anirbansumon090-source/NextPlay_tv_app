// lib/presentation/screens/player_widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.hasError,
    required this.isLoading,
    required this.channelName,
    this.retryAttempt = 1,
    this.maxRetries = 3,
    this.showManualRetry = false,
    // ✅ FIX 4: বাফারিং দেখাতে হবে কিনা — শুধু সত্যিকার offline-এ দেখাবে
    // isBufferingVisible = false হলে লোডিং স্পিনার দেখাবে না (স্ট্রিম
    // শুধু লেটেন্সি/নেটওয়ার্কের কারণে স্লো হলে), true হলে দেখাবে (সত্যিকার
    // অফলাইন বা exhausted retry-তে)।
    this.isBufferingVisible = true,
  });

  final bool hasError;
  final bool isLoading;
  final String channelName;
  final int retryAttempt;
  final int maxRetries;
  final bool showManualRetry;
  final bool isBufferingVisible;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 4: isLoading true হলেও isBufferingVisible false থাকলে
    // কিছুই দেখাবে না — ভিডিও ব্যাকগ্রাউন্ডে লোড হতে থাকবে শান্তিতে।
    // শুধু hasError বা isBufferingVisible=true হলে ওভারলে দেখাবে।
    if (!hasError && (!isLoading || !isBufferingVisible)) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError) ...[
              const Icon(
                Icons.signal_wifi_statusbar_connected_no_internet_4,
                color: Colors.white38,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                '$channelName — Offline',
                style: const TextStyle(color: Colors.white60, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (showManualRetry) ...[
                const Text(
                  'Press OK / Select to retry',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 6),
              ],
              const Text(
                'Use ↑ ↓ or CH+/CH− to change channel',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ] else if (isLoading && isBufferingVisible) ...[
              const CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                retryAttempt > 1
                    ? 'Reconnecting $channelName… ($retryAttempt/$maxRetries)'
                    : 'Loading $channelName...',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
