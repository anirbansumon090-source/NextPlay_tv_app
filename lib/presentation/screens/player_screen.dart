//lib/presentaion/screen/player_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as native_vp;
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import 'player_widgets/player_top_panel.dart';
import 'player_widgets/channel_list_panel.dart';
import 'player_widgets/loading_overlay.dart';
import 'player_widgets/app_info_dialog.dart';
import 'player_widgets/app_exit_settings.dart';

class _SecurePlayerHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => "DIRECT";
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    // dead host হলে socket level এ দ্রুত fail করার জন্য — না হলে OS
    // default timeout (অনেক বেশি) ধরে অপেক্ষা করতে হতো।
    client.connectionTimeout = const Duration(seconds: 4);
    client.idleTimeout = const Duration(seconds: 8);
    return client;
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver, RouteAware {
  final FocusNode _focus = FocusNode(debugLabel: 'player-root');

  native_vp.VideoPlayerController? _nativeCtrl;
  VoidCallback? _nativeCtrlListener;

  String? _activeChannelId;

  bool _showControls = true;
  bool _isLoading = false;
  bool _hasStreamError = false;
  bool _showChannelList = false;

  bool _isDialogOpen = false;

  // ← Settings screen-এ আছি কিনা track করার জন্য
  bool _isOnSettingsScreen = false;

  AppState? _appState;

  Timer? _controlsTimer;
  Timer? _channelListTimer;
  Timer? _numberTimer;
  Timer? _bufferWatchdog;
  Timer? _retryDelayTimer;
  // ✅ ফিক্স: silent mid-stream freeze ধরার জন্য নতুন পিরিয়ডিক টাইমার।
  Timer? _positionStallWatchdog;
  Duration _lastSeenPosition = Duration.zero;
  DateTime _lastPositionChangeAt = DateTime.now();

  String _typed = '';

  int _currentInitTimestamp = 0;
  late DateTime _ignoreSelectUntil;
  bool _handlingBack = false;
  bool _routeArgsChecked = false;
  // ✅ ফিক্স: Player স্ক্রিন Home থেকে এসেছে নাকি boot-to-player দিয়ে
  // সরাসরি খোলা হয়েছে তা ট্র্যাক করার জন্য। AppExitHandler.handleExit
  // এই ফ্ল্যাগ দেখে ঠিক করে — back চাপলে পুরনো Home route-এ pop করবে,
  // নাকি নতুন একটা Home route বানাবে (দেখো app_exit_settings.dart)।
  bool _cameFromHome = false;
  DateTime _lastBackTime = DateTime(2000);

  static const List<Duration> _attemptTimeouts = [
    Duration(seconds: 5),
    Duration(seconds: 6),
    Duration(seconds: 7),
  ];
  static const int _maxAutoRetries = 3; // মোট চেষ্টা, এরপর manual/offline
  static const List<Duration> _retryBackoff = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
  ];
  static const Duration _bufferStuckThreshold = Duration(seconds: 6);
  // ✅ ফিক্স: প্রতি কত সেকেন্ড পর পর actual playback position এগোচ্ছে
  // কিনা যাচাই করা হবে। অনেক IPTV/HLS স্ট্রিম silently freeze হয়ে যায় —
  // isPlaying সত্যি থাকে, isBuffering মিথ্যা থাকে, কিন্তু আসলে কোনো নতুন
  // ফ্রেম আসছে না। আগের কোডে কেবল isBuffering flag-এর উপর ভিত্তি করে
  // watchdog চলতো, ফলে এই ধরনের "silent freeze" কখনো ধরা পড়তো না এবং
  // auto-retry-ও কাজ করতো না — ইউজার শুধু একটা স্থির ফ্রেম দেখতো।
  static const Duration _positionStallCheckInterval = Duration(seconds: 3);
  static const Duration _positionStallThreshold = Duration(seconds: 7);

  int _retryAttempt = 0; // 0 = প্রথম চেষ্টা
  bool _exhaustedRetries = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _wakelock();
      if (!_isDialogOpen && !_isOnSettingsScreen) _requestFocus();
    } else if (state == AppLifecycleState.paused) {
      _nativeCtrl?.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    _ignoreSelectUntil =
        DateTime.now().add(const Duration(milliseconds: 500));
    HttpOverrides.global = _SecurePlayerHttpOverrides();
    WidgetsBinding.instance.addObserver(this);
    _forceFullLandscape();
    _wakelock();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _appState = Provider.of<AppState>(context, listen: false);
        _initController();
        _startControlsTimer();
        _focus.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PlayerScreen.routeObserver.subscribe(this, ModalRoute.of(context)!);

    if (!_routeArgsChecked) {
      _routeArgsChecked = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == 'fromHome') {
        _cameFromHome = true;
        _ignoreSelectUntil =
            DateTime.now().add(const Duration(milliseconds: 1500));
        _showChannelList = false;
      }
    }

    final nextState = Provider.of<AppState>(context, listen: false);
    if (_appState != null && _activeChannelId != null) {
      final nextChannelId = nextState.channels.isNotEmpty
          ? nextState.channels[nextState.currentChannelIndex].id
          : null;
      if (nextChannelId == _activeChannelId) {
        _appState = nextState;
        return;
      }
    }
    _appState = nextState;
  }

  // ← Settings screen-এ push হলে এটা call হয়
  @override
  void didPushNext() {
    _isOnSettingsScreen = true;
    _controlsTimer?.cancel();
    _channelListTimer?.cancel();
    _bufferWatchdog?.cancel();
    _positionStallWatchdog?.cancel();
    _retryDelayTimer?.cancel();
    // ✅ FIX: Home বা Settings-এ push হওয়ার সময় channel list ও controls
    // লুকিয়ে দাও — না হলে route transition এ player skin দেখা যায়।
    if (mounted) {
      setState(() {
        _showChannelList = false;
        _showControls = false;
      });
      _focus.unfocus();
    }
  }

  // ← Settings screen থেকে ফিরে এলে এটা call হয়
  @override
  void didPopNext() {
    _isOnSettingsScreen = false;
    _isDialogOpen = false;
    _ignoreSelectUntil =
        DateTime.now().add(const Duration(milliseconds: 400));
    _requestFocus();
    _startControlsTimer();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_showChannelList && !_isDialogOpen && !_isOnSettingsScreen) {
        _focus.requestFocus();
      }
    });
  }

  Future<void> _handleBackPress() async {
    final now = DateTime.now();
    if (now.difference(_lastBackTime).inMilliseconds < 300) return;
    _lastBackTime = now;

    if (_handlingBack || _isDialogOpen || _isOnSettingsScreen) return;
    _handlingBack = true;

    try {
      if (_showChannelList) {
        _hideChannelList();
        return;
      }

      if (_appState == null || !mounted) return;

      if (!_showControls) {
        setState(() => _showControls = true);
      }
      _controlsTimer?.cancel();

      _isDialogOpen = true;
      await AppExitHandler.handleExit(
        context: context,
        appState: _appState!,
        cameFromHome: _cameFromHome,
        onBeforeDispose: _prepareForExitRelease,
        onCancelled: () {
          _isDialogOpen = false;
          if (mounted) {
            _requestFocus();
            _startControlsTimer();
          }
        },
      );
      _isDialogOpen = false;
    } finally {
      _isDialogOpen = false;
      _handlingBack = false;
    }
  }

  void _forceFullLandscape() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _wakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {}
  }

  void _prepareForExitRelease() {
    _controlsTimer?.cancel();
    _channelListTimer?.cancel();
    _numberTimer?.cancel();
    _bufferWatchdog?.cancel();
    _positionStallWatchdog?.cancel();
    _retryDelayTimer?.cancel();
    _disposeControllers();
  }

  void _hideChannelList() {
    _channelListTimer?.cancel();
    if (!_showChannelList) return;
    setState(() => _showChannelList = false);
    _requestFocus();
    _startControlsTimer();
  }

  void _showChannelListPanel() {
    setState(() {
      _showChannelList = true;
      _showControls = true;
    });
    _controlsTimer?.cancel();
    _startChannelListTimer();
  }

  void _startChannelListTimer() {
    _channelListTimer?.cancel();
    _channelListTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _showChannelList && !_isDialogOpen && !_isOnSettingsScreen) {
        _hideChannelList();
      }
    });
  }

  // ✅ ফিক্স: ChannelListPanel-এর ভিতরে কী-প্যাড অ্যাক্টিভিটি (focus change)
  // হলে এটা কল হবে এবং auto-hide টাইমার রিসেট করবে। আগে এই মেথডটা
  // ChannelListPanel-এ পাস করা হতো না, ফলে ইউজার লিস্টের ভিতরে
  // up/down চাপতে থাকলেও ৮ সেকেন্ড পর প্যানেল হাইড হয়ে যেতো।
  void _onChannelListActivity() {
    if (mounted &&
        _showChannelList &&
        !_isDialogOpen &&
        !_isOnSettingsScreen) {
      _startChannelListTimer();
    }
  }

  void _toggleChannelList() {
    if (_showChannelList) {
      _hideChannelList();
    } else {
      _showChannelListPanel();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted &&
          _showControls &&
          _typed.isEmpty &&
          !_showChannelList &&
          !_isDialogOpen &&
          !_isOnSettingsScreen) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_showChannelList || _isDialogOpen || _isOnSettingsScreen) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _disposeControllers() {
    _bufferWatchdog?.cancel();
    _bufferWatchdog = null;
    _positionStallWatchdog?.cancel();
    _positionStallWatchdog = null;
    if (_nativeCtrl != null) {
      final oldCtrl = _nativeCtrl!;
      _nativeCtrl = null;
      if (_nativeCtrlListener != null) {
        oldCtrl.removeListener(_nativeCtrlListener!);
        _nativeCtrlListener = null;
      }
      try {
        unawaited(oldCtrl.setVolume(0));
        if (oldCtrl.value.isPlaying) unawaited(oldCtrl.pause());
      } catch (_) {}
      unawaited(oldCtrl.dispose());
    }
  }

  
  Future<void> _initController({bool resetRetry = true}) async {
    if (!mounted || _appState == null) return;

    if (resetRetry) {
      _retryAttempt = 0;
      _exhaustedRetries = false;
      _retryDelayTimer?.cancel();
    }

    final channel = _appState!.currentChannel;
    final int thisInitTimestamp = DateTime.now().millisecondsSinceEpoch;
    _currentInitTimestamp = thisInitTimestamp;

    setState(() {
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = channel.id;
    });

    _disposeControllers();

    final newCtrl = native_vp.VideoPlayerController.networkUrl(
      Uri.parse(channel.streamUrl),
      videoPlayerOptions: native_vp.VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
      httpHeaders: {
        'User-Agent': 'OTTKING-1.1 ANDROIDTV AGENT',
        'X-App-Token': 'backend_generated_secret_handshake_token',
        'Origin': 'https://ottking.internal',
        'Accept': '*/*',
      },
    );

    final timeoutForThisAttempt = _attemptTimeouts[
        _retryAttempt.clamp(0, _attemptTimeouts.length - 1)];

    try {
      await newCtrl.initialize().timeout(
        timeoutForThisAttempt,
        onTimeout: () => throw TimeoutException('timeout'),
      );

      if (_currentInitTimestamp != thisInitTimestamp || !mounted) {
        unawaited(newCtrl.dispose());
        return;
      }

      await newCtrl.play();
      _wakelock();

      _nativeCtrlListener = _onNativeCtrlUpdate;
      _nativeCtrl = newCtrl;
      newCtrl.addListener(_nativeCtrlListener!);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasStreamError = false;
        });
        // সফল হলে counter রিসেট — যাতে এক স্ট্রিমে পরে আবার কোনো
        // আলাদা/স্বাধীন blip হলে আবার পুরো ৩টা চেষ্টা পায়।
        _retryAttempt = 0;
        _exhaustedRetries = false;
        _requestFocus();
        _armBufferWatchdog();
        _armPositionStallWatchdog(newCtrl);
      }
    } catch (e) {
      if (_currentInitTimestamp == thisInitTimestamp && mounted) {
        newCtrl.dispose();
        _scheduleRetryOrFail(thisInitTimestamp);
      } else {
        newCtrl.dispose();
      }
    }
  }

  // ব্যর্থ হলে: ৩ বার পর্যন্ত backoff দিয়ে silent auto-retry, তারপরই
  // visible "Offline" + manual retry দেখানো।
  void _scheduleRetryOrFail(int forTimestamp) {
    if (!mounted) return;

    if (_retryAttempt < _maxAutoRetries - 1) {
      final nextAttempt = _retryAttempt + 1;
      final delay = _retryBackoff[
          _retryAttempt.clamp(0, _retryBackoff.length - 1)];

      setState(() {
        _isLoading = true;
        _hasStreamError = false;
      });

      _retryDelayTimer?.cancel();
      _retryDelayTimer = Timer(delay, () {
        if (!mounted || _currentInitTimestamp != forTimestamp) return;
        if (_isOnSettingsScreen || _isDialogOpen) return;
        _retryAttempt = nextAttempt;
        _initController(resetRetry: false);
      });
    } else {
      _enterStreamErrorState(exhausted: true);
    }
  }

  void _handleStreamDrop() {
    if (!mounted) return;
    if (_isOnSettingsScreen || _isDialogOpen) return;

    final ts = DateTime.now().millisecondsSinceEpoch;
    _currentInitTimestamp = ts;
    _disposeControllers(); // ভাঙা/আটকে যাওয়া controller অবিলম্বে সরাও
    _scheduleRetryOrFail(ts);
  }

  void _armBufferWatchdog() {
    _bufferWatchdog?.cancel();
    _bufferWatchdog = Timer(_bufferStuckThreshold, () {
      if (!mounted) return;
      final ctrl = _nativeCtrl;
      if (ctrl == null) return;
      if (ctrl.value.isBuffering && !_hasStreamError) {
        _handleStreamDrop();
      }
    });
  }

  // ✅ ফিক্স: "চলতে চলতে হুট করে অফলাইন দেখায়, রিট্রাই করে আবার লোড করে
  // না" সমস্যার মূল কারণ এখানে — অনেক IPTV/HLS স্ট্রিম এমনভাবে freeze
  // হয় যে video_player এর isBuffering flag কখনো true হয় না (player
  // মনে করে এখনো "playing" আছে), কিন্তু আসলে কোনো নতুন ফ্রেম আসছে না।
  // ফলে পুরনো _armBufferWatchdog() কখনো ট্রিগার হতো না এবং auto-retry
  // শুরুই হতো না — স্ক্রিনে একটা স্থির/freeze ফ্রেম আটকে থাকতো।
  //
  // এই watchdog প্রতি few সেকেন্ড পর পর actual playback position চেক
  // করে। position যদি যথেষ্ট সময় ধরে না এগোয় (অথচ controller মনে করছে
  // playing/initialized, error নেই), তখন এটাকে silent freeze ধরে নিয়ে
  // ঠিক সেই একই _handleStreamDrop() ফ্লো ট্রিগার করে যা auto-retry শুরু
  // করে — exactly আগের retry/backoff/offline যুক্তি বজায় রেখে।
  void _armPositionStallWatchdog(native_vp.VideoPlayerController ctrl) {
    _positionStallWatchdog?.cancel();
    _lastSeenPosition = Duration.zero;
    _lastPositionChangeAt = DateTime.now();

    _positionStallWatchdog =
        Timer.periodic(_positionStallCheckInterval, (_) async {
      if (!mounted || _hasStreamError) return;
      if (_isOnSettingsScreen || _isDialogOpen) return;
      if (_nativeCtrl != ctrl) {
        // এই ctrl আর active নয় — পুরনো timer বন্ধ করে দেওয়া হলো।
        _positionStallWatchdog?.cancel();
        return;
      }

      final value = ctrl.value;
      if (!value.isInitialized || value.hasError) return;

      // পজ করা থাকলে বা বাফার করার সময় position এগোবে না — সেটা স্বাভাবিক,
      // আলাদাভাবে _armBufferWatchdog ইতিমধ্যে buffering কেস সামলায়।
      if (!value.isPlaying || value.isBuffering) {
        _lastSeenPosition = value.position;
        _lastPositionChangeAt = DateTime.now();
        return;
      }

      final currentPosition = value.position;
      if (currentPosition != _lastSeenPosition) {
        _lastSeenPosition = currentPosition;
        _lastPositionChangeAt = DateTime.now();
        return;
      }

      final stuckFor = DateTime.now().difference(_lastPositionChangeAt);
      if (stuckFor >= _positionStallThreshold) {
        _positionStallWatchdog?.cancel();
        _handleStreamDrop();
      }
    });
  }

  void _onNativeCtrlUpdate() {
    if (!mounted) return;

  
    if (_nativeCtrl?.value.hasError == true) {
      _handleStreamDrop();
      return;
    }

    if (_nativeCtrl != null && _nativeCtrl!.value.isInitialized) {
      if (_nativeCtrl!.value.isBuffering) {
        _armBufferWatchdog();
      } else {
        
        _bufferWatchdog?.cancel();
        if (_retryAttempt != 0 || _exhaustedRetries) {
          _retryAttempt = 0;
          _exhaustedRetries = false;
        }
      }
      if (!_nativeCtrl!.value.isBuffering &&
          !_nativeCtrl!.value.isPlaying &&
          !_hasStreamError &&
          !_isLoading) {
        _nativeCtrl!.play();
      }
    }
    setState(() {});
  }

  void _enterStreamErrorState({bool exhausted = false}) {
    _disposeControllers();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _hasStreamError = true;
      _exhaustedRetries = exhausted;
      _showControls = true;
    });
    _startControlsTimer();
    _requestFocus();
  }

  void _manualRetry() {
    if (_appState == null) return;
    _initController(resetRetry: true);
  }

  void _switchChannel(int direction) {
    if (_appState == null || _isDialogOpen || _isOnSettingsScreen) return;
    _retryDelayTimer?.cancel();
    _currentInitTimestamp = DateTime.now().millisecondsSinceEpoch;
    _disposeControllers();
    setState(() {
      _showControls = true;
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = null;
    });
    _startControlsTimer();
    _appState!.switchChannel(direction);
    if (mounted) _initController(resetRetry: true);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.snackbar,
      ));
  }

  void _switchToIndex(int index) {
    if (_appState == null) return;
    final allCh = _appState!.channels;
    if (index < 0 || index >= allCh.length) {
      _showSnack('${index + 1} No Channels Found');
      return;
    }
    _retryDelayTimer?.cancel();
    _currentInitTimestamp = DateTime.now().millisecondsSinceEpoch;
    _disposeControllers();
    setState(() {
      _showControls = true;
      _isLoading = true;
      _hasStreamError = false;
      _activeChannelId = null;
    });
    _appState!.selectChannelByIndex(index);
    if (mounted) _initController(resetRetry: true);
  }

  void _handleNumberInput(String digit) {
    _numberTimer?.cancel();
    setState(() {
      _showControls = true;
      _typed += digit;
    });
    _numberTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _typed.isNotEmpty) {
        final n = int.tryParse(_typed);
        if (n != null) _switchToIndex(n - 1);
        setState(() => _typed = '');
        _startControlsTimer();
      }
    });
  }

  void _openSettings() {
    if (_isDialogOpen || _isOnSettingsScreen) return;
    _controlsTimer?.cancel();
    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => Consumer<AppState>(
        builder: (ctx, state, __) => PlayerSettingsDialog(
          state: state,
          onAppInfo: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogOpen = false;
            _showAppInfo();
          },
          onNavigateSettings: () {
            // ১. আগে dialog বন্ধ করো
            Navigator.of(context, rootNavigator: true).pop();
            // ২. _isDialogOpen false করো
            _isDialogOpen = false;

            Future.microtask(() {
              if (mounted) {
                Navigator.pushNamed(context, '/settings');
                
              }
            });
          },
          onClose: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isDialogOpen = false;
          },
        ),
      ),
    ).then((_) {
      _isDialogOpen = false;
      if (mounted && !_isOnSettingsScreen) {
        _requestFocus();
        _startControlsTimer();
      }
    });
  }

  void _showAppInfo() {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const AppInfoDialog(),
    ).then((_) {
      _isDialogOpen = false;
      if (mounted && !_isOnSettingsScreen) {
        _requestFocus();
        _startControlsTimer();
      }
    });
  }

  KeyEventResult _handlePlayerKey(FocusNode node, KeyEvent event) {
  
    if (!_focus.hasFocus) return KeyEventResult.ignored;
    if (_isOnSettingsScreen) return KeyEventResult.ignored;
    if (_showChannelList || _isDialogOpen) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final isBack = (event is KeyDownEvent) &&
        (key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.browserBack);

    if (isBack) {
      unawaited(_handleBackPress());
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isActivate = key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space;

  
    if (_hasStreamError && _exhaustedRetries && isActivate) {
      _manualRetry();
      return KeyEventResult.handled;
    }

    final label = key.keyLabel;
    if (RegExp(r'^[0-9]$').hasMatch(label)) {
      _handleNumberInput(label);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.arrowUp) {
      _switchChannel(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.arrowDown) {
      _switchChannel(-1);
      return KeyEventResult.handled;
    }

    if (isActivate &&
        DateTime.now().isAfter(_ignoreSelectUntil) &&
        !_isLoading) {
      _toggleChannelList();
      return KeyEventResult.handled;
    }

    if (!_showControls) {
      setState(() => _showControls = true);
      _startControlsTimer();
      _requestFocus();
      return KeyEventResult.handled;
    }

    _startControlsTimer();
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    PlayerScreen.routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _prepareForExitRelease();
    _focus.dispose();
    HttpOverrides.global = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_appState == null) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final ch = _appState!.currentChannel;
   
    final bool initialized = _nativeCtrl != null &&
        _nativeCtrl!.value.isInitialized &&
        !_nativeCtrl!.value.hasError &&
        !_hasStreamError;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Settings screen-এ থাকলে player-এর back handle করবে না
        if (_isOnSettingsScreen) return;
        await _handleBackPress();
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _handlePlayerKey,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _toggleControls,
            onHorizontalDragEnd: (d) {
              // Settings screen-এ থাকলে swipe কাজ করবে না
              if (_isOnSettingsScreen) return;
              if (d.primaryVelocity == null) return;
              if (d.primaryVelocity! < -300) _switchChannel(1);
              if (d.primaryVelocity! > 300) _switchChannel(-1);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ✅ FIX 3: ভিডিও সম্পূর্ণ স্ক্রিন ফিল (zoom/stretch)
                // FittedBox(fit: BoxFit.fill) ভিডিওকে স্ক্রিনের XY তে পুরোপুরি
                // ফিট করে — aspect ratio উপেক্ষা করে সম্পূর্ণ স্কিন ভরে যায়।
                // কোনো কালো বার বা letterbox থাকবে না।
                if (initialized)
                  ExcludeFocus(
                    child: SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: _nativeCtrl!.value.size.width,
                          height: _nativeCtrl!.value.size.height,
                          child: native_vp.VideoPlayer(_nativeCtrl!),
                        ),
                      ),
                    ),
                  ),

                // ✅ FIX 4: স্মার্ট লোডিং ওভারলে — শুধু সত্যিকার অফলাইন/
                // exhausted retry-তে দেখাবে। প্রথম লোড বা লেটেন্সির কারণে
                // বাফার হলে দেখাবে না (isBufferingVisible = false)।
                // _retryAttempt > 0 মানে প্রথম চেষ্টা ব্যর্থ হয়েছে — তখনই
                // "Reconnecting" দেখাবে।
                LoadingOverlay(
                  hasError: _hasStreamError,
                  isLoading: _isLoading,
                  channelName: ch.name,
                  retryAttempt: _retryAttempt + 1,
                  maxRetries: _maxAutoRetries,
                  showManualRetry: _hasStreamError && _exhaustedRetries,
                  // প্রথম লোডে (_retryAttempt == 0) স্পিনার লুকানো থাকবে
                  // শুধু retry শুরু হলে বা error হলে দেখাবে
                  isBufferingVisible: _retryAttempt > 0 || _hasStreamError,
                ),

                if (_showControls)
                  PlayerTopPanel(
                    channel: ch,
                    currentIndex: _appState!.currentChannelIndex,
                    totalChannels: _appState!.channels.length,
                    typedNumber: _typed,
                  ),

                if (_showChannelList)
                  ChannelListPanel(
                    channels: _appState!.channels,
                    currentIndex: _appState!.currentChannelIndex,
                    onSettings: _openSettings,
                    onSelect: (i) {
                      final currentIdx = _appState!.currentChannelIndex;
                      _hideChannelList();
                      if (i != currentIdx) _switchToIndex(i);
                    },
                    onActivity: _onChannelListActivity, // ✅ ফিক্স
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}