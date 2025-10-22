import 'dart:math';
import 'package:flutter/material.dart';

import '../models/fruit_enum.dart'; // Fruit, kFruitInfo (20문제)
import '../widgets/background_layer.dart'; // BackgroundLayer(fruit: ...)
import '../widgets/center_fruit_with_shine.dart'; // CenterFruitWithShine
import '../widgets/option_pair.dart'; // OptionPair (overlaySeed, inputLocked, instantHideVersion 지원)
import '../widgets/kkomi_reaction.dart'; // KkomiReaction + Controller
import 'quiz_result_screen.dart';

class FruitQuizScreen extends StatefulWidget {
  const FruitQuizScreen({
    super.key,
    this.randomize = true,
    this.autoNext = true,
    this.nextDelay = const Duration(milliseconds: 900),
  });

  final bool randomize;
  final bool autoNext;
  final Duration nextDelay;

  @override
  State<FruitQuizScreen> createState() => _FruitQuizScreenState();
}

class _FruitQuizScreenState extends State<FruitQuizScreen> {
  // 기준 캔버스(1920×1080) & 고정 좌표
  static const double baseW = 1920;
  static const double baseH = 1080;

  static const Rect titleRect = Rect.fromLTWH(44, 34, 1001, 144);
  static const Rect slotRect = Rect.fromLTWH(1490, 240, 345, 778);
  static const Rect centerRect = Rect.fromLTWH(610, 140, 700, 700);

  // 보기 이미지 파일 풀(총 29개) — options/ 폴더 파일명과 정확히 일치
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

  // 문제(20개) enum → 파일명
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
  late final List<Fruit> _order; // 20문제 순서
  int _idx = 0;
  Fruit get _answer => _order[_idx];

  // 현재 문제의 보기 두 장
  late String _topOptionImg;
  late String _bottomOptionImg;
  late bool _answerIsTop;

  // O/X 표시 상태
  bool _showTopMark = false;
  bool _showBottomMark = false;
  bool _topCorrect = false;
  bool _bottomCorrect = false;

  // 반대편 X 즉시 숨김 트리거
  int _instantHideVersion = 0; // ✅

  // 꼬미 리액션 컨트롤러 + 중복 이동 방지
  final _kkomiCtrl = KkomiReactionController();
  bool _waitingNext = false;

  @override
  void initState() {
    super.initState();
    _order = kFruitInfo.keys.toList();
    if (widget.randomize) _order.shuffle(rand);
    _makeQuestion();
  }

  // 29개 풀에서 정답과 다른 이름 하나 추출
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

    // 새 문제 뜰 때 꼬미는 base로 (중복 전환 방지)
    if (_kkomiCtrl.mood != KkomiMood.base) {
      _kkomiCtrl.playBase();
    }

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

  Future<void> _select(bool pickTop) async {
    final correct = (pickTop && _answerIsTop) || (!pickTop && !_answerIsTop);

    if (pickTop) {
      _topCorrect = correct;
      _showTopMark = true;

      if (correct) {
        // ✅ 정답을 위에서 골랐으면 아래쪽 X는 즉시 숨김
        _showBottomMark = false;
        _instantHideVersion++; // ✅ 오버레이에 즉시 OFF 신호
      }
    } else {
      _bottomCorrect = correct;
      _showBottomMark = true;

      if (correct) {
        // ✅ 정답을 아래에서 골랐으면 위쪽 X는 즉시 숨김
        _showTopMark = false;
        _instantHideVersion++; // ✅ 오버레이에 즉시 OFF 신호
      }
    }
    setState(() {});

    if (correct) {
      // ✅ 정답: success 리액션 1사이클 종료를 기다린 뒤 다음 문제
      if (!widget.autoNext) {
        await _kkomiCtrl.playSuccess();
        return;
      }
      if (_waitingNext) return;
      _waitingNext = true; // 터치 잠금 트리거
      setState(() {});

      await _kkomiCtrl.playSuccess(); // success 끝나는 순간까지 대기

      if (!mounted) return;
      // (원하면 추가 지연)
      // await Future.delayed(widget.nextDelay);

      _waitingNext = false;
      _next();
    } else {
      // ❌ 오답: 실패 리액션만 재생(자동 base 복귀), 문제는 그대로 유지
      _kkomiCtrl.playFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 스케일/패딩 계산
    final sz = MediaQuery.of(context).size;
    final scale = min(sz.width / baseW, sz.height / baseH);
    final canvasW = baseW * scale;
    final canvasH = baseH * scale;
    final leftPad = (sz.width - canvasW) / 2;
    final topPad = (sz.height - canvasH) / 2;

    // 꼬미가 덮을 캔버스 사각형(1920×1080 위치)
    final canvasRect = Rect.fromLTWH(leftPad, topPad, canvasW, canvasH);

    // ✅ 정답 상태이거나 success 대기 중이면 입력 잠금
    final shouldLockInput =
        _waitingNext ||
        (_showTopMark && _topCorrect) ||
        (_showBottomMark && _bottomCorrect);

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

                // 1.5) 꼬미 리액션(배경 위, 다른 UI 뒤)
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

                // 3) 중앙 과일 + 샤인
                CenterFruitWithShine(
                  fruit: _answer,
                  rect: centerRect,
                  scale: scale,
                  framesBasePath: 'assets/images/quiz/effects/shine_seq/shine_',
                  frameDigits: 3,
                  frameCount: 4,
                  fps: 12,
                  repeats: 3,
                  autoplay: true,
                  fxDuration: const Duration(milliseconds: 900),
                  enableFx: true,
                ),

                // 4) 우측 보기 슬롯 (정답이면 전체 잠금)
                IgnorePointer(
                  ignoring: shouldLockInput, // ✅ 정답 동안 터치 차단
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
                    inputLocked: shouldLockInput, // ✅ 정답 시 터치 차단
                    overlaySeed: _idx, // ✅ 문제 전환마다 오버레이 state 초기화
                    instantHideVersion: _instantHideVersion, // ✅ 즉시 OFF 트리거
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
