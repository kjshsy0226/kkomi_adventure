import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/fruit_enum.dart';
import '../widgets/background_layer.dart';
import '../widgets/center_fruit_with_shine.dart';
import '../widgets/option_pair.dart';
import '../widgets/kkomi_reaction.dart';
import '../widgets/game_controller_bar.dart';
import 'quiz_result_screen.dart';
import 'splash_screen.dart'; // ✅ 홈으로 복귀용

class FruitQuizScreen extends StatefulWidget {
  const FruitQuizScreen({
    super.key,
    this.randomize = true,
    this.autoNext = true,
    this.nextDelay = const Duration(milliseconds: 900),
    this.answerHold = const Duration(milliseconds: 900),
  });

  final bool randomize;
  final bool autoNext;
  final Duration nextDelay;
  final Duration answerHold;

  @override
  State<FruitQuizScreen> createState() => _FruitQuizScreenState();
}

class _FruitQuizScreenState extends State<FruitQuizScreen> {
  // 기준 캔버스(1920×1080)
  static const double baseW = 1920;
  static const double baseH = 1080;

  static const Rect titleRect = Rect.fromLTWH(44, 34, 1001, 144);
  static const Rect slotRect = Rect.fromLTWH(1490, 240, 345, 778);

  // 보기 이미지 파일 풀(총 29개)
  static const String _optionDir = 'assets/images/fruits/options';
  static const List<String> _optionPool29 = [
    'apple',
    'banana',
    'blueberry',
    'carrot',
    'cherry',
    'cucumber',
    'eggplant',
    'grape',
    'kiwi',
    'lemon',
    'manggo',
    'melon',
    'onion',
    'orange',
    'orientalMelon',
    'paprika',
    'pear',
    'persimmon',
    'pineapple',
    'plum',
    'potato',
    'pumpkin',
    'radish',
    'strawberry',
    'sweetPotato',
    'tangerine',
    'tomato',
    'watermelon',
    'zucchini',
  ];

  // 문제 enum → 파일명
  static const Map<Fruit, String> _nameForFile = {
    Fruit.apple: 'apple',
    Fruit.banana: 'banana',
    Fruit.carrot: 'carrot',
    Fruit.cucumber: 'cucumber',
    Fruit.eggplant: 'eggplant',
    Fruit.grape: 'grape',
    Fruit.kiwi: 'kiwi',
    Fruit.melon: 'melon',
    Fruit.onion: 'onion',
    Fruit.orientalMelon: 'orientalMelon',
    Fruit.paprika: 'paprika',
    Fruit.pear: 'pear',
    Fruit.persimmon: 'persimmon',
    Fruit.pineapple: 'pineapple',
    Fruit.pumpkin: 'pumpkin',
    Fruit.radish: 'radish',
    Fruit.strawberry: 'strawberry',
    Fruit.tangerine: 'tangerine',
    Fruit.tomato: 'tomato',
    Fruit.watermelon: 'watermelon',
  };

  String _optionPath(String name) => '$_optionDir/$name.jpg';
  String _correctOptionPath(Fruit f) => _optionPath(_nameForFile[f]!);

  final rand = Random();
  late final List<Fruit> _order;
  int _idx = 0;
  Fruit get _answer => _order[_idx];

  // 보기
  late String _topOptionImg;
  late String _bottomOptionImg;
  late bool _answerIsTop;

  // O/X 표시
  bool _showTopMark = false;
  bool _showBottomMark = false;
  bool _topCorrect = false;
  bool _bottomCorrect = false;
  int _instantHideVersion = 0;

  // 꼬미
  final _kkomiCtrl = KkomiReactionController();
  bool _waitingNext = false;

  // 중앙 과일 + 정답 오버레이 컨트롤러
  final _centerCtrl = CenterFruitWithShineController();

  // BGM
  final AudioPlayer _bgm = AudioPlayer();
  bool _bgmPaused = false;

  @override
  void initState() {
    super.initState();
    _order = kFruitInfo.keys.toList();
    if (widget.randomize) _order.shuffle(rand);
    _makeQuestion();
    _startBgm();
  }

  Future<void> _startBgm() async {
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.play(AssetSource('audio/bgm/game_theme.wav'));
  }

  @override
  void dispose() {
    _bgm.stop();
    _bgm.dispose();
    super.dispose();
  }

  String _pickWrongOption(Fruit ans) {
    final exclude = _nameForFile[ans]!;
    final pool = _optionPool29.where((n) => n != exclude).toList();
    final name = pool[rand.nextInt(pool.length)];
    return _optionPath(name);
  }

  void _makeQuestion() {
    final correct = _correctOptionPath(_answer);
    final wrong = _pickWrongOption(_answer);

    _answerIsTop = rand.nextBool();
    _topOptionImg = _answerIsTop ? correct : wrong;
    _bottomOptionImg = _answerIsTop ? wrong : correct;

    _showTopMark = _showBottomMark = false;
    _topCorrect = _bottomCorrect = false;
    _waitingNext = false;

    if (_kkomiCtrl.mood != KkomiMood.base) _kkomiCtrl.playBase();
    setState(() {});
  }

  void _next() {
    if (_idx < _order.length - 1) {
      _idx++;
      _makeQuestion();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (c, a, b) => const QuizResultScreen(),
          transitionsBuilder: (c, a, b, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  void _prev() {
    if (_idx > 0) {
      _idx--;
      _makeQuestion();
    }
  }

  Future<void> _select(bool pickTop) async {
    final correct = (pickTop && _answerIsTop) || (!pickTop && !_answerIsTop);

    if (pickTop) {
      _topCorrect = correct;
      _showTopMark = true;
      if (correct) {
        _showBottomMark = false;
        _instantHideVersion++;
      }
    } else {
      _bottomCorrect = correct;
      _showBottomMark = true;
      if (correct) {
        _showTopMark = false;
        _instantHideVersion++;
      }
    }
    setState(() {});

    if (correct) {
      if (!widget.autoNext) {
        await _kkomiCtrl.playSuccess();
        return;
      }
      if (_waitingNext) return;
      _waitingNext = true;
      setState(() {});

      // 1) 꼬미 success
      await _kkomiCtrl.playSuccess();
      if (!mounted) return;

      // 2) 같은 위젯에서 정답 오버레이
      await _centerCtrl.showAnswer(widget.answerHold);

      if (!mounted) return;
      _waitingNext = false;
      setState(() {});
      _next();
    } else {
      _kkomiCtrl.playFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1920×1080 비율 유지 (letter-box)
    final sz = MediaQuery.of(context).size;
    final scale = min(sz.width / baseW, sz.height / baseH);
    final canvasW = baseW * scale;
    final canvasH = baseH * scale;
    final leftPad = (sz.width - canvasW) / 2;
    final topPad = (sz.height - canvasH) / 2;

    final canvasRect = Rect.fromLTWH(leftPad, topPad, canvasW, canvasH);

    final shouldLockInput =
        _waitingNext ||
        (_showTopMark && _topCorrect) ||
        (_showBottomMark && _bottomCorrect);

    // 컨트롤러 배치/크기 스케일(캔버스 기준)
    final controllerTop = 35 * scale;
    final controllerRight = 40 * scale;
    final controllerScale = scale;

    return Scaffold(
      body: Stack(
        children: [
          // 캔버스 중앙 정렬
          Positioned(
            left: leftPad,
            top: topPad,
            width: canvasW,
            height: canvasH,
            child: Stack(
              children: [
                // 1) 배경
                BackgroundLayer(fruit: _answer),

                // 1.5) 꼬미 리액션
                KkomiReaction(
                  controller: _kkomiCtrl,
                  canvasRect: canvasRect,
                  fps: 24,
                ),

                // 2) 타이틀
                Positioned(
                  left: titleRect.left * scale,
                  top: titleRect.top * scale,
                  width: titleRect.width * scale,
                  height: titleRect.height * scale,
                  child: Image.asset(
                    'assets/images/ui/title_banner.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),

                // 3) 중앙 과일 + 샤인 + (내장)정답 오버레이
                CenterFruitWithShine(
                  fruit: _answer,
                  controller: _centerCtrl,
                  framesBasePath: 'assets/images/quiz/effects/shine_seq/shine_',
                  frameDigits: 3,
                  frameCount: 4,
                  fps: 12,
                  repeats: 3,
                  autoplay: true,
                  fxDuration: const Duration(milliseconds: 900),
                  enableFx: true,
                ),

                // 4) 우측 보기 슬롯
                IgnorePointer(
                  ignoring: shouldLockInput,
                  child: OptionPair(
                    slotRect: slotRect,
                    scale: scale,
                    slotBgPath: 'assets/images/ui/slot_bg.png',
                    topImagePath: _topOptionImg,
                    bottomImagePath: _bottomOptionImg,
                    onTapTop: () => _select(true),
                    onTapBottom: () => _select(false),
                    showTopMark: _showTopMark,
                    showBottomMark: _showBottomMark,
                    topCorrect: _topCorrect,
                    bottomCorrect: _bottomCorrect,
                    markOPath: 'assets/images/ui/marks/mark_o.png',
                    markXPath: 'assets/images/ui/marks/mark_x.png',
                    inputLocked: shouldLockInput,
                    overlaySeed: _idx,
                    instantHideVersion: _instantHideVersion,
                  ),
                ),

                // 5) ✅ 컨트롤러: 캔버스 우상단, 스케일 반영
                Positioned(
                  top: controllerTop,
                  right: controllerRight,
                  child: Transform.scale(
                    scale: controllerScale,
                    alignment: Alignment.topRight,
                    child: GameControllerBar(
                      isPaused: _bgmPaused,
                      onHome: () async {
                        await _bgm.stop();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          PageRouteBuilder(
                            pageBuilder: (c, a, b) => const SplashScreen(),
                            transitionsBuilder: (c, a, b, child) =>
                                FadeTransition(opacity: a, child: child),
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      onPrev: _prev,
                      onNext: _next,
                      onPauseToggle: () async {
                        if (_bgmPaused) {
                          await _bgm.resume();
                        } else {
                          await _bgm.pause();
                        }
                        if (mounted) setState(() => _bgmPaused = !_bgmPaused);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
