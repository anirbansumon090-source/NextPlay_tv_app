// lib/presentation/screens/player_widgets/channel_list_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class ChannelListPanel extends StatefulWidget {
  const ChannelListPanel({
    super.key,
    required this.channels,
    required this.currentIndex,
    required this.onSettings,
    required this.onSelect,
    this.onActivity, // ✅ নতুন — ফোকাস/কী-অ্যাক্টিভিটি হলে parent কে জানাবে
  });

  final List channels;
  final int currentIndex;
  final VoidCallback onSettings;
  final ValueChanged<int> onSelect;
  final VoidCallback? onActivity; // ✅ নতুন

  @override
  State<ChannelListPanel> createState() => _ChannelListPanelState();
}

class _ChannelListPanelState extends State<ChannelListPanel> {
  final ScrollController _scrollController = ScrollController();
  late final List<FocusNode> _itemNodes;
  final FocusNode _settingsBtnNode = FocusNode(debugLabel: 'ch-list-settings');

  @override
  void initState() {
    super.initState();

    _itemNodes = List.generate(
      widget.channels.length,
      (i) => FocusNode(debugLabel: 'ch-list-item-$i'),
    );

    // ✅ যখনই কোনো item বা settings বাটনে ফোকাস যাবে (অর্থাৎ ইউজার
    // up/down চাপছে), parent-কে জানিয়ে auto-hide টাইমার রিসেট করানো হবে
    for (final node in _itemNodes) {
      node.addListener(_notifyActivity);
    }
    _settingsBtnNode.addListener(_notifyActivity);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusCurrentChannel();
    });
  }

  void _notifyActivity() {
    widget.onActivity?.call();
  }

  void _focusCurrentChannel() {
    if (!mounted || _itemNodes.isEmpty) return;

    final idx = widget.currentIndex.clamp(0, _itemNodes.length - 1);
    _itemNodes[idx].requestFocus();

    if (_scrollController.hasClients) {
      const itemHeight = 50.0;
      final targetOffset = (idx * itemHeight) - 150;
      final maxOffset = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxOffset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(ChannelListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusCurrentChannel();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final n in _itemNodes) {
      n.removeListener(_notifyActivity); // ✅ ক্লিনআপ
      n.dispose();
    }
    _settingsBtnNode.removeListener(_notifyActivity); // ✅ ক্লিনআপ
    _settingsBtnNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: FocusScope(
        node: FocusScopeNode(debugLabel: 'ch-list-panel-scope'),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.92),
              border: Border(
                left: BorderSide(
                  color: AppTheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.list_rounded,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Channel List',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      _SettingsFocusButton(
                        focusNode: _settingsBtnNode,
                        onSettings: widget.onSettings,
                        onDown: () {
                          if (_itemNodes.isNotEmpty) {
                            _itemNodes[0].requestFocus();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.channels.length,
                    itemBuilder: (ctx, i) {
                      final ch = widget.channels[i];
                      final isActive = i == widget.currentIndex;
                      if (i >= _itemNodes.length) {
                        return const SizedBox.shrink();
                      }

                      return _ChannelListItem(
                        focusNode: _itemNodes[i],
                        index: i,
                        channelName: ch.name,
                        isActive: isActive,
                        onSelect: () => widget.onSelect(i),
                        onKeyEvent: i == 0
                            ? (event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey ==
                                        LogicalKeyboardKey.arrowUp) {
                                  _settingsBtnNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                                return KeyEventResult.ignored;
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsFocusButton extends StatefulWidget {
  const _SettingsFocusButton({
    required this.focusNode,
    required this.onSettings,
    this.onDown,
  });

  final FocusNode focusNode;
  final VoidCallback onSettings;
  final VoidCallback? onDown;

  @override
  State<_SettingsFocusButton> createState() => _SettingsFocusButtonState();
}

class _SettingsFocusButtonState extends State<_SettingsFocusButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (v) => setState(() => _focused = v),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select) {
          widget.onSettings();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          widget.onDown?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color:
              _focused ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _focused ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: IconButton(
          icon: Icon(
            Icons.settings,
            color: _focused ? AppTheme.primary : Colors.white38,
            size: 18,
          ),
          onPressed: widget.onSettings,
        ),
      ),
    );
  }
}

class _ChannelListItem extends StatefulWidget {
  const _ChannelListItem({
    required this.focusNode,
    required this.index,
    required this.channelName,
    required this.isActive,
    required this.onSelect,
    this.onKeyEvent,
  });

  final FocusNode focusNode;
  final int index;
  final String channelName;
  final bool isActive;
  final VoidCallback onSelect;
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  @override
  State<_ChannelListItem> createState() => _ChannelListItemState();
}

class _ChannelListItemState extends State<_ChannelListItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _focused || widget.isActive;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (v) {
        setState(() => _focused = v);
        if (v) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.focusNode.context != null) {
              Scrollable.ensureVisible(
                widget.focusNode.context!,
                duration: const Duration(milliseconds: 200),
                alignment: 0.5,
              );
            }
          });
        }
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) {
          widget.onSelect();
          return KeyEventResult.handled;
        }

        return widget.onKeyEvent?.call(event) ?? KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _focused
                ? AppTheme.primary.withOpacity(0.25)
                : widget.isActive
                    ? AppTheme.primary.withOpacity(0.15)
                    : Colors.transparent,
            border: _focused
                ? const Border(
                    left: BorderSide(color: AppTheme.primary, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Text(
                '${widget.index + 1}'.padLeft(3),
                style: TextStyle(
                  color: highlighted ? AppTheme.primary : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.channelName,
                  style: TextStyle(
                    color: highlighted ? Colors.white : Colors.white60,
                    fontSize: 14,
                    fontWeight:
                        highlighted ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}