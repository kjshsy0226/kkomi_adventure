import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/fruit_enum.dart';
import '../widgets/center_fruit_with_shine.dart';
import '../widgets/option_pair.dart';
import '../widgets/kkomi_reaction_video.dart';
import '../widgets/game_controller_bar.dart';
import 'quiz_result_screen.dart';
import 'splash_screen.dart';

class FruitQuizScreen extends StatefulWidget {
  const FruitQuizScreen({
    super.key,
    this.randomize = true,
    this.autoNext = true,
    this.nextDelay = const Duration(milliseconds: 900),
    this.answerHold = const Duration(milliseconds: 1800),
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

  // 보기 이미지 파일 풀(옵션용 - 에셋 있는 이름만 두세요)
  static const String _optionDir = 'assets/images/fruits/options';
  static const List<String> _optionPool28 = [
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
    'manggo', // 프로젝트 에셋명이 이 표기면 그대로 두세요
    'melon',
    'onion',
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

  /// 문제(enum) -> 파일명 매핑(있는 것만 채우고, 나머지는 자동 폴백)
  static const Map<Fruit, String> _nameForFile = {
    // 필요 시 채우세요. 없으면 자동으로 enum 이름을 사용합니다.
    Fruit.carrot: 'carrot',
    Fruit.pineapple: 'pineapple',
    // 예시:
    // Fruit.apple: 'apple',
    // Fruit.watermelon: 'watermelon',
    // ...
  };

  String _optionPath(String name) => '$_optionDir/$name.jpg';

  /// 안전한 파일명 계산: 매핑 없으면 enum 이름을 파일명으로 사용
  String _fileNameFor(Fruit f) {
    final mapped = _nameForFile[f];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    // enum 이름: Fruit.apple -> 'apple'
    final raw = f.toString().split('.').last;
    return raw; // camelCase 그대로 사용(ex: orientalMelon)
  }

  /// 정답 보기 이미지 경로(Null-Safe)
  String _correctOptionPath(Fruit f) => _optionPath(_fileNameFor(f));

  final rand = Random();

  /// 출제 순서
  late final List<Fruit> _order;
  int _idx = 0;
  Fruit get _answer => _order[_idx];

  // 보기 상태
  late String _topOptionImg;
  late String _bottomOptionImg;
  late bool _answerIsTop;

  // O/X 표시
  bool _showTopMark = false;
  bool _showBottomMark = false;
  bool _topCorrect = false;
  bool _bottomCorrect = false;
  int _instantHideVersion = 0;

  // 꼬미 리액션 컨트롤러
  final _kkomiCtrl = KkomiReactionController();
  bool _waitingNext = false;

  // 중앙 과일 + 샤인 컨트롤러
  final _centerCtrl = CenterFruitWithShineController();

  // BGM
  final AudioPlayer _bgm = AudioPlayer();
  bool _bgmPaused = false;

  @override
  void initState() {
    super.initState();

    // 출제 풀: kFruitInfo의 key 전체 사용 (파일명은 폴백으로 처리)
    _order = kFruitInfo.keys.toList();
    if (_order.isEmpty) {
      debugPrint('❗ kFruitInfo가 비어있습니다. Fruit 데이터 확인 필요');
      // 비상 복구: 앱이 바로 죽지 않도록 임시 가드(실사용에선 데이터를 채우세요)
    }
    if (widget.randomize) _order.shuffle(rand);

    _makeQuestion();
    _startBgm();
  }

  Future<void> _startBgm() async {
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setVolume(0.4);
    await _bgm.play(AssetSource('audio/bgm/game_theme.wav'));
  }

  @override
  void dispose() {
    _bgm.stop();
    _bgm.dispose();
    super.dispose();
  }

  // 홈 이동
  Future<void> _goHome() async {
    await _bgm.stop();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (c, a, b) => const SplashScreen(),
        transitionsBuilder: (c, a, b, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  /// 오답 보기 선택(정답 파일명과 다른 이름 중 랜덤)
  String _pickWrongOption(Fruit ans) {
    final exclude = _fileNameFor(ans); // 매핑/폴백 일관
    final pool = _optionPool28.where((n) => n != exclude).toList();
    if (pool.isEmpty) {
      debugPrint('❗ 오답 풀 비어있음. 옵션 풀을 확인하세요.');
      return _optionPath(exclude); // 최악의 경우 동일 보기라도 반환(크래시 방지)
    }
    final name = pool[rand.nextInt(pool.length)];
    return _optionPath(name);
  }

  void _makeQuestion() {
    if (_order.isEmpty) {
      // 비상 방어
      _topOptionImg = _optionPath('apple');
      _bottomOptionImg = _optionPath('banana');
      _answerIsTop = true;
      setState(() {});
      return;
    }

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

  // 첫 문제에서 이전 → 홈 이동
  void _prev() {
    if (_idx > 0) {
      _idx--;
      _makeQuestion();
    } else {
      _goHome();
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

      try {
        final successF = _kkomiCtrl.playSuccess();
        final overlayF = _centerCtrl.showAnswer(widget.answerHold);
        await Future.wait([successF, overlayF]);
        if (!mounted) return;
        _waitingNext = false;
        setState(() {});
        _next();
      } catch (_) {
        if (!mounted) return;
        _waitingNext = false;
        setState(() {});
        _next();
      }
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
                // 1) 꼬미 리액션 (영상 기반)
                KkomiReactionVideo(
                  controller: _kkomiCtrl,
                  fruit: _answer,
                  canvasRect: canvasRect,
                ),

                // 2) 중앙 과일 + 샤인 + 정답 오버레이
                CenterFruitWithShine(
                  fruit: _answer,
                  controller: _centerCtrl,
                  framesBasePath: 'assets/images/effects/shine_seq/shine_',
                  frameDigits: 3,
                  frameCount: 5,
                  fps: 12,
                  repeats: 3,
                  autoplay: true,
                  fxDuration: const Duration(milliseconds: 900),
                  enableFx: true,
                ),

                // 3) 타이틀
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

                // 5) 컨트롤러: 캔버스 우상단
                Positioned(
                  top: controllerTop,
                  right: controllerRight,
                  child: Transform.scale(
                    scale: controllerScale,
                    alignment: Alignment.topRight,
                    child: GameControllerBar(
                      isPaused: _bgmPaused,
                      onHome: _goHome,
                      onPrev: _prev,
                      onNext: _next,
                      onPauseToggle: () async {
                        if (_bgmPaused) {
                          await _bgm.resume();
                          await _bgm.setVolume(0.4);
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
