// lib/presentation/screens/settings_screen_widgets/settings_system_section.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';

class SettingsSystemSection extends StatelessWidget {
  const SettingsSystemSection({
    super.key,
    required this.appState,
    required this.cardFocusNodes,
    required this.onReturnToSidebar,
    required this.onScreenBack,
  });
  final AppState appState;
  final List<FocusNode> cardFocusNodes;
  final VoidCallback onReturnToSidebar;
  final VoidCallback onScreenBack;

  void _refreshCatalog(BuildContext context) {
    appState.loadCatalog();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Channel list is updating...'),
        backgroundColor: AppTheme.card,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Checking for new updates...'),
        backgroundColor: AppTheme.card,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SYSTEM'),
        const SizedBox(height: 16),

        // ── প্রথম লাইন (কার্ড ১ এবং কার্ড ২) ──────────────────────────────────
        SettingsTwoColRow(
          children: [
            // ── ১. ক্যাটালগ রিফ্রেশ ──────────────────────────────────────────
            SettingCard(
              focusNode: cardFocusNodes.isNotEmpty ? cardFocusNodes[0] : null,
              icon: Icons.sync_rounded,
              title: 'Catalog Refresh',
              subtitle: 'Update channel list',
              onReturnToSidebar: onReturnToSidebar,
              onScreenBack: onScreenBack,
              onTap: () => _refreshCatalog(context),
            ),
            SettingCard(
              focusNode: cardFocusNodes.length > 1 ? cardFocusNodes[1] : null,
              icon: Icons.system_update_rounded,
              title: 'App Update',
              subtitle: 'Check for new version',
              onReturnToSidebar: onReturnToSidebar,
              onScreenBack: onScreenBack,
              onTap: () => _checkForUpdates(context),
            ),
          ],
        ),

        const SizedBox(height: 16), // দুই লাইনের মাঝে স্ট্যান্ডার্ড গ্যাপ

        // ── দ্বিতীয় লাইন (কার্ড ৩ এবং কার্ড ৪) ─────────────────────────────────
        SettingsTwoColRow(
          children: [
            // ── ৩. ডেভেলপার ────────────────────────────────────────────────
            SettingCard(
              focusNode: cardFocusNodes.length > 2 ? cardFocusNodes[2] : null,
              icon: Icons.code_rounded,
              title: 'Developer',
              subtitle: 'App development & Support',
              onReturnToSidebar: onReturnToSidebar,
              onScreenBack: onScreenBack,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const _DeveloperDialog(),
              ),
            ),
            SettingCard(
              focusNode: cardFocusNodes.length > 3 ? cardFocusNodes[3] : null,
              icon: Icons.info_outline_rounded,
              title: 'App Information',
              subtitle: 'Version and system information',
              onReturnToSidebar: onReturnToSidebar,
              onScreenBack: onScreenBack,
              onTap: () => showDialog(
                context: context,
                builder: (_) => const _AppInfoDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── ৩. Developer Dialog ──────────────────────────────────────────────────────

class _DeveloperDialog extends StatelessWidget {
  const _DeveloperDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.person_rounded, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('Developer Information', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Main Developer and Project Architect:',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Anirban Sumon',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Full Stack Developer (IPTV & Mobile Systems)',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TvDialogAction(
          label: 'Close',
          autofocus: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

// ── ৪. App Info Dialog ───────────────────────────────────────────────────────

class _AppInfoDialog extends StatelessWidget {
  const _AppInfoDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.info_rounded, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('App Information', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NextPlay TV App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'All rights reserved.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TvDialogAction(
          label: 'Close',
          autofocus: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
