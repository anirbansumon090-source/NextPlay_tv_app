// lib/presentation/widgets/tv_focus_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'tv_focus.dart';

class TvFocusCard extends StatefulWidget {
  const TvFocusCard({
    super.key,
    required this.onTap,
    required this.child,
    this.focusNode,
    this.onFocusChange,
    this.onBack,
    // ✅ onKeyEvent যোগ করা হলো — channel card-এ arrowLeft intercept করতে
    this.onKeyEvent,
    this.selected = false,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 14.0,
  });

  final VoidCallback onTap;
  final Widget child;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;
  final VoidCallback? onBack;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  State<TvFocusCard> createState() => _TvFocusCardState();
}

class _TvFocusCardState extends State<TvFocusCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || widget.selected;

    return AnimatedScale(
      scale: _focused ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: TvFocus(
        focusNode: widget.focusNode,
        onFocusChange: (v) {
          setState(() => _focused = v);
          widget.onFocusChange?.call(v);
        },
        onActivate: widget.onTap,
        onBack: widget.onBack,
        onKeyEvent: widget.onKeyEvent,
        builder: (context, focused) => GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _focused ? AppTheme.cardLight : AppTheme.card,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: active ? AppTheme.primary : AppTheme.border,
                width: active ? 2.5 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
