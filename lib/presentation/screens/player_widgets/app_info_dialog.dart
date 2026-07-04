import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class AppInfoDialog extends StatefulWidget {
  const AppInfoDialog({super.key});

  @override
  State<AppInfoDialog> createState() => _AppInfoDialogState();
}

class _AppInfoDialogState extends State<AppInfoDialog> {
  final FocusNode _closeFocusNode = FocusNode(debugLabel: 'dialog-close-btn');
  bool _isCloseFocused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _closeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context, rootNavigator: true).pop();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // ← Back key দিয়ে dismiss হবে না, শুধু Close বাটনে হবে
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        
      },
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_rounded, color: AppTheme.primary),
            SizedBox(width: 10),
            Text(
              'App Info',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── অ্যাপ নাম ও ভার্সন ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'LTV Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.1',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── কোম্পানি ও ডেভেলপার তথ্য ───────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Company:',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11)),
                    SizedBox(height: 2),
                    Text(
                      'Ltv digital Limited',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    Text('Developer:',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11)),
                    SizedBox(height: 2),
                    Text(
                      'AnirbanSumon',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Powered by ──────────────────────────────────────────
              Center(
                child: Text(
                  'Powered by OTTKING',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.only(bottom: 16, right: 16),
        actions: [
          Focus(
            focusNode: _closeFocusNode,
            onFocusChange: (hasFocus) =>
                setState(() => _isCloseFocused = hasFocus),
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final key = event.logicalKey;

              // OK / Enter / Select → close
              if (key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.select ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.space) {
                _close();
                return KeyEventResult.handled;
              }

              // Back / Escape → আটকে রাখো, dialog বন্ধ হবে না
              if (key == LogicalKeyboardKey.goBack ||
                  key == LogicalKeyboardKey.escape ||
                  key == LogicalKeyboardKey.browserBack) {
                return KeyEventResult.handled; // consume, কিছু করবে না
              }

              return KeyEventResult.ignored;
            },
            child: GestureDetector(
              onTap: _close,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _isCloseFocused
                      ? AppTheme.primary.withOpacity(0.25)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isCloseFocused
                        ? AppTheme.primary
                        : Colors.white24,
                    width: _isCloseFocused ? 2 : 1,
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color:
                        _isCloseFocused ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}