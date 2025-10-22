import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'splash_screen.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final VideoPlayerController _controller;
  bool _inited = false;
  bool _navigating = false;

  late final VoidCallback _onTick;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/result.mp4')
      ..setLooping(false);

    _onTick = () {
      if (!_controller.value.isInitialized) return;

      final v = _controller.value;

      // 에러 발생 시: 그대로 멈추고 사용자 탭 기다림
      if (v.hasError) {
        _controller.pause();
        return;
      }

      // 종료 조건: 재생이 멈췄고, position >= duration (약간의 오차 허용)
      if (!v.isPlaying) {
        final dur = v.duration;
        final pos = v.position;
        if (pos >= dur - const Duration(milliseconds: 50)) {
          // 마지막 프레임에서 정지 유지
          _controller.pause();
        }
      }

      if (mounted) setState(() {});
    };

    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          _controller.addListener(_onTick);
          _inited = true;
          setState(() {});

          // 자동 재생
          _controller.play();
        })
        .catchError((_) {
          // 초기화 실패시에도 UI는 뜨고, 탭하여 처음으로 돌아갈 수 있게
          if (mounted) setState(() {});
        });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _backToSplash() {
    if (_navigating || !mounted) return;
    _navigating = true;

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

  @override
  Widget build(BuildContext context) {
    final ready = _inited && _controller.value.isInitialized;

    return GestureDetector(
      onTap: _backToSplash, // 탭하면 처음으로
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            const Positioned(
              right: 16,
              bottom: 24,
              child: Text(
                '탭하여 처음으로',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
