import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tv_focus_utils.dart';

typedef TvFocusBuilder = Widget Function(BuildContext context, bool isFocused);

class TvFocus extends StatefulWidget {
  const TvFocus({
    super.key,
    this.focusNode,
    this.autofocus = false,
    this.skipTraversal = false,
    this.onFocusChange,
    this.onKeyEvent,
    this.onActivate,
    this.onBack,
    required this.builder,
  });

  final FocusNode? focusNode;
  final bool autofocus;
  final bool skipTraversal;
  final ValueChanged<bool>? onFocusChange;
  // ✅ onKeyEvent — activate/back এর পরে extra key handling (যেমন arrowLeft)
  final KeyEventResult Function(KeyEvent)? onKeyEvent;
  final VoidCallback? onActivate;
  final VoidCallback? onBack;
  final TvFocusBuilder builder;

  @override
  State<TvFocus> createState() => _TvFocusState();
}

class _TvFocusState extends State<TvFocus> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      skipTraversal: widget.skipTraversal,
      onFocusChange: (v) {
        setState(() => _focused = v);
        widget.onFocusChange?.call(v);
      },
      onKeyEvent: (_, event) {
        // ১. activate key (enter/select/ok)
        if (widget.onActivate != null && isTvActivateKey(event)) {
          return handleTvActivate(event, widget.onActivate!);
        }
        // ২. back key
        if (widget.onBack != null && isTvBackKey(event)) {
          return handleTvBack(event, widget.onBack!);
        }
        // ৩. extra key handler (যেমন arrowLeft → sidebar)
        //
        // আগে widget.onKeyEvent == null হলে এই handler
        // KeyEventResult.skipRemainingHandlers রিটার্ন করতো — যার অর্থ
        // event আর কখনো ancestor widget-এ bubble করতো না, একদম silently
        // আটকে যেতো। এখন onKeyEvent না থাকলে (বা সেটা নিজে ignored
        // রিটার্ন করলে) আমরা ignored রিটার্ন করি, যাতে event সবসময়
        // ঠিকভাবে parent FocusNode-এ পৌঁছাতে পারে।
        if (widget.onKeyEvent != null) {
          return widget.onKeyEvent!(event);
        }
        return KeyEventResult.ignored;
      },
      child: widget.builder(context, _focused),
    );
  }
}
