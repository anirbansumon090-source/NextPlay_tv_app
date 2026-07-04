// lib/presentation/screens/home_screen_widgets/home_top_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/tv_focus.dart';

class HomeTopBar extends StatelessWidget {
  final AppState appState;
  final FocusNode settingsFocusNode;
  final VoidCallback? onSettingsDown;

  const HomeTopBar({
    super.key,
    required this.appState,
    required this.settingsFocusNode,
    this.onSettingsDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          // ── App Logo ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Next Play',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),

          const Spacer(),

          // ── User badge ────────────────────────────────────────────
          if (appState.isAuthenticated && appState.userProfile != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Color(0xFFEAB308), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${appState.userProfile!.email.split('@').first}  •  ${appState.userProfile!.plan}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // ── Channel count ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.live_tv_rounded,
                    color: AppTheme.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${appState.channels.length} Channels',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Settings button ───────────────────────────────────────
          _TvSettingsButton(
            focusNode: settingsFocusNode,
            onTap: () => Navigator.pushNamed(context, '/settings'),
            onDown: onSettingsDown,
          ),
        ],
      ),
    );
  }
}

class _TvSettingsButton extends StatefulWidget {
  const _TvSettingsButton({
    required this.focusNode,
    required this.onTap,
    this.onDown,
  });
  final FocusNode focusNode;
  final VoidCallback onTap;
  final VoidCallback? onDown;

  @override
  State<_TvSettingsButton> createState() => _TvSettingsButtonState();
}

class _TvSettingsButtonState extends State<_TvSettingsButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Settings',
      child: TvFocus(
        focusNode: widget.focusNode,
        onFocusChange: (v) => setState(() => _focused = v),
        onActivate: widget.onTap,
        onKeyEvent: (e) {
          if (e is KeyDownEvent &&
              e.logicalKey == LogicalKeyboardKey.arrowDown) {
            widget.onDown?.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        builder: (context, focused) => GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _focused ? AppTheme.primary.withOpacity(0.2) : AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppTheme.primary : AppTheme.border,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1)
                    ]
                  : [],
            ),
            child: Icon(
              Icons.settings_rounded,
              color: _focused ? AppTheme.primary : Colors.white70,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
