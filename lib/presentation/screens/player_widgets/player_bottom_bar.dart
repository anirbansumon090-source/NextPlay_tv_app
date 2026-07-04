// lib/presentation/screens/player_widgets/player_bottom_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_theme.dart';

class PlayerBottomBar extends StatefulWidget {
  const PlayerBottomBar({
    super.key,
    required this.ctrl,
    required this.isLive,
    required this.liveBlink,
    required this.onPlayPause,
    required this.onExit,
    required this.onChannelUp,   
    required this.onChannelDown, 
  });

  final VideoPlayerController ctrl;
  final bool isLive;
  final bool liveBlink;
  final VoidCallback onPlayPause;
  final VoidCallback onExit;
  final VoidCallback onChannelUp;  
  final VoidCallback onChannelDown;

  @override
  State<PlayerBottomBar> createState() => _PlayerBottomBarState();
}

class _PlayerBottomBarState extends State<PlayerBottomBar> {
  final FocusNode _playPauseNode = FocusNode(debugLabel: 'bar-playpause');
  
  // শুরুতে এটি false থাকবে। রিমোট দিয়ে সিলেক্ট করলেই কেবল true হবে।
  bool _isFocused = false; 

  @override
  void initState() {
    super.initState();
    // স্ক্রিন ওপেন হওয়ার সাথে সাথে বাটনটি রিমোটের ফোকাস পাওয়ার জন্য রেডি হবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playPauseNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _playPauseNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // চ্যানেল আপ/ডাউন কি হ্যান্ডেলিং
    if (event.logicalKey == LogicalKeyboardKey.channelUp ||
        event.logicalKey == LogicalKeyboardKey.pageUp) {
      widget.onChannelUp();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.channelDown ||
        event.logicalKey == LogicalKeyboardKey.pageDown) {
      widget.onChannelDown();
      return KeyEventResult.handled;
    }

    // ফোকাসড থাকা অবস্থায় রিমোটের OK/Enter চাপলে প্লে-পজ হবে
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onPlayPause();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // ===== Play/Pause বোতাম (রিমোট ফোকাস লজিকসহ) =====
            Focus(
              focusNode: _playPauseNode,
              onFocusChange: (hasFocus) {
                // রিমোট দিয়ে যখনই এই বাটনে আসা হবে, তখনই কেবল স্টেট আপডেট হবে
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              onKeyEvent: (_, event) => _handleKey(event),
              child: GestureDetector(
                onTap: widget.onPlayPause,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(6), // আইকনের চারপাশের প্যাডিং
                  decoration: BoxDecoration(
                    // ফোকাস হলে থিম কালার ব্যাকগ্রাউন্ড পাবে, না হলে একদম নরমাল (Transparent)
                    color: _isFocused
                        ? AppTheme.primary.withOpacity(0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50), // গোল ফোকাস ইফেক্ট এর জন্য
                    border: Border.all(
                      // ফোকাস হলে বর্ডার জ্বলজ্বল করবে, না হলে বর্ডার থাকবে না
                      color: _isFocused ? AppTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.ctrl.value.isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    // ফোকাসড অবস্থায় আইকনটি আরও উজ্জ্বল দেখাবে
                    color: _isFocused ? Colors.white : Colors.white70,
                    size: 40, // টিভির জন্য স্ট্যান্ডার্ড বড় সাইজ
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ===== LIVE ব্লিংকিং ব্যাজ =====
            if (widget.isLive && widget.ctrl.value.isPlaying)
              AnimatedOpacity(
                opacity: widget.liveBlink ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 3,
                        backgroundColor: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
