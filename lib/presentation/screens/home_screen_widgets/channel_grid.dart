import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel_model.dart';
import '../../providers/app_state.dart';
import '../../../presentation/widgets/tv_focus_card.dart';

class IndexedChannel {
  const IndexedChannel(this.channel, this.originalIndex);
  final ChannelModel channel;
  final int originalIndex;
}

class ChannelGrid extends StatefulWidget {
  const ChannelGrid({
    super.key,
    required this.channels,
    required this.chNodes,
    required this.appState,
    required this.categoryName,
    this.onFocusIndex,
    this.onMoveLeft,
  });

  final List<IndexedChannel> channels;
  final List<FocusNode> chNodes;
  final AppState appState;
  final String categoryName;

  /// চ্যানেলে focus গেলে index জানাও — HomeScreen _catIndexWhenGridFocused update করে
  final ValueChanged<int>? onFocusIndex;

  /// Grid বাম edge থেকে ⬅️ চাপলে sidebar-এ ফেরো
  final VoidCallback? onMoveLeft;

  @override
  State<ChannelGrid> createState() => _ChannelGridState();
}

class _ChannelGridState extends State<ChannelGrid> {
  final ScrollController _scrollController = ScrollController();

  // কলাম সংখ্যা এখানে ও gridDelegate এ একই হতে হবে
  static const int _crossAxisCount = 5;

  void _focusGridIndex(int index, {int retries = 3}) {
    final total = widget.chNodes.length;
    if (index < 0 || index >= total) return;
    final node = widget.chNodes[index];
    if (node.context != null && node.canRequestFocus) {
      node.requestFocus();
      return;
    }
    // GridView lazy-build এর কারণে node এখনো build হয়নি — পরের frame-এ
    // আবার চেষ্টা করো, চুপচাপ fail করো না (নাহলে arrowRight/Left/Up/Down
    // মাঝে মাঝে অকার্যকর মনে হয়)।
    if (retries <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusGridIndex(index, retries: retries - 1);
    });
  }

  KeyEventResult _handleGridKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final total = widget.channels.length;
    if (total == 0) return KeyEventResult.ignored;

    // Defensive: index কখনো out-of-range হলে (stale callback ইত্যাদির
    // কারণে) ক্র্যাশ না করে নিরাপদে handled রিটার্ন করি।
    if (index < 0 || index >= total) return KeyEventResult.handled;

    final col = index % _crossAxisCount;
    final row = index ~/ _crossAxisCount;
    final totalRows = (total + _crossAxisCount - 1) ~/ _crossAxisCount;
    final lastColInRow = row == totalRows - 1
        ? (total - 1) % _crossAxisCount
        : _crossAxisCount - 1;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (col == 0) {
          // বাম edge → sidebar-এ ফিরে যাও
          widget.onMoveLeft?.call();
        } else {
          _focusGridIndex(index - 1);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
        if (col < lastColInRow) {
          _focusGridIndex(index + 1);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowDown:
        final next = index + _crossAxisCount;
        if (next < total) {
          _focusGridIndex(next);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        if (row > 0) {
          _focusGridIndex(index - _crossAxisCount);
          return KeyEventResult.handled;
        }
        // প্রথম row তে up — focus বাইরে পাঠাও না, block করো
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  void didUpdateWidget(covariant ChannelGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Category বদলালে scroll reset ও stale focus unfocus
    if (oldWidget.categoryName != widget.categoryName) {
      for (final node in oldWidget.chNodes) {
        if (node.hasFocus) node.unfocus();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.chNodes.isNotEmpty && widget.chNodes.first.canRequestFocus) {
          widget.chNodes.first.requestFocus();
        }
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safety: chNodes আর channels এর length match নিশ্চিত করো
    final safeCount = widget.chNodes.length < widget.channels.length
        ? widget.chNodes.length
        : widget.channels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8, left: 4),
          child: Text(
            '${widget.categoryName} CHANNELS'.toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: widget.channels.isEmpty
              ? const Center(
                  child: Text(
                    'No channels available.',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(4),
                  cacheExtent: 600,
                  physics: const ClampingScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: safeCount,
                  itemBuilder: (context, i) {
                    final entry = widget.channels[i];
                    return _ChannelItem(
                      // ⚠️ আগে key ছিল database id দিয়ে
                      // (ValueKey('${categoryName}_${channel.id}')),
                      // কিন্তু focusNode আসতো position (i) থেকে — দুটো
                      // ভিন্ন identity scheme। ফলে category বদলালে
                      // filtered list-এর order বদলে গেলে (যেমন DB id ৪
                      // হঠাৎ position ০-এ চলে আসা), Flutter widget-কে
                      // নতুন content দিয়ে re-key করতো কিন্তু position-based
                      // FocusNode object same থেকে যেতো — node-এর focus
                      // state আর প্রদর্শিত content-এর sync নষ্ট হয়ে যেতো,
                      // ফলে focus হারিয়ে যাওয়া/ভুল জায়গায় যাওয়া দেখা দিতো।
                      //
                      // এখন key এবং FocusNode দুটোই position (i) ভিত্তিক —
                      // তাই identity সবসময় sync থাকবে, content যাই হোক।
                      key: ValueKey('${widget.categoryName}_pos_$i'),
                      channel: entry.channel,
                      originalIndex: entry.originalIndex,
                      focusNode: widget.chNodes[i],
                      appState: widget.appState,
                      gridIndex: i,
                      totalCount: safeCount,
                      crossAxisCount: _crossAxisCount,
                      onFocused: (idx) => widget.onFocusIndex?.call(idx),
                      onGridKeyEvent: (event) => _handleGridKey(i, event),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single channel card
// ─────────────────────────────────────────────────────────────────────────────
class _ChannelItem extends StatefulWidget {
  const _ChannelItem({
    super.key,
    required this.channel,
    required this.originalIndex,
    required this.gridIndex,
    required this.focusNode,
    required this.appState,
    required this.onFocused,
    required this.totalCount,
    required this.crossAxisCount,
    this.onGridKeyEvent,
  });

  final ChannelModel channel;
  final int originalIndex;
  final int gridIndex;
  final FocusNode focusNode;
  final AppState appState;
  final ValueChanged<int> onFocused;
  final int totalCount;
  final int crossAxisCount;
  final KeyEventResult Function(KeyEvent)? onGridKeyEvent;

  @override
  State<_ChannelItem> createState() => _ChannelItemState();
}

class _ChannelItemState extends State<_ChannelItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _ensureVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = widget.focusNode.context;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: 0.3,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final origIdx = widget.originalIndex;
    final playing = widget.appState.currentChannelIndex == origIdx;
    final isPremium = widget.channel.isPremium > 0;
    final isLocked = isPremium && !widget.appState.isAuthenticated;

    return RepaintBoundary(
      child: TvFocusCard(
        focusNode: widget.focusNode,
        selected: playing,
        padding: EdgeInsets.zero,
        onKeyEvent: widget.onGridKeyEvent,
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            widget.onFocused(widget.gridIndex);
            _ensureVisible();
          }
        },
        onTap: () {
          widget.appState.selectChannelByIndex(origIdx);
          Navigator.pushNamed(context, '/player', arguments: 'fromHome');
        },
        child: ChannelCard(
          channel: widget.channel,
          isPlaying: playing,
          isPremium: isPremium,
          isLocked: isLocked,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pure display card — focus logic নেই
// ─────────────────────────────────────────────────────────────────────────────
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.isPlaying,
    this.isPremium = false,
    this.isLocked = false,
  });

  final ChannelModel channel;
  final bool isPlaying;
  final bool isPremium;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppTheme.card,
            child: CachedNetworkImage(
              imageUrl: channel.logoUrl.trim(),
              fit: BoxFit.cover,
              memCacheWidth: 200,
              memCacheHeight: 120,
              fadeInDuration: const Duration(milliseconds: 150),
              fadeOutDuration: const Duration(milliseconds: 100),
              placeholder: (context, url) => const Center(
                child: Icon(Icons.live_tv_rounded,
                    color: Colors.white24, size: 32),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.live_tv_rounded,
                    color: Colors.white24, size: 32),
              ),
            ),
          ),
          if (isPremium)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.black87
                      : const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isLocked
                        ? Colors.white24
                        : const Color(0xFFFFF9C4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLocked
                          ? Icons.lock_rounded
                          : Icons.workspace_premium_rounded,
                      size: 9,
                      color: isLocked ? Colors.white54 : Colors.black87,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isLocked ? 'LOCK' : 'PRE',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        color: isLocked ? Colors.white54 : Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isLocked)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
              ),
            ),
        ],
      ),
    );
  }
}