// lib/screens/splash_screen.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:kkomi_adventure/screens/fruit_quiz_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ── Video & Audio ─────────────────────────────────────────────────────
  late final VideoPlayerController _introC; // splash.mp4 (단발)
  late final VideoPlayerController _loopC; // splash_loop.mp4 (반복)
  final AudioPlayer _bgm = AudioPlayer(); // splash_bgm.mp3 (반복)

  bool _initOnce = false;
  bool _ready = false;
  bool _showIntro = true; // 위 레이어 표시/숨김
  String? _error;

  // 배경색: 초기 검정 → 루프 시작 시 흰색으로 애니 전환
  Color _bgColor = Colors.white;

  @override
  void initState() {
    super.initState();

    _introC =
        VideoPlayerController.asset(
            'assets/videos/splash/splash.mp4',
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          )
          ..setLooping(false)
          ..addListener(_onIntroTick);

    _loopC = VideoPlayerController.asset(
      'assets/videos/splash/splash_loop.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..setLooping(true);

    _initialize();
  }

  Future<void> _initialize() async {
    if (_initOnce) return;
    _initOnce = true;

    try {
      // 1) 두 영상 미리 initialize
      await Future.wait([_introC.initialize(), _loopC.initialize()]);

      // 2) 텍스처 준비: play → pause
      await _introC.play();
      await _introC.pause();
      await _loopC.play();
      await _loopC.pause();

      // 3) BGM 루프 (🔉 볼륨 0.4 추천)
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.4);
      await _bgm.play(AssetSource('audio/bgm/splash_bgm.mp3'));

      setState(() => _ready = true);

      // 4) 인트로 재생 시작
      await _introC.seekTo(Duration.zero);
      await _introC.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  // 인트로 프레임 이벤트
  void _onIntroTick() {
    if (_error != null) return;
    final v = _introC.value;
    if (!v.isInitialized) return;

    if (v.hasError) {
      setState(() => _error = v.errorDescription ?? 'Video error');
      return;
    }

    // 인트로가 실제로 끝남 → 루프 0부터 재생 + 인트로 숨김 + 배경 흰색으로 전환
    if (!v.isPlaying && v.position >= v.duration) {
      _startLoopAndHideIntro();
    }
  }

  Future<void> _startLoopAndHideIntro() async {
    try {
      await _loopC.seekTo(Duration.zero);
      await _loopC.play();
      try {
        await _introC.pause();
      } catch (_) {}

      if (!mounted) return;

      // 배경을 검정 → 흰색으로 부드럽게 전환 (300ms)
      setState(() {
        _showIntro = false;
        _bgColor = Colors.white;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _introC.removeListener(_onIntroTick);
    _introC.dispose();
    _loopC.dispose();
    _bgm.stop();
    _bgm.dispose();
    super.dispose();
  }

  // 다음 화면으로
  Future<void> _goNext() async {
    try {
      await _introC.pause();
      await _loopC.pause();
      await _bgm.stop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a, b) => const FruitQuizScreen(),
        transitionsBuilder: (context, a, b, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // 키 입력(Enter/Space)
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final k = event.logicalKey;
      if (k == LogicalKeyboardKey.enter ||
          k == LogicalKeyboardKey.numpadEnter ||
          k == LogicalKeyboardKey.space) {
        _goNext();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ready =
        _ready &&
        _introC.value.isInitialized &&
        _loopC.value.isInitialized &&
        _error == null;

    return GestureDetector(
      onTap: _goNext,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Scaffold(
          // 배경 전환(검정 → 흰색)을 부드럽게
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            color: _bgColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ready) ...[
                  // 바닥: loop (인트로 끝난 뒤부터 보임)
                  PositionedFillVideo(controller: _loopC),

                  // 위: intro (끝나면 숨김)
                  Positioned.fill(
                    child: Visibility(
                      visible: _showIntro,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _introC.value.size.width,
                          height: _introC.value.size.height,
                          child: VideoPlayer(_introC),
                        ),
                      ),
                    ),
                  ),
                ] else
                  // 프리로딩 화면
                  Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // 에러 힌트 (Windows 전용 안내) — 웹에선 Platform 접근 금지
                if (_error != null && !kIsWeb && Platform.isWindows)
                  const Positioned(
                    left: 16,
                    bottom: 24,
                    right: 16,
                    child: Text(
                      '힌트: Windows 배포 시 MP4는 H.264 + AAC 권장.\n'
                      '다른 코덱/컨테이너는 재생이 안 될 수 있어요.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),

                // 터치/키 안내(선택)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: IgnorePointer(
                    ignoring: !ready,
                    child: Opacity(
                      opacity: ready ? 0.9 : 0.0,
                      child: const Center(
                        child: Text(
                          '탭/Enter/Space로 시작',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

/// loop 비디오 바닥 레이어 위젯 (가독성 위해 분리)
class PositionedFillVideo extends StatelessWidget {
  final VideoPlayerController controller;
  const PositionedFillVideo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // controller.value.isInitialized 체크는 상위에서 보장
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
