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

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..setLooping(false);

    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          // 자동 이동 ❌, 자동 루프 ❌
          controller.play();
          setState(() {}); // 첫 프레임
        })
        .catchError((_) {
          // 에러 시에도 화면은 유지, 탭으로만 진행
          setState(() {});
        });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void goNext() {
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
  Widget build(BuildContext context) {
    final ready = controller.value.isInitialized;

    return GestureDetector(
      onTap: goNext, // ✅ 탭해서만 시작
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
              child: Text('탭하여 시작', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
