import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/tv_focus.dart';

class CategorySidebar extends StatefulWidget {
  const CategorySidebar({
    super.key,
    required this.cats,
    required this.catNodes,
    required this.selectedIndex,
    required this.onSelect,
    this.onMoveRight,
    this.channelCount = 0,
  });

  final List<Map<String, String>> cats;
  final List<FocusNode> catNodes;
  final int selectedIndex;

  /// Enter/OK চাপলে সেই ক্যাটাগরি select করে grid-এ focus দাও
  final ValueChanged<int> onSelect;

  /// ➡️ চাপলে grid-এ focus দাও (currently selected category)
  final VoidCallback? onMoveRight;

  /// বর্তমান selected ক্যাটাগরিতে কতটি চ্যানেল আছে
  final int channelCount;

  @override
  State<CategorySidebar> createState() => _CategorySidebarState();
}

class _CategorySidebarState extends State<CategorySidebar> {
  final ScrollController _scrollController = ScrollController();
  static const double _itemExtent = CategoryItem.height;

  void _scrollToItem(int index) {
    if (!_scrollController.hasClients) return;
    final target = index * _itemExtent;
    final maxOffset = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant CategorySidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToItem(widget.selectedIndex);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            'CATEGORIES',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.cats.length,
            physics: const ClampingScrollPhysics(),
            itemExtent: _itemExtent,
            cacheExtent: 300,
            itemBuilder: (context, i) {
              final cat = widget.cats[i];
              final isSelected = widget.selectedIndex == i;

              // Selected category তে channelCount দিয়ে check করো,
              // অন্য category তে আমরা জানি না — সেগুলোকে enabled রাখো
              final hasChannels = !isSelected || widget.channelCount > 0;

              return CategoryItem(
                focusNode: widget.catNodes[i],
                icon: cat['icon']!,
                name: cat['name']!,
                selected: isSelected,
                hasChannels: hasChannels,
                // Enter/OK → grid-এ যাও
                onActivate: () => widget.onSelect(i),
                // ➡️ key → শুধু current selected category তে কাজ করে
                onMoveRight: (isSelected && hasChannels)
                    ? widget.onMoveRight
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class CategoryItem extends StatefulWidget {
  const CategoryItem({
    super.key,
    required this.focusNode,
    required this.icon,
    required this.name,
    required this.selected,
    required this.onActivate,
    this.onMoveRight,
    this.hasChannels = true,
  });

  static const double height = 48.0;

  final FocusNode focusNode;
  final String icon;
  final String name;
  final bool selected;
  final bool hasChannels;

  /// Enter/OK চাপলে এটা call হয়
  final VoidCallback onActivate;

  /// ➡️ চাপলে এটা call হয় (null হলে ➡️ কাজ করবে না)
  final VoidCallback? onMoveRight;

  @override
  State<CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<CategoryItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || widget.selected;

    return SizedBox(
      height: CategoryItem.height,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: TvFocus(
          focusNode: widget.focusNode,
          onFocusChange: (v) => setState(() => _focused = v),
          // Enter/OK → onActivate (grid-এ যাও)
          onActivate: widget.onActivate,
          // arrowRight key এখন এখানে handle করি না। আগে এখানে local
          // interception ছিল (widget.onMoveRight, যা widget.selectedIndex
          // prop-এর উপর নির্ভরশীল ছিল) — কিন্তু rebuild timing-এর কারণে
          // এই local prop আর HomeScreen-এর আসল _selectedCatIndex মাঝে মাঝে
          // এক frame এর জন্য async ভাবে আলাদা থেকে যেতো, ফলে কোনো কোনো
          // category-তে ➡ কাজ করতো না। এখন event সবসময় ignored রিটার্ন
          // করে bubble করে HomeScreen-এর central _handleSidebarKey-এ যায়,
          // যেটাই একমাত্র source of truth — তাই সব category-তে সমানভাবে
          // কাজ করবে।
          onKeyEvent: null,
          builder: (context, focused) => GestureDetector(
            onTap: widget.onActivate,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: _focused
                    ? AppTheme.primary
                    : widget.selected
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? AppTheme.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: !widget.hasChannels
                        ? Colors.white12
                        : active
                            ? Colors.white70
                            : Colors.white24,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
