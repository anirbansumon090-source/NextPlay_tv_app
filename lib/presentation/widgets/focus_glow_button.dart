// lib/presentation/widgets/focus_glow_button.dart
// ✅ FIXED — ADDED FOCUSNODE FOR TV REMOTE NAVIGATION COMPATIBILITY

import 'package:flutter/material.dart';

class FocusGlowButton extends StatefulWidget {
  const FocusGlowButton({
    super.key,
    required this.label,
    required this.icon, 
    required this.onTap,
    this.focusNode, // 👈 ১. এখানে focusNode প্যারামিটার যুক্ত করা হয়েছে
    this.trailing,
    this.selected = false,
    this.isTV = false,
  });

  final String label;
  final dynamic icon; 
  final VoidCallback onTap;
  final FocusNode? focusNode; // 👈 ২. ভ্যারিয়েবল ডিক্লেয়ার করা হয়েছে
  final Widget? trailing;
  final bool selected;
  final bool isTV;

  @override
  State<FocusGlowButton> createState() => _FocusGlowButtonState();
}

class _FocusGlowButtonState extends State<FocusGlowButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = widget.selected || _focused;

    // লোগো ইমেজ বা আইকন সাইজিং এবং শেপ
    Widget logoWidget;
    if (widget.icon is Widget) {
      logoWidget = Container(
        width: widget.isTV ? 48 : 56,
        height: widget.isTV ? 48 : 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
            )
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: widget.icon as Widget,
        ),
      );
    } else {
      logoWidget = Icon(
        widget.icon is IconData ? widget.icon as IconData : Icons.play_circle_outline, 
        color: theme.colorScheme.primary,
        size: widget.isTV ? 32 : 40,
      );
    }

    return Focus(
      focusNode: widget.focusNode, // 👈 ৩. প্যারামিটার থেকে আসা নোডটি এখানে লিঙ্ক করা হয়েছে
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary.withAlpha(26)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: active
                  ? const Color(0xFF06B6D4)
                  : Colors.white.withAlpha(15),
              width: active ? 2.5 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withAlpha(100),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: widget.isTV
                    ? Row(
                        children: [
                          logoWidget,
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.trailing != null) widget.trailing!,
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          logoWidget,
                          const SizedBox(height: 12),
                          Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.trailing != null) widget.trailing!,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
