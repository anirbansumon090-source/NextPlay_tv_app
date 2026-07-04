// lib/presentation/screens/settings_screen_widgets/settings_status_footer.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';

class SettingsStatusFooter extends StatelessWidget {
  const SettingsStatusFooter({super.key, required this.appState});
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          _Badge(
            icon: Icons.connected_tv_rounded,
            label: 'Smart TV Mode',
            color: AppTheme.primary,
          ),
          const SizedBox(width: 24),
          _Badge(
            icon: appState.errorMessage.isEmpty
                ? Icons.cloud_done_rounded
                : Icons.warning_amber_rounded,
            label: appState.errorMessage.isEmpty
                ? 'API Connected'
                : 'API Problem',
            color: appState.errorMessage.isEmpty
                ? AppTheme.primary
                : Colors.redAccent,
          ),
          const SizedBox(width: 24),
          _Badge(
            icon: Icons.live_tv_rounded,
            label: '${appState.channels.length} Channels',
            color: Colors.white54,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
