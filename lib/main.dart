// lib/main.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kkomi_adventure/core/global_sfx.dart';
import 'package:window_manager/window_manager.dart';

import 'utils/window_fit.dart';
import 'screens/splash_screen.dart';

/// window_manager 사용 가능 여부(웹/모바일에서는 false)
bool _wmReady = false;

/// ─────────────────────────────────────────────────────────────────
/// 데스크톱 앱 시작 흐름:
///  - (웹/모바일은 skip) window_manager 초기화
///  - 창 옵션 설정(제목/배경/센터링/풀스크린 해제)
///  - (웹/모바일은 skip) fitWindowToDisplay()로 화면맞춤
///  - show + focus 후 필요 시 풀스크린 진입
/// ─────────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 전역 효과음 미리 로드(웹/데스크톱 공통)
  await GlobalSfx.instance.preload('tap', 'audio/sfx/btn_tap.mp3');

  // 2) window_manager 초기화 (데스크톱 전용)
  if (!kIsWeb) {
    try {
      await windowManager.ensureInitialized();
      _wmReady = true;
    } catch (_) {
      _wmReady = false;
    }
  }

  // 3) 창 기본 옵션(데스크톱에서만 적용)
  const opts = WindowOptions(
    title: '꼬미와 알록달록 채소 과일',
    backgroundColor: Colors.white, // 초기엔 검정
    center: true,
    fullScreen: false,
  );

  // 4) 데스크톱이면 실제로 창 컨트롤 수행
  if (_wmReady) {
    windowManager.waitUntilReadyToShow(opts, () async {
      await _safeFitWindowToDisplay();
      await _safeShow();
      await _safeFocus();

      // 필요 시 자동 풀스크린 진입
      await Future.delayed(const Duration(milliseconds: 120));
      await _safeSetAspectRatio(0); // 풀스크린 전 비율 고정 해제
      await _safeSetFullScreen(true);
    });
  }

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
        scaffoldBackgroundColor: Colors.white, // 기본은 흰색(스플래시에서 애니로 전환)
        useMaterial3: true,
      ),
      // ✅ 웹에서는 HotkeyGlobal을 감싸지 않아 터치/클릭 인터셉트 방지
      builder: (context, child) {
        final content = child ?? const SizedBox();
        return kIsWeb ? content : HotkeyGlobal(child: content);
      },
      home: const SplashScreen(),
    );
  }
}

/// 앱 전역 핫키 위젯 (데스크톱 전용)
/// - ESC: 풀스크린 해제 + 창 모드 화면맞춤
/// - F11: 풀스크린 토글(Windows/macOS/Linux 공통)
/// - Alt+Enter: 풀스크린 토글(Windows/Linux)
/// - Ctrl+Cmd+F: 풀스크린 토글(macOS)
class HotkeyGlobal extends StatefulWidget {
  final Widget child;
  const HotkeyGlobal({super.key, required this.child});

  @override
  State<HotkeyGlobal> createState() => _HotkeyGlobalState();
}

class _HotkeyGlobalState extends State<HotkeyGlobal> {
  Future<void> _toggleFullscreen() async {
    if (!_wmReady) return; // 웹/모바일은 no-op
    final isFull = await _safeIsFullScreen();
    if (isFull == true) {
      await _safeSetFullScreen(false);
      await _safeFitWindowToDisplay();
    } else {
      await _safeSetAspectRatio(0);
      await _safeSetFullScreen(true);
    }
  }

  Future<void> _exitFullscreenIfNeeded() async {
    if (!_wmReady) return;
    final isFull = await _safeIsFullScreen();
    if (isFull == true) {
      await _safeSetFullScreen(false);
      await _safeFitWindowToDisplay();
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    // 데스크톱에서만 의미 있음. 웹에서는 이 위젯 자체를 사용하지 않음.
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;

    bool isPressed(LogicalKeyboardKey k) => pressed.contains(k);
    final isAlt =
        isPressed(LogicalKeyboardKey.altLeft) ||
        isPressed(LogicalKeyboardKey.altRight) ||
        isPressed(LogicalKeyboardKey.alt);
    final isMeta =
        isPressed(LogicalKeyboardKey.metaLeft) ||
        isPressed(LogicalKeyboardKey.metaRight) ||
        isPressed(LogicalKeyboardKey.meta);
    final isCtrl =
        isPressed(LogicalKeyboardKey.controlLeft) ||
        isPressed(LogicalKeyboardKey.controlRight) ||
        isPressed(LogicalKeyboardKey.control);

    // ESC → 풀스크린 해제 + 화면맞춤
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

    // macOS: Ctrl+Cmd+F → 풀스크린 토글
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

/// ────────────────────────────────────────────────────────────────
/// window_manager 호출을 안전하게 감싼 helper들
/// (웹/모바일/미탑재 환경에서도 예외 없이 no-op)
/// ────────────────────────────────────────────────────────────────
Future<void> _safeFitWindowToDisplay() async {
  if (!_wmReady) return;
  try {
    await fitWindowToDisplay();
  } catch (_) {}
}

Future<void> _safeShow() async {
  if (!_wmReady) return;
  try {
    await windowManager.show();
  } catch (_) {}
}

Future<void> _safeFocus() async {
  if (!_wmReady) return;
  try {
    await windowManager.focus();
  } catch (_) {}
}

Future<void> _safeSetAspectRatio(double ratio) async {
  if (!_wmReady) return;
  try {
    await windowManager.setAspectRatio(ratio);
  } catch (_) {}
}

Future<void> _safeSetFullScreen(bool value) async {
  if (!_wmReady) return;
  try {
    await windowManager.setFullScreen(value);
  } catch (_) {}
}

Future<bool?> _safeIsFullScreen() async {
  if (!_wmReady) return false;
  try {
    return await windowManager.isFullScreen();
  } catch (_) {
    return false;
  }
}
