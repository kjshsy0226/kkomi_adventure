import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 윈도우 매니저 초기화
  await windowManager.ensureInitialized();

  // ✅ Release 모드에서 창 크기 및 위치 지정
  const opts = WindowOptions(
    title: '꼬미와 알록달록 채소 과일',
    backgroundColor: Colors.black, // 🔸 Release 모드에서 투명은 피함
    center: true,
    fullScreen: false, // 나중에 fullScreen으로 전환
  );

  windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.show();
    await windowManager.focus();

    // ✅ 창 크기/위치 지정 후 풀스크린 진입
    await windowManager.setSize(const Size(1920, 1080));
    await windowManager.setPosition(const Offset(0, 0));
    await Future.delayed(const Duration(milliseconds: 200));
    await windowManager.setFullScreen(true);
  });

  runApp(const BaseApp());
}

class BaseApp extends StatelessWidget {
  const BaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '꼬미와 알록달록 채소 과일',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      builder: (context, child) =>
          HotkeyGlobal(child: child ?? const SizedBox()),
      home: const SplashScreen(),
    );
  }
}

/// 앱 전역 핫키 (F11/Alt+Enter 토글, ESC 해제, macOS Ctrl+Cmd+F)
class HotkeyGlobal extends StatefulWidget {
  final Widget child;
  const HotkeyGlobal({super.key, required this.child});

  @override
  State<HotkeyGlobal> createState() => _HotkeyGlobalState();
}

class _HotkeyGlobalState extends State<HotkeyGlobal> {
  Future<void> _toggleFullscreen() async {
    final isFull = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFull);
  }

  Future<void> _exitFullscreenIfNeeded() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;

    bool isPressed(LogicalKeyboardKey k) => pressed.contains(k);
    final isAlt = isPressed(LogicalKeyboardKey.altLeft) ||
        isPressed(LogicalKeyboardKey.altRight) ||
        isPressed(LogicalKeyboardKey.alt);
    final isMeta = isPressed(LogicalKeyboardKey.metaLeft) ||
        isPressed(LogicalKeyboardKey.metaRight) ||
        isPressed(LogicalKeyboardKey.meta);
    final isCtrl = isPressed(LogicalKeyboardKey.controlLeft) ||
        isPressed(LogicalKeyboardKey.controlRight) ||
        isPressed(LogicalKeyboardKey.control);

    // ESC → 풀스크린 해제
    if (key == LogicalKeyboardKey.escape) {
      _exitFullscreenIfNeeded();
      return true;
    }

    // F11 → 풀스크린 토글
    if (key == LogicalKeyboardKey.f11) {
      _toggleFullscreen();
      return true;
    }

    // Alt+Enter → 풀스크린 토글 (Windows/Linux)
    if (isAlt && key == LogicalKeyboardKey.enter) {
      _toggleFullscreen();
      return true;
    }

    // macOS: Ctrl+Cmd+F
    if (isMeta && isCtrl && key == LogicalKeyboardKey.keyF) {
      _toggleFullscreen();
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
