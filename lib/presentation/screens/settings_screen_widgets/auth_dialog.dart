import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_state.dart';
import 'settings_shared_widgets.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isRegister = false;
  bool _loading = false;

  final _email = TextEditingController();
  final _pass = TextEditingController();

  final _emailFocus = FocusNode(debugLabel: 'auth-email');
  final _passFocus = FocusNode(debugLabel: 'auth-pass');
  final _toggleFocus = FocusNode(debugLabel: 'auth-toggle');
  final _cancelFocus = FocusNode(debugLabel: 'auth-cancel');
  final _submitFocus = FocusNode(debugLabel: 'auth-submit');
  final _logoutFocus = FocusNode(debugLabel: 'auth-logout');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emailFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _toggleFocus.dispose();
    _cancelFocus.dispose();
    _submitFocus.dispose();
    _logoutFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState appState) async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) return;
    setState(() => _loading = true);
    _isRegister
        ? await appState.register(_email.text.trim(), _pass.text)
        : await appState.login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (appState.errorMessage.isEmpty) Navigator.pop(context);
  }

  // ── ফিল্ড "nav mode" এ থাকলে (editing চলছে না) এই keys হ্যান্ডেল হবে ──
  KeyEventResult _onFieldNavKey(
    KeyEvent event, {
    FocusNode? prevNode,
    FocusNode? nextNode,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (prevNode != null) {
        prevNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.tab) {
      if (nextNode != null) {
        nextNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAuth = appState.isAuthenticated;

    return AlertDialog(
      backgroundColor: const Color(0xFF131B2E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isRegister ? 'Create Account' : 'Sign In',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Email ────────────────────────────────────────────────
            _Field(
              ctrl: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              focusNode: _emailFocus,
              onNavKey: (e) => _onFieldNavKey(
                e,
                prevNode: null,
                nextNode: _passFocus,
              ),
            ),
            const SizedBox(height: 16),

            // ── Password ─────────────────────────────────────────────
            _Field(
              ctrl: _pass,
              label: 'Password',
              icon: Icons.lock_outline,
              obscure: true,
              focusNode: _passFocus,
              onNavKey: (e) => _onFieldNavKey(
                e,
                prevNode: _emailFocus,
                nextNode: _toggleFocus,
              ),
            ),
            const SizedBox(height: 12),

            // ── Toggle ───────────────────────────────────────────────
            _NavItem(
              focusNode: _toggleFocus,
              onActivate: () =>
                  setState(() => _isRegister = !_isRegister),
              onUp: () => _passFocus.requestFocus(),
              onDown: () => isAuth
                  ? _logoutFocus.requestFocus()
                  : _cancelFocus.requestFocus(),
              child: Text(
                _isRegister
                    ? 'Already have an account? Sign in'
                    : 'Create a new account',
                style:
                    const TextStyle(color: AppTheme.primary, fontSize: 13),
              ),
            ),

            if (appState.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  appState.errorMessage,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAuth)
              _NavItem(
                focusNode: _logoutFocus,
                onActivate: () {
                  appState.logout();
                  Navigator.pop(context);
                },
                onUp: () => _toggleFocus.requestFocus(),
                onRight: () => _cancelFocus.requestFocus(),
                child: const Text('Logout',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            _NavItem(
              focusNode: _cancelFocus,
              onActivate: () => Navigator.pop(context),
              onUp: () => _toggleFocus.requestFocus(),
              onLeft: isAuth ? () => _logoutFocus.requestFocus() : null,
              onRight: () => _submitFocus.requestFocus(),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            _NavItem(
              focusNode: _submitFocus,
              onActivate: _loading ? null : () => _submit(appState),
              onUp: () => _passFocus.requestFocus(),
              onLeft: () => _cancelFocus.requestFocus(),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary),
                    )
                  : Text(
                      _isRegister ? 'Register' : 'Sign In',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Focus-aware TextField with explicit nav/edit modes ──────────────────
//
// মূল আইডিয়া:
//  - "nav mode" (default): ফিল্ড focused দেখাবে (border highlight) কিন্তু
//    keyboard/IME ওপেন হবে না, আর Up/Down/Tab/Escape সবই বাইরের
//    navigation handler এ যাবে।
//  - "edit mode": Enter/Select চাপলে ঢোকা যায়, তখন TextField আসলেই
//    readOnly:false হয়ে keyboard input নেয়।
//  - Edit mode এ Escape/Back চাপলে আমরা সেটা TextField কে consume
//    করতে দিই না — বরং নিজেরা আগেই intercept করে nav mode এ ফিরে যাই,
//    এবং focus node টা ধরে রাখি (focus হারায় না), যাতে এর পরে
//    up/down চাপলে আগের মতই ফিল্ড থেকে বের হয়ে অন্য আইটেমে যাওয়া যায়।
class _Field extends StatefulWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    required this.focusNode,
    required this.onNavKey,
    this.obscure = false,
  });

  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final FocusNode focusNode;

  /// শুধু nav mode-এ থাকা অবস্থায় navigation keys (↑↓ Tab Escape Back) এখানে আসবে
  final KeyEventResult Function(KeyEvent) onNavKey;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _focused = widget.focusNode.hasFocus;
      // ফোকাস হারালে edit mode থেকেও বের হয়ে যাও (পরিষ্কার state)
      if (!_focused) _editing = false;
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (!_editing) {
      // ── NAV MODE ──────────────────────────────────────────────
      // Enter/Select চাপলে edit mode-এ ঢোকো
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.numpadEnter) {
        setState(() => _editing = true);
        return KeyEventResult.handled;
      }
      // বাকি navigation keys বাইরের handler-কে দাও
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.tab ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack) {
        return widget.onNavKey(event);
      }
      return KeyEventResult.ignored;
    } else {
      // ── EDIT MODE ─────────────────────────────────────────────
      // Escape/Back: TextField পর্যন্ত পৌঁছানোর আগেই আটকে দিয়ে
      // nav mode-এ ফিরো। focus node ধরেই রাখা হচ্ছে।
      if (key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.goBack) {
        setState(() => _editing = false);
        return KeyEventResult.handled;
      }
      // অন্য সব কিছু (letters, backspace, arrows-within-text ইত্যাদি)
      // স্বাভাবিকভাবে TextField-এ যাক — তাই ignored.
      return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // nav mode-এ আমরা চাই এই node-টাই key events আগে পাক (TextField-এর
      // ডিফল্ট nav handling override করতে), তাই canRequestFocus true রেখে
      // skipTraversal করছি যাতে এই wrapper আলাদা ভাবে focus না নেয়—
      // আসল focus থাকবে widget.focusNode (নিচের TextField-এ)।
      canRequestFocus: false,
      onKeyEvent: _handleKey,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focused
                ? (_editing
                    ? AppTheme.primary
                    : AppTheme.primary.withOpacity(0.6))
                : Colors.white.withOpacity(0.1),
            width: _focused ? 1.5 : 1,
          ),
          // nav mode-এ থাকা অবস্থায় subtle fill দিয়ে বোঝানো যে এটাই
          // বর্তমান remote-selection, কিন্তু এখনো editing শুরু হয়নি।
          color: _focused && !_editing
              ? AppTheme.primary.withOpacity(0.06)
              : null,
        ),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: widget.ctrl,
              focusNode: widget.focusNode,
              obscureText: widget.obscure,
              // edit mode না হলে input/keyboard disable — IME পপ-আপ
              // এবং internal key consumption দুটোই বন্ধ থাকে।
              readOnly: !_editing,
              showCursor: _editing,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.next,
              keyboardType: widget.obscure
                  ? TextInputType.visiblePassword
                  : TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: const TextStyle(color: Colors.white38),
                prefixIcon: Icon(widget.icon, color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            if (_focused && !_editing)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_return,
                  size: 16,
                  color: Colors.white38,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── TV remote navigable button/item ───────────────────────────────────────
class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.focusNode,
    required this.child,
    this.onActivate,
    this.onUp,
    this.onDown,
    this.onLeft,
    this.onRight,
  });

  final FocusNode focusNode;
  final Widget child;
  final VoidCallback? onActivate;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space) {
          widget.onActivate?.call();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp && widget.onUp != null) {
          widget.onUp!();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown && widget.onDown != null) {
          widget.onDown!();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft && widget.onLeft != null) {
          widget.onLeft!();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight && widget.onRight != null) {
          widget.onRight!();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.goBack) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onActivate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _focused
                ? AppTheme.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppTheme.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}