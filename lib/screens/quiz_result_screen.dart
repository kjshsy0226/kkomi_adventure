import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import 'splash_screen.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  // ── Video & Audio ─────────────────────────────────────────────────────
  late final VideoPlayerController _introC; // result.mp4 (단발)
  late final VideoPlayerController _loopC; // result_loop.mp4 (반복)
  final AudioPlayer _bgm = AudioPlayer(); // result_bgm.mp3 (반복)

  bool _initOnce = false;
  bool _ready = false;
  bool _showIntro = true; // 위 레이어 표시/숨김 (즉시 전환)
  bool _navigating = false;
  String? _error;

  // 배경색: 초기 흰색 → (인트로 종료 시) 흰색 유지 (필요시 검정→흰색으로 바꾸고 싶으면 초기값을 Colors.black로 바꿔)
  Color _bgColor = Colors.white;

  late final VoidCallback _onTick;

  @override
  void initState() {
    super.initState();

    _introC = VideoPlayerController.asset(
      'assets/videos/result/result.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..setLooping(false);

    _loopC = VideoPlayerController.asset(
      'assets/videos/result/result_loop.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..setLooping(true);

    _onTick = () {
      final v = _introC.value;
      if (!v.isInitialized) return;

      if (v.hasError && _error == null) {
        _error = v.errorDescription ?? 'Video error';
        _introC.pause();
      }

      // 인트로가 실제로 끝나는 순간에만 처리
      if (!v.isPlaying && v.isInitialized && v.position >= v.duration) {
        _startLoopAndHideIntro();
      }

      if (mounted) setState(() {});
    };

    _initialize();
  }

  Future<void> _initialize() async {
    if (_initOnce) return;
    _initOnce = true;

    try {
      // 1) 두 영상 initialize
      await Future.wait([_introC.initialize(), _loopC.initialize()]);
      if (!mounted) return;

      _introC.addListener(_onTick);

      // 2) 텍스처 프리패치: play → pause (깜빡임 최소화)
      await _introC.play();
      await _introC.pause();
      await _loopC.play();
      await _loopC.pause();

      // 3) BGM 무한 반복
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.setVolume(0.4);
      await _bgm.play(AssetSource('audio/bgm/result_bgm.mp3'));

      setState(() => _ready = true);

      // 4) 인트로 재생 시작
      await _introC.seekTo(Duration.zero);
      await _introC.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _startLoopAndHideIntro() async {
    try {
      // (1) 루프 0부터 재생 시작
      await _loopC.seekTo(Duration.zero);
      await _loopC.play();
      // (2) 인트로 숨김
      try {
        await _introC.pause();
      } catch (_) {}

      if (!mounted) return;

      // (3) 배경 전환이 필요하다면 여기서 AnimatedContainer가 반영 (현재는 흰색 유지)
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
    try {
      _introC.removeListener(_onTick);
    } catch (_) {}
    _introC.dispose();
    _loopC.dispose();
    _bgm.stop();
    _bgm.dispose();
    super.dispose();
  }

  void _backToSplash() {
    if (_navigating || !mounted) return;
    _navigating = true;

    // 재생 중지(안전)
    try {
      _introC.pause();
      _loopC.pause();
      _bgm.stop();
    } catch (_) {}

    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (c, a, b) => const SplashScreen(),
        transitionsBuilder: (c, a, b, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (_) => false,
    );
  }

  // Flutter 3.18+ 키 이벤트 API
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final k = event.logicalKey;
      if (k == LogicalKeyboardKey.enter ||
          k == LogicalKeyboardKey.numpadEnter ||
          k == LogicalKeyboardKey.space) {
        _backToSplash();
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
      onTap: _backToSplash,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            color: _bgColor,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ready) ...[
                  // 바닥: 루프 (인트로 끝난 뒤부터 재생)
                  PositionedFillVideo(controller: _loopC),

                  // 위: 인트로 (끝나면 즉시 숨김)
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
                  // 프리로딩/에러 화면
                  Container(
                    color: Colors.white,
                    child: Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                  size: 36,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '결과 영상을 불러올 수 없어요.\n탭 또는 Enter로 처음으로 돌아갑니다.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                // Windows 전용 힌트(웹에선 Platform 접근 금지)
                if (_error != null && !kIsWeb && Platform.isWindows)
                  const Positioned(
                    left: 16,
                    bottom: 24,
                    right: 16,
                    child: Text(
                      '힌트: Windows 배포 시 MP4(H.264 + AAC) 권장.\n'
                      '다른 코덱/컨테이너는 재생이 안 될 수 있어요.',
                      style: TextStyle(color: Colors.black38, fontSize: 12),
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
