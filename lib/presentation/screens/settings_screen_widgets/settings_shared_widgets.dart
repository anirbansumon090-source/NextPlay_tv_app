// lib/presentation/screens/settings_screen_widgets/settings_shared_widgets.dart
// সব settings section এ ব্যবহার হওয়া shared widget গুলো

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/tv_focus.dart';
import '../../widgets/tv_focus_utils.dart';

/// Section শিরোনাম
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// ২ কলামের row (বা ১টি হলে stretched)
class SettingsTwoColRow extends StatelessWidget {
  const SettingsTwoColRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) {
      return SizedBox(
        height: 76,
        child: children.first,
      );
    }
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) const SizedBox(width: 14),
          ],
        ],
      ),
    );
  }
}

/// Focusable setting card — TV remote: OK activates, ← sidebar, Back pops screen.
class SettingCard extends StatefulWidget {
  const SettingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.focusNode,
    this.trailing,
    this.highlight = false,
    this.onReturnToSidebar,
    this.onScreenBack,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final Widget? trailing;
  final bool highlight;
  final VoidCallback? onReturnToSidebar;
  final VoidCallback? onScreenBack;

  @override
  State<SettingCard> createState() => _SettingCardState();
}

class _SettingCardState extends State<SettingCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || widget.highlight;
    return TvFocus(
      focusNode: widget.focusNode,
      onFocusChange: (v) => setState(() => _focused = v),
      onActivate: widget.onTap,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onReturnToSidebar?.call();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown &&
            widget.focusNode != null) {
          final scope = FocusScope.of(context);
          scope.nextFocus();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowUp &&
            widget.focusNode != null) {
          final scope = FocusScope.of(context);
          scope.previousFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      builder: (context, focused) => GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.card : const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? AppTheme.primary
                  : Colors.white.withOpacity(0.04),
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primary.withOpacity(0.15)
                      : const Color(0xFF0B0F19),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon,
                    color: active ? AppTheme.primary : Colors.white54,
                    size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              widget.trailing ??
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white24, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

/// TV-remote friendly dialog action button.
class TvDialogAction extends StatefulWidget {
  const TvDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.color,
    this.onLeft,
    this.onRight,
  });

  final String label;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? color;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  @override
  State<TvDialogAction> createState() => _TvDialogActionState();
}

class _TvDialogActionState extends State<TvDialogAction> {
  bool _focused = false;
  late final FocusNode _node =
      widget.focusNode ?? FocusNode(debugLabel: 'dialog-action');
  late DateTime _ignoreBackUntil;

  @override
  void initState() {
    super.initState();
    _ignoreBackUntil = DateTime.now().add(const Duration(milliseconds: 300));
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _node.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primary;
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (isTvBackKey(event)) {
          if (DateTime.now().isBefore(_ignoreBackUntil)) {
            return KeyEventResult.handled;
          }
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          widget.onLeft?.call();
          return widget.onLeft != null
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowRight) {
          widget.onRight?.call();
          return widget.onRight != null
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        return KeyEventResult.ignored;
      },
      child: TextButton(
        onPressed: widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor:
              _focused ? color.withOpacity(0.15) : Colors.transparent,
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _focused ? color : color.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
