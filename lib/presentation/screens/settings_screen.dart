// lib/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/tv_focus_utils.dart';
import 'settings_screen_widgets/settings_nav_sidebar.dart';
import 'settings_screen_widgets/settings_account_section.dart';
import 'settings_screen_widgets/settings_tv_section.dart';
import 'settings_screen_widgets/settings_system_section.dart';
import 'settings_screen_widgets/settings_status_footer.dart';

enum _Section { account, tvSettings, system }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with RouteAware {
  final FocusNode _firstSidebarNode = FocusNode(debugLabel: 'settings-first-nav');
  final List<FocusNode> _cardFocusNodes = [];
  _Section _activeSection = _Section.account;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstSidebarNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SettingsScreen.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    SettingsScreen.routeObserver.unsubscribe(this);
    _firstSidebarNode.dispose();
    for (final node in _cardFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void didPopNext() {
    restoreFocusAfterFrame(_firstSidebarNode, ifMounted: () => mounted);
  }

  void _safelyPop() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _requestSidebarFocus() {
    if (mounted) {
      _firstSidebarNode.requestFocus();
    }
  }

  void _selectSection(int index) {
    setState(() => _activeSection = _Section.values[index]);
  }

  void _moveToContentFromNav(int index) {
    setState(() => _activeSection = _Section.values[index]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusFirstContent();
    });
  }

  int _cardCountForSection() {
    switch (_activeSection) {
      case _Section.account:
        return 2;
      case _Section.tvSettings:
        return 1;
      case _Section.system:
        return 4;
    }
  }

  void _syncCardFocusNodes(int count) {
    while (_cardFocusNodes.length < count) {
      _cardFocusNodes.add(
        FocusNode(debugLabel: 'settings-card-${_cardFocusNodes.length}'),
      );
    }
    while (_cardFocusNodes.length > count) {
      _cardFocusNodes.removeLast().dispose();
    }
  }

  void _focusFirstContent() {
    _syncCardFocusNodes(_cardCountForSection());
    if (_cardFocusNodes.isNotEmpty && mounted) {
      _cardFocusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _syncCardFocusNodes(_cardCountForSection());

    final navCallbacks = (
      onReturnToSidebar: _requestSidebarFocus,
      onScreenBack: _safelyPop,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _safelyPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: SettingsNavSidebar(
                  activeSection: _activeSection.index,
                  firstFocusNode: _firstSidebarNode,
                  onSelect: _selectSection,
                  onBack: _safelyPop,
                  onMoveToContent: _moveToContentFromNav,
                ),
              ),
              Container(
                width: 1,
                color: Colors.white.withOpacity(0.05),
              ),
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: SafeArea(
                    child: FocusTraversalGroup(
                      policy: WidgetOrderTraversalPolicy(),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _buildActiveSection(
                                appState,
                                navCallbacks,
                                _cardFocusNodes,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Divider(color: Colors.white.withOpacity(0.05)),
                            const SizedBox(height: 16),
                            SettingsStatusFooter(appState: appState),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSection(
    AppState appState,
    ({VoidCallback onReturnToSidebar, VoidCallback onScreenBack}) nav,
    List<FocusNode> cardFocusNodes,
  ) {
    switch (_activeSection) {
      case _Section.account:
        return SettingsAccountSection(
          key: const ValueKey('account'),
          appState: appState,
          cardFocusNodes: cardFocusNodes,
          onReturnToSidebar: nav.onReturnToSidebar,
          onScreenBack: nav.onScreenBack,
        );
      case _Section.tvSettings:
        return SettingsTvSection(
          key: const ValueKey('tv'),
          appState: appState,
          cardFocusNodes: cardFocusNodes,
          onReturnToSidebar: nav.onReturnToSidebar,
          onScreenBack: nav.onScreenBack,
        );
      case _Section.system:
        return SettingsSystemSection(
          key: const ValueKey('system'),
          appState: appState,
          cardFocusNodes: cardFocusNodes,
          onReturnToSidebar: nav.onReturnToSidebar,
          onScreenBack: nav.onScreenBack,
        );
    }
  }
}
