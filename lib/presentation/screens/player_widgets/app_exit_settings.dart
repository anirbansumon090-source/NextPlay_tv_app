import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';

class AppExitHandler {
  static Future<bool> confirmExit(
    BuildContext context, {
    String title = 'Exit App',
    String message = 'Do you want to exit the app?',
  }) async {
    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => _ExitConfirmDialog(title: title, message: message),
    );
    return result == true;
  }

  // Home screen থেকে back press → app exit confirm
  static Future<void> handleHomeExit(BuildContext context) async {
    if (!context.mounted) return;
    final confirmed = await confirmExit(
      context,
      title: 'Exit App',
      message: 'Do you want to exit OTTKing?',
    );
    if (confirmed && context.mounted) {
      await SystemNavigator.pop();
    }
  }

  static Future<void> handleExit({
    required BuildContext context,
    required AppState appState,
    required VoidCallback onBeforeDispose,
    required bool cameFromHome,
    VoidCallback? onCancelled,
  }) async {
    if (!context.mounted) return;

    final bootToPlayer = appState.isPlayerBootEnabled;

    // ✅ FIX: bootToPlayer = OFF এবং home থেকে এসেছে →
    // dialog ছাড়াই সরাসরি home-এ ফিরে যাও।
    // "Leave Player" dialog দেখানোর কোনো মানে নেই কারণ
    // ব্যবহারকারী home থেকেই এসেছে — back মানে home-এ ফেরা।
    if (!bootToPlayer && cameFromHome) {
      onBeforeDispose();
      try {
        await WakelockPlus.disable();
      } catch (_) {}
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // bootToPlayer = ON → exit confirm dialog
    // bootToPlayer = OFF কিন্তু home থেকে আসেনি → exit confirm
    final confirmed = await confirmExit(
      context,
      title: bootToPlayer ? 'Exit App' : 'Exit App',
      message: bootToPlayer
          ? 'Do you want to exit the app completely?'
          : 'Do you want to exit the app?',
    );

    if (!confirmed) {
      onCancelled?.call();
      return;
    }

    if (!context.mounted) return;
    onBeforeDispose();

    try {
      await WakelockPlus.disable();
    } catch (_) {}

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    if (bootToPlayer) {
      exit(0);
    } else if (context.mounted) {
      if (cameFromHome) {
        Navigator.of(context).pop();
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}

// ── Exit confirm dialog ────────────────────────────────────────────────────
class _ExitConfirmDialog extends StatefulWidget {
  const _ExitConfirmDialog({
    this.title = 'Exit App',
    this.message = 'Do you want to exit the app completely?',
  });

  final String title;
  final String message;

  @override
  State<_ExitConfirmDialog> createState() => _ExitConfirmDialogState();
}

class _ExitConfirmDialogState extends State<_ExitConfirmDialog> {
  final FocusNode _noNode = FocusNode(debugLabel: 'exit-no');
  final FocusNode _yesNode = FocusNode(debugLabel: 'exit-yes');
  late DateTime _ignoreBackUntil;

  @override
  void initState() {
    super.initState();
    _ignoreBackUntil =
        DateTime.now().add(const Duration(milliseconds: 400));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _noNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _noNode.dispose();
    _yesNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          widget.message,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          _DialogButton(
            focusNode: _noNode,
            label: 'No',
            color: Colors.white54,
            ignoreBackUntil: _ignoreBackUntil,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            onRight: () => _yesNode.requestFocus(),
          ),
          _DialogButton(
            focusNode: _yesNode,
            label: 'Yes',
            color: AppTheme.primary,
            ignoreBackUntil: _ignoreBackUntil,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            onLeft: () => _noNode.requestFocus(),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  const _DialogButton({
    required this.focusNode,
    required this.label,
    required this.color,
    required this.onPressed,
    this.ignoreBackUntil,
    this.onLeft,
    this.onRight,
  });

  final FocusNode focusNode;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final DateTime? ignoreBackUntil;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.space ||
            key == LogicalKeyboardKey.numpadEnter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }

        if (key == LogicalKeyboardKey.arrowLeft) {
          widget.onLeft?.call();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          widget.onRight?.call();
          return KeyEventResult.handled;
        }

        if (key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.browserBack) {
          final until = widget.ignoreBackUntil;
          if (until != null && DateTime.now().isBefore(until)) {
            return KeyEventResult.handled;
          }
          Navigator.of(context, rootNavigator: true).pop(false);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _focused
              ? widget.color.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focused ? widget.color : Colors.white24,
            width: _focused ? 2 : 1,
          ),
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              widget.label,
              style: TextStyle(
                color: _focused ? Colors.white : widget.color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Player Settings Dialog ─────────────────────────────────────────────────
class PlayerSettingsDialog extends StatefulWidget {
  const PlayerSettingsDialog({
    super.key,
    required this.state,
    required this.onAppInfo,
    required this.onNavigateSettings,
    required this.onClose,
  });

  final AppState state;
  final VoidCallback onAppInfo;
  final VoidCallback onNavigateSettings;
  final VoidCallback onClose;

  @override
  State<PlayerSettingsDialog> createState() => _PlayerSettingsDialogState();
}

class _PlayerSettingsDialogState extends State<PlayerSettingsDialog> {
  final List<FocusNode> _nodes = [];
  int _focusedIndex = 0;

  int get _itemCount {
    int count = 1; // boot player toggle
    if (widget.state.isAuthenticated) count++; // user info
    count++; // app info
    count++; // open settings
    count++; // close
    return count;
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _itemCount; i++) {
      _nodes.add(FocusNode(debugLabel: 'ps-$i'));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nodes.isNotEmpty) _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int dir) {
    if (_nodes.isEmpty) return;
    final next = (_focusedIndex + dir).clamp(0, _nodes.length - 1);
    setState(() => _focusedIndex = next);
    _nodes[next].requestFocus();
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      _moveFocus(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      _moveFocus(-1);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Widget _item({
    required int idx,
    required Widget child,
    required VoidCallback onActivate,
  }) {
    final focused = _focusedIndex == idx;
    return Focus(
      focusNode: _nodes[idx],
      onFocusChange: (v) {
        if (v) setState(() => _focusedIndex = idx);
      },
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.enter ||
                e.logicalKey == LogicalKeyboardKey.select ||
                e.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return _onKey(e);
      },
      child: GestureDetector(
        onTap: onActivate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: focused
                ? AppTheme.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focused ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    int vi = 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.white),
            Spacer(),
            Text('Settings', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _item(
              idx: vi++,
              onActivate: () => state.togglePlayerBoot(),
              child: SwitchListTile(
                title: const Text('Boot Player',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  'App will open live TV directly when launched',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12),
                ),
                activeColor: AppTheme.primary,
                value: state.isPlayerBootEnabled,
                onChanged: (v) => state.togglePlayerBoot(),
              ),
            ),
            if (state.isAuthenticated)
              _item(
                idx: vi++,
                onActivate: () {},
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ListTile(
                    leading: const Icon(Icons.stars_rounded,
                        color: Color(0xFFEAB308)),
                    title: Text(
                      state.userProfile?.email ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Package: ${state.userProfile?.plan ?? ''}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 9),
                    ),
                  ),
                ),
              ),
            const Divider(color: Colors.white12, height: 20),
            _item(
              idx: vi++,
              onActivate: widget.onAppInfo,
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded,
                    color: AppTheme.primary),
                title: const Text('App Info',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Version and Developer Information',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          _item(
            idx: vi++,
            onActivate: widget.onNavigateSettings,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Settings',
                  style: TextStyle(color: Colors.white54)),
            ),
          ),
          _item(
            idx: vi++,
            onActivate: widget.onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
