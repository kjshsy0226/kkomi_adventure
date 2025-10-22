import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/window_fit.dart';
import '../widgets/background_image.dart';
import '../widgets/top_control_bar.dart';
import '../widgets/mode_card.dart';

// 새로 추가: 두 화면으로 이동하기 위한 import
import 'learn_animation_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AudioPlayer _bgm;
  bool _isPlaying = false;
  double _volume = 0.6;

  @override
  void initState() {
    super.initState();
    _bgm = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    _initBgm();

    // 앱이 풀스크린이 아닐 때도 16:9 최대 1920x1080 맞추기
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isFull = await windowManager.isFullScreen();
      if (!isFull) await fitWindowToDisplay();
    });
  }

  Future<void> _initBgm() async {
    try {
      await _bgm.setSource(AssetSource('audio/bgm.mp3'));
      await _bgm.setVolume(_volume);
      await _bgm.resume();
      setState(() => _isPlaying = true);
    } catch (_) {
      // 에셋 없으면 무시
    }
  }

  @override
  void dispose() {
    _bgm.dispose();
    super.dispose();
  }

  Future<void> _toggleFullScreen() async {
    final isFull = await windowManager.isFullScreen();
    if (isFull) {
      await windowManager.setFullScreen(false);
      await fitWindowToDisplay(); // 해제 시 16:9로 리사이즈/센터
    } else {
      await windowManager.setFullScreen(true);
    }
    setState(() {});
  }

  Future<void> _toggleBgm() async {
    if (_isPlaying) {
      await _bgm.pause();
    } else {
      await _bgm.resume();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, // 레터박스 색
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const BackgroundImage(),
              Align(
                alignment: Alignment.topRight,
                child: TopControlBar(
                  isPlaying: _isPlaying,
                  volume: _volume,
                  onTogglePlay: _toggleBgm,
                  onChangeVolume: (v) async {
                    setState(() => _volume = v);
                    await _bgm.setVolume(v);
                  },
                  onToggleFullScreen: _toggleFullScreen,
                ),
              ),
              // === 여기 수정 완료: 학습/게임 화면 네비게이션 연결 ===
              Center(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LearnAnimationScreen(),
                        ),
                      ),
                      child: const ModeCard(
                        title: '학습 애니메이션 모드',
                        desc: '애니메이션을 보며 학습하는 화면으로 이동',
                        icon: Icons.movie_creation_rounded,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      ),
                      child: const ModeCard(
                        title: '게임 모드',
                        desc: '터치로 맞추는 게임 화면으로 이동',
                        icon: Icons.videogame_asset_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              // ======================================================
            ],
          ),
        ),
      ),
    );
  }
}
