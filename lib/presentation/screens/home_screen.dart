import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'home_screen_widgets/home_top_bar.dart';
import 'home_screen_widgets/category_sidebar.dart';
import 'home_screen_widgets/channel_grid.dart';
import 'player_widgets/app_exit_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final FocusNode _settingsFocusNode = FocusNode(debugLabel: 'settings');
  bool _healthCheckQueued = false;
  DateTime? _lastSelfHeal;

  // ── FocusNode lists ────────────────────────────────────────────────────────
  final List<FocusNode> _catNodes = [];
  final List<FocusNode> _chNodes = [];

  // ── State ──────────────────────────────────────────────────────────────────
  int _selectedCatIndex = 0;

  // 'sidebar' | 'grid' | 'settings'
  String _zone = 'sidebar';

  int _catIndexWhenInGrid = 0;
  int _lastGridIndex = 0;

  bool _exitDialogShowing = false;
  bool _justReturnedFromChild = false;
  bool _initialFocusDone = false;
  int _currentFilteredCount = 0;

  _FocusRequest? _pendingFocus;

  @override
  void initState() {
    super.initState();
    _settingsFocusNode.addListener(_onSettingsFocused);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    HomeScreen.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  // player screen থেকে ফিরে এলে আগের zone restore করো
  @override
  void didPopNext() {
    
    _justReturnedFromChild = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _justReturnedFromChild = false;
    });
    _scheduleFocus(_zone);
  }

  @override
  void dispose() {
    HomeScreen.routeObserver.unsubscribe(this);
    _settingsFocusNode
      ..removeListener(_onSettingsFocused)
      ..dispose();
    _disposeNodes(_catNodes);
    _disposeNodes(_chNodes);
    super.dispose();
  }

  // ── Node management ────────────────────────────────────────────────────────

  void _disposeNodes(List<FocusNode> list) {
    for (final n in list) n.dispose();
    list.clear();
  }

  void _syncNodes(List<FocusNode> list, int target, String prefix) {
    while (list.length < target) {
      list.add(FocusNode(debugLabel: '$prefix-${list.length}'));
    }
    while (list.length > target) {
      final n = list.removeLast();
      if (n.hasFocus) n.unfocus();
      n.dispose();
    }
  }

  // ── Focus scheduling ─────────────────────────────────────
  bool get _isRouteActive {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  void _scheduleFocus(String zone) {
    _zone = zone;
    final req = _FocusRequest(zone: zone);
    _pendingFocus = req;

    if (_isRouteActive) WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pendingFocus != req) return; // নতুন request এসে গেছে
      _pendingFocus = null;
      _deliverFocus(zone, retries: 5);
    });
  }

  void _deliverFocus(String zone, {required int retries}) {
   
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      _pendingFocus = null; // চলমান কোনো retry chain থাকলে বাতিল করো
      return;
    }
    switch (zone) {
      case 'settings':
        _settingsFocusNode.requestFocus();
        return;

      case 'grid':
        if (_chNodes.isEmpty) {
          // চ্যানেল নেই — sidebar-এ চলে যাও
          _zone = 'sidebar';
          _deliverFocus('sidebar', retries: retries);
          return;
        }
       
        final idx = _lastGridIndex.clamp(0, _chNodes.length - 1);
        _lastGridIndex = idx;
        final node = _chNodes[idx];
        if (node.context != null && node.canRequestFocus) {
          node.requestFocus();
          return;
        }
        _retry(zone, retries);
        return;

      default: // 'sidebar'
        if (_catNodes.isEmpty) return;
        final idx = _selectedCatIndex.clamp(0, _catNodes.length - 1);
        final node = _catNodes[idx];
        if (node.context != null && node.canRequestFocus) {
          node.requestFocus();
          return;
        }
        _retry(zone, retries);
        return;
    }
  }

  void _retry(String zone, int remaining) {
    if (remaining <= 0) {

      if (zone != 'sidebar') {
        _zone = 'sidebar';
        _deliverFocus('sidebar', retries: 3);
      }
      return;
    }
    if (_isRouteActive) WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pendingFocus != null) return; // নতুন request এসে গেছে
      _deliverFocus(zone, retries: remaining - 1);
    });
  }


  void _ensureFocusAlive() {
    _healthCheckQueued = false;
    if (!mounted) return;
    if (_pendingFocus != null) return; // ইতিমধ্যে একটা request in-flight
    if (_exitDialogShowing) return;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return; // অন্য screen (player) সক্রিয়

    final anyFocused = _settingsFocusNode.hasFocus ||
        _catNodes.any((n) => n.hasFocus) ||
        _chNodes.any((n) => n.hasFocus);

    if (!anyFocused) {
      
      final now = DateTime.now();
      if (_lastSelfHeal != null &&
          now.difference(_lastSelfHeal!) < const Duration(milliseconds: 400)) {
        return;
      }
      _lastSelfHeal = now;
      _deliverFocus(_zone, retries: 5);
    }
  }

  void _onSettingsFocused() {
    if (_settingsFocusNode.hasFocus) _zone = 'settings';
  }

  void _onGridFocusChanged(int gridIndex) {
    _zone = 'grid';
    _lastGridIndex = gridIndex;
    _catIndexWhenInGrid = _selectedCatIndex;
  }

  // ── Category change ────────────────────────────────────────────────────────

  void _changeCategory(int index, {bool toGrid = false}) {
    final changed = _selectedCatIndex != index;

    if (toGrid) {

      final cur = _selectedCatIndex.clamp(0, _catNodes.length - 1);
      if (_catNodes.isNotEmpty) _catNodes[cur].unfocus();

      _catIndexWhenInGrid = index;
      _zone = 'grid';
      _lastGridIndex = 0;
    } else {
      _zone = 'sidebar';
    }

    if (changed) {
      setState(() => _selectedCatIndex = index);
      // setState করলে build() চলবে, তার পরে _scheduleAfterBuild দিয়ে
      // focus দেবো। build() নিজে focus দেবে না।
      _scheduleAfterBuild(toGrid ? 'grid' : 'sidebar');
    } else {
      // Category একই — rebuild দরকার নেই, সরাসরি focus schedule করো
      _scheduleFocus(toGrid ? 'grid' : 'sidebar');
    }
  }


  void _scheduleAfterBuild(String zone) {
    _zone = zone;
    final req = _FocusRequest(zone: zone);
    _pendingFocus = req;
    if (_isRouteActive) WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pendingFocus != req) return;
      _pendingFocus = null;
      _deliverFocus(zone, retries: 5);
    });
  }

  // ── Grid left edge ─────────────────────────────────────────────────────────

  void _onGridMoveLeft() {
    _zone = 'sidebar';
    _selectedCatIndex = _catIndexWhenInGrid.clamp(0, _catNodes.length - 1);
    _scheduleFocus('sidebar');
  }

  // ── Sidebar key handler ────────────────────────────────────────────────────

  KeyEventResult _handleSidebarKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (_selectedCatIndex < _catNodes.length - 1) {
          _changeCategory(_selectedCatIndex + 1);
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowUp:
        if (_selectedCatIndex > 0) {
          _changeCategory(_selectedCatIndex - 1);
        } else {
          _scheduleFocus('settings');
        }
        return KeyEventResult.handled;

      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        if (_currentFilteredCount > 0) {
          _changeCategory(_selectedCatIndex, toGrid: true);
        }
        return KeyEventResult.handled;

      default:
        return KeyEventResult.ignored;
    }
  }

  // ── Back ───────────────────────────────────────────────────────────────────

  Future<void> _onBackPressed() async {
    if (_exitDialogShowing) return;
    if (_justReturnedFromChild) {
      // Player থেকে ফেরার ঠিক পরে আসা duplicate back signal — exit
      // dialog না দেখিয়ে শুধু consume করে ফেলি।
      _justReturnedFromChild = false;
      return;
    }
    _exitDialogShowing = true;
    final confirmed = await AppExitHandler.confirmExit(
      context,
      title: 'Exit App',
      message: 'Do you want to exit this App?',
    );
    _exitDialogShowing = false;
    if (confirmed && mounted) await SystemNavigator.pop();
  }

  // ── Filtered channels ──────────────────────────────────────────────────────

  List<IndexedChannel> _buildFiltered(AppState appState, String cat) {
    return [
      for (int i = 0; i < appState.channels.length; i++)
        if (cat == 'All' ||
            appState.channels[i].category.toLowerCase() == cat.toLowerCase())
          IndexedChannel(appState.channels[i], i),
    ];
  }

  // ── Build ──────────────────────────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    // ── Category list ──────────────────────────────────────────────────────
    final cats = <Map<String, String>>[
      {'name': 'All', 'icon': ''},
      for (final c in appState.categories) {'name': c.name, 'icon': c.icon},
    ];

    _syncNodes(_catNodes, cats.length, 'cat');

    // Safe index — categories কমে গেলে clamp করো
    final safeIdx = _selectedCatIndex.clamp(0, cats.length - 1);
    if (safeIdx != _selectedCatIndex) _selectedCatIndex = safeIdx;

    // ── Initial focus — একবারই ─────────────────────────────────────────────
    if (!_initialFocusDone && !appState.isLoading && _catNodes.isNotEmpty) {
      _initialFocusDone = true;
      _scheduleAfterBuild('sidebar');
    }

    // ── Filtered channels ──────────────────────────────────────────────────
    final currentCat = cats[safeIdx]['name']!;
    final filtered = _buildFiltered(appState, currentCat);
    _currentFilteredCount = filtered.length;
    _syncNodes(_chNodes, filtered.length, 'chan');


    if (!_healthCheckQueued) {
      _healthCheckQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFocusAlive());
    }

    // ── Widget tree ────────────────────────────────────────────────────────
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              HomeTopBar(
                appState: appState,
                settingsFocusNode: _settingsFocusNode,
                onSettingsDown: () => _scheduleFocus('sidebar'),
              ),
              Expanded(
                child: appState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: size.width * 0.18,
                              child: Focus(

                                skipTraversal: true,
                                canRequestFocus: false,
                                onKeyEvent: (_, e) => _handleSidebarKey(e),
                                child: CategorySidebar(
                                  cats: cats,
                                  catNodes: _catNodes,
                                  selectedIndex: safeIdx,
                                  channelCount: _currentFilteredCount,
                                  onSelect: (i) =>
                                      _changeCategory(i, toGrid: true),
                                  onMoveRight: () {
                                    if (_currentFilteredCount > 0) {
                                      _changeCategory(_selectedCatIndex,
                                          toGrid: true);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: ChannelGrid(
                                channels: filtered,
                                chNodes: _chNodes,
                                appState: appState,
                                categoryName: currentCat,
                                onFocusIndex: _onGridFocusChanged,
                                onMoveLeft: _onGridMoveLeft,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal DTO ─────────────────────────────────────────────────────────────

class _FocusRequest {
  _FocusRequest({required this.zone});
  final String zone;
}