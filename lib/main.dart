import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const opts = WindowOptions(
    title: '꼬미와 알록달록 채소 과일',
    backgroundColor: Colors.transparent,
    fullScreen: false,
  );
  windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.show();
    await windowManager.focus();
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
      home: const AppHotkeys(child: SplashScreen()),
    );
  }
}

class AppHotkeys extends StatefulWidget {
  final Widget child;
  const AppHotkeys({super.key, required this.child});

  @override
  State<AppHotkeys> createState() => _AppHotkeysState();
}

class _AppHotkeysState extends State<AppHotkeys> {
  Future<void> _exitFullscreenIfNeeded() async {
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
  }

  Future<void> _toggleFullscreen() async {
    final isFull = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFull);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      // ✅ 시그니처: (FocusNode node, KeyEvent event)
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          // ESC → 풀스크린 해제
          if (key == LogicalKeyboardKey.escape) {
            _exitFullscreenIfNeeded();
            return KeyEventResult.handled;
          }

          // F11 또는 Alt+Enter → 토글
          final isAltEnter =
              key == LogicalKeyboardKey.enter &&
              HardwareKeyboard.instance.isAltPressed;
          if (key == LogicalKeyboardKey.f11 || isAltEnter) {
            _toggleFullscreen();
            return KeyEventResult.handled;
          }

          // macOS: Ctrl+Cmd+F → 토글
          final isMacToggle =
              HardwareKeyboard.instance.isMetaPressed &&
              HardwareKeyboard.instance.isControlPressed &&
              key == LogicalKeyboardKey.keyF;
          if (isMacToggle) {
            _toggleFullscreen();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
