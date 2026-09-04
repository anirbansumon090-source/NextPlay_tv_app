// lib/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _boot();
  }

  Future<void> _boot() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appState = context.read<AppState>();
    final start = DateTime.now();

    try {
      await appState.bootstrap();

      if (appState.errorMessage.isNotEmpty || appState.channels.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = appState.errorMessage.isNotEmpty
                ? 'Network or server issue. Please try again.'
                : 'Channel failed to load. Please check your internet connection.';
          });
        }
        return;
      }

      final elapsed = DateTime.now().difference(start);
      final remaining = AppConstants.splashDuration - elapsed;
      if (remaining > Duration.zero) await Future.delayed(remaining);

      _navigate();
    } catch (e) {
      debugPrint('Splash error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Network or server issue. Please try again.';
        });
      }
    }
  }

  void _navigate() {
    if (!mounted) return;
    final appState = context.read<AppState>();

    if (appState.shouldBootToPlayer() && appState.channels.isNotEmpty) {
      Navigator.pushNamedAndRemoveUntil(context, '/player', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ব্যানার ইমেজ — কোনো অংশ crop না হয়ে পুরো ছবিটাই স্কেল হয়ে স্ক্রিনে ফিট হবে
          Image.asset(
            'assets/image/splash_banner.jpg',
            width: size.width,
            height: size.height,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stackTrace) {
              // asset load fail করলে console এ exact কারণ প্রিন্ট হবে,
              // আর ডার্ক ব্যাকগ্রাউন্ডেও স্পষ্ট বোঝা যাবে যে ইমেজ লোড হয়নি
              debugPrint('Splash banner load failed: $error');
              return Container(
                color: AppTheme.surface,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_not_supported_outlined,
                          color: Colors.white54, size: 56),
                      SizedBox(height: 8),
                      Text('Banner not found',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),

          // ব্যানারের উপর হালকা অন্ধকার overlay, যাতে প্রগ্রেস/টেক্সট স্পষ্ট দেখা যায়
          Container(color: Colors.black.withOpacity(0.25)),

          // লোডিং বা এরর মেসেজ — স্ক্রিনের নিচের দিকে, বটাম সেন্টারে
          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.9),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading) ...[
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text('Loading...',
                          style: TextStyle(color: Colors.white60)),
                    ] else if (_errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        autofocus: true,
                        onPressed: _boot,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
