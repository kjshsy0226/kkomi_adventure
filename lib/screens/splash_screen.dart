import 'package:flutter/material.dart';
import 'package:kkomi_adventure/screens/fruit_quiz_screen.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController controller;
  bool navigated = false;

  // addListener가 반환값이 없어서 콜백을 보관했다가 removeListener에 넘겨야 함
  late final VoidCallback onTick;

  @override
  void initState() {
    super.initState();

    controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..setLooping(false);

    onTick = () {
      if (!controller.value.isInitialized) return;

      // 에러나 종료 시 다음 화면으로
      final value = controller.value;
      if (value.hasError ||
          (!value.isPlaying && value.position >= value.duration)) {
        goNext();
      }

      // 첫 프레임/프로그레스 갱신
      if (mounted) setState(() {});
    };

    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          controller.addListener(onTick);
          controller.play();
          setState(() {}); // 첫 프레임 표시
        })
        .catchError((_) {
          goNext();
        });
  }

  void goNext() {
    if (navigated || !mounted) return;
    navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, a, b) => const FruitQuizScreen(),
        transitionsBuilder: (context, a, b, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    controller.removeListener(onTick);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = controller.value.isInitialized;

    return GestureDetector(
      onTap: goNext, // 탭 시 스킵 (옵션)
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
            const Positioned(
              right: 16,
              bottom: 24,
              child: Text('탭하여 건너뛰기', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
