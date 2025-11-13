import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kkomi_adventure/widgets/background_layer.dart';

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
    this.answerHold = const Duration(milliseconds: 1800),
  });

  final bool randomize;
  final bool autoNext;
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

  // 보기 이미지 파일 풀
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
    'manggo',
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

  /// enum -> 파일명 매핑
  static const Map<Fruit, String> _nameForFile = {
    Fruit.carrot: 'carrot',
    Fruit.pineapple: 'pineapple',
  };

  String _optionPath(String name) => '$_optionDir/$name.jpg';

  String _fileNameFor(Fruit f) {
    final mapped = _nameForFile[f];
    if (mapped != null && mapped.isNotEmpty) return mapped;
    return f.toString().split('.').last;
  }

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

  // 동시 게이트용 플래그
  bool _questionReady = false;
  bool _reactionReady = false;

  @override
  void initState() {
    super.initState();

    _order = kFruitInfo.keys.toList();
    if (_order.isEmpty) {
      debugPrint('❗ kFruitInfo가 비어있습니다. Fruit 데이터 확인 필요');
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

  String _pickWrongOption(Fruit ans) {
    final exclude = _fileNameFor(ans);
    final pool = _optionPool28.where((n) => n != exclude).toList();
    if (pool.isEmpty) {
      debugPrint('❗ 오답 풀 비어있음. 옵션 풀을 확인하세요.');
      return _optionPath(exclude);
    }
    final name = pool[rand.nextInt(pool.length)];
    return _optionPath(name);
  }

  Future<void> _precacheQuestionAssets(BuildContext ctx, double scale) async {
    final futures = <Future<dynamic>>[];

    futures.add(precacheImage(
        const AssetImage('assets/images/ui/title_banner.png'), ctx));
    futures.add(precacheImage(
        const AssetImage('assets/images/ui/slot_bg.png'), ctx));
    futures.add(precacheImage(
        const AssetImage('assets/images/ui/marks/mark_o.png'), ctx));
    futures.add(precacheImage(
        const AssetImage('assets/images/ui/marks/mark_x.png'), ctx));

    futures.add(precacheImage(AssetImage(_topOptionImg), ctx));
    futures.add(precacheImage(AssetImage(_bottomOptionImg), ctx));

    try {
      await Future.wait(futures);
    } catch (_) {}
    if (mounted) setState(() => _questionReady = true);
  }

  void _resetGates() {
    _questionReady = false;
    _reactionReady = false;
  }

  void _makeQuestion() {
    if (_order.isEmpty) {
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

    _resetGates();
    setState(() {});
  }

  Future<void> _next() async {
    if (_idx < _order.length - 1) {
      _idx++;
      _makeQuestion();
    } else {
      if (!mounted) return;
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

  Future<void> _prev() async {
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
      // ✅ 정답 로직: success 끝까지 + 정답 오버레이는 충분히 오래 유지
      if (!widget.autoNext) {
        await _kkomiCtrl.playSuccess();
        return;
      }
      if (_waitingNext) return;
      _waitingNext = true;
      setState(() {});

      try {
        // 🔹 정답 오버레이는 "충분히 긴 시간" 동안 켜둔다 (성공 영상보다 길게)
        final overlayHold = Duration(
          milliseconds: max(widget.answerHold.inMilliseconds, 4500),
        );
        _centerCtrl.showAnswer(overlayHold); // fire-and-forget

        // 🔹 실제로 기다리는 건 success 끝날 때까지
        await _kkomiCtrl.playSuccess();

        if (!mounted) return;
        _waitingNext = false;
        setState(() {});
        await _next(); // 이 시점까지 정답은 계속 보이는 상태
      } catch (_) {
        if (!mounted) return;
        _waitingNext = false;
        setState(() {});
        await _next();
      }
    } else {
      _kkomiCtrl.playFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    final scale = min(sz.width / baseW, sz.height / baseH);
    final canvasW = baseW * scale;
    final canvasH = baseH * scale;
    final leftPad = (sz.width - canvasW) / 2;
    final topPad = (sz.height - canvasH) / 2;

    final localCanvasRect = Rect.fromLTWH(0, 0, canvasW, canvasH);

    final shouldLockInput =
        _waitingNext ||
        (_showTopMark && _topCorrect) ||
        (_showBottomMark && _bottomCorrect);

    if (!_questionReady) {
      _precacheQuestionAssets(context, scale);
    }

    final allReady = _questionReady && _reactionReady;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: leftPad,
            top: topPad,
            width: canvasW,
            height: canvasH,
            child: Stack(
              children: [
                BackgroundLayer(fruit: _answer),

                KkomiReactionVideo(
                  controller: _kkomiCtrl,
                  fruit: _answer,
                  canvasRect: localCanvasRect,
                  onReady: () => setState(() => _reactionReady = true),
                ),

                if (allReady) ...[
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
                ],

                Positioned(
                  top: 35 * scale,
                  right: 40 * scale,
                  child: Transform.scale(
                    scale: scale,
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
