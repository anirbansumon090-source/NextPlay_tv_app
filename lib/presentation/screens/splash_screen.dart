// lib/presentation/screens/splash_screen.dart
// TV-only landscape splash. Boots to player if enabled & has channels.

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

    // Force landscape on every screen
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
                : 'Channel failed to load. Please check your internet connection and try again.';
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
      // Boot directly to last-played channel (already restored in loadCatalog)
      Navigator.pushNamedAndRemoveUntil(
          context, '/player', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, '/home', (route) => false);
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
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [
                AppTheme.primary.withOpacity(0.08),
                AppTheme.surface,
              ],
            ),
          ),
          child: Row(
            children: [
              // Left decorative bar
              Container(
                width: 6,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primary.withOpacity(0.0),
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              // Center content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, child) => Transform.scale(
                          scale: _isLoading ? 0.96 + _pulse.value * 0.04 : 1.0,
                          child: child,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo ring
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.08),
                                border: Border.all(
                                  color: _isLoading
                                      ? AppTheme.primary
                                      : Colors.redAccent,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isLoading
                                            ? AppTheme.primary
                                            : Colors.redAccent)
                                        .withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isLoading
                                    ? Icons.live_tv_rounded
                                    : Icons.wifi_off_rounded,
                                size: 48,
                                color: _isLoading ? AppTheme.primary : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 24),
      
                            // App name
                            Text(
                              AppConstants.appName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                              textAlign: TextAlign.center,
                            ),
      
                            const SizedBox(height: 6),
                            Text(
                              AppConstants.appTagline,
                              style: TextStyle(
                                color: AppTheme.primary.withOpacity(0.8),
                                fontSize: 14,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
      
                            const SizedBox(height: 36),
      
                            if (_isLoading) ...[
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading channels...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ] else if (_errorMessage != null) ...[
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: size.width * 0.6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                autofocus: true, // রিমোটের ফোকাস অটোমেটিক বাটনে চলে আসবে
                                onPressed: _boot,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.black, // টেক্সট কালার আরও ক্লিয়ার করা হলো
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                label: const Text('Try Again'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
