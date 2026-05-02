// 트랜지션 버전
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:kkomi_adventure/widgets/background_layer.dart';

// import '../models/fruit_enum.dart';
// import '../widgets/center_fruit_with_shine.dart';
// import '../widgets/option_pair.dart';
// import '../widgets/game_controller_bar.dart';
// import 'quiz_result_screen.dart';
// import 'splash_screen.dart';

// /// 정적 꼬미 상태용 enum
// enum SimpleKkomiMood { base, success, failure }

// class FruitQuizScreen extends StatefulWidget {
//   const FruitQuizScreen({
//     super.key,
//     this.randomize = true,
//     this.autoNext = true,
//     this.answerHold = const Duration(milliseconds: 1800),
//   });

//   final bool randomize;
//   final bool autoNext;
//   final Duration answerHold;

//   @override
//   State<FruitQuizScreen> createState() => _FruitQuizScreenState();
// }

// class _FruitQuizScreenState extends State<FruitQuizScreen> {
//   // 기준 캔버스(1920×1080)
//   static const double baseW = 1920;
//   static const double baseH = 1080;

//   static const Rect titleRect = Rect.fromLTWH(44, 34, 1001, 144);
//   static const Rect slotRect = Rect.fromLTWH(1490, 240, 345, 778);

//   // 보기 이미지 파일 풀
//   static const String _optionDir = 'assets/images/fruits/options';
//   static const List<String> _optionPool28 = [
//     'apple',
//     'banana',
//     'blueberry',
//     'carrot',
//     'cherry',
//     'cucumber',
//     'eggplant',
//     'grape',
//     'kiwi',
//     'lemon',
//     'manggo',
//     'melon',
//     'onion',
//     'orientalMelon',
//     'paprika',
//     'pear',
//     'persimmon',
//     'pineapple',
//     'plum',
//     'potato',
//     'pumpkin',
//     'radish',
//     'strawberry',
//     'sweetPotato',
//     'tangerine',
//     'tomato',
//     'watermelon',
//     'zucchini',
//   ];

//   /// enum -> 파일명 매핑
//   static const Map<Fruit, String> _nameForFile = {
//     Fruit.carrot: 'carrot',
//     Fruit.pineapple: 'pineapple',
//   };

//   String _optionPath(String name) => '$_optionDir/$name.jpg';

//   String _fileNameFor(Fruit f) {
//     final mapped = _nameForFile[f];
//     if (mapped != null && mapped.isNotEmpty) return mapped;
//     return f.toString().split('.').last;
//   }

//   String _correctOptionPath(Fruit f) => _optionPath(_fileNameFor(f));

//   final rand = Random();

//   /// 출제 순서
//   late final List<Fruit> _order;
//   int _idx = 0;
//   Fruit get _answer => _order[_idx];

//   // 보기 상태
//   late String _topOptionImg;
//   late String _bottomOptionImg;
//   late bool _answerIsTop;

//   // O/X 표시
//   bool _showTopMark = false;
//   bool _showBottomMark = false;
//   bool _topCorrect = false;
//   bool _bottomCorrect = false;
//   int _instantHideVersion = 0;

//   // 꼬미 정적 이미지 상태 (setState 안 쓰고 따로 관리)
//   late final ValueNotifier<SimpleKkomiMood> _kkomiMoodNotifier;

//   // 다음 문제로 넘어가기 대기 상태
//   bool _waitingNext = false;

//   // 중앙 과일 + 샤인 컨트롤러
//   final _centerCtrl = CenterFruitWithShineController();

//   // BGM
//   final AudioPlayer _bgm = AudioPlayer();
//   bool _bgmPaused = false;

//   // 정오답 효과음용 SFX 플레이어
//   final AudioPlayer _sfx = AudioPlayer();

//   @override
//   void initState() {
//     super.initState();

//     _kkomiMoodNotifier = ValueNotifier<SimpleKkomiMood>(SimpleKkomiMood.base);

//     _order = kFruitInfo.keys.toList();
//     if (_order.isEmpty) {
//       debugPrint('❗ kFruitInfo가 비어있습니다. Fruit 데이터 확인 필요');
//     }
//     if (widget.randomize) _order.shuffle(rand);

//     _makeQuestion();
//     _startBgm();
//   }

//   @override
//   void dispose() {
//     _bgm.stop();
//     _bgm.dispose();
//     _sfx.stop();
//     _sfx.dispose();
//     _kkomiMoodNotifier.dispose();
//     super.dispose();
//   }

//   Future<void> _startBgm() async {
//     await _bgm.setReleaseMode(ReleaseMode.loop);
//     await _bgm.setVolume(0.4);
//     await _bgm.play(AssetSource('audio/bgm/game_theme.wav'));
//   }

//   Future<void> _playSuccessSfx() async {
//     try {
//       await _sfx.stop();
//       await _sfx.setVolume(1.0);
//       await _sfx.play(AssetSource('audio/sfx/success.wav'));
//     } catch (e) {
//       debugPrint('⚠️ success SFX 재생 실패: $e');
//     }
//   }

//   Future<void> _playFailureSfx() async {
//     try {
//       await _sfx.stop();
//       await _sfx.setVolume(1.0);
//       await _sfx.play(AssetSource('audio/sfx/failure.wav'));
//     } catch (e) {
//       debugPrint('⚠️ failure SFX 재생 실패: $e');
//     }
//   }

//   Future<void> _goHome() async {
//     await _bgm.stop();
//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//       PageRouteBuilder(
//         pageBuilder: (c, a, b) => const SplashScreen(),
//         transitionsBuilder: (c, a, b, child) =>
//             FadeTransition(opacity: a, child: child),
//         transitionDuration: const Duration(milliseconds: 300),
//       ),
//       (route) => false,
//     );
//   }

//   String _pickWrongOption(Fruit ans) {
//     final exclude = _fileNameFor(ans);
//     final pool = _optionPool28.where((n) => n != exclude).toList();
//     if (pool.isEmpty) {
//       debugPrint('❗ 오답 풀 비어있음. 옵션 풀을 확인하세요.');
//       return _optionPath(exclude);
//     }
//     final name = pool[rand.nextInt(pool.length)];
//     return _optionPath(name);
//   }

//   void _makeQuestion() {
//     if (_order.isEmpty) {
//       _topOptionImg = _optionPath('apple');
//       _bottomOptionImg = _optionPath('banana');
//       _answerIsTop = true;
//       setState(() {});
//       return;
//     }

//     final correct = _correctOptionPath(_answer);
//     final wrong = _pickWrongOption(_answer);

//     _answerIsTop = rand.nextBool();
//     _topOptionImg = _answerIsTop ? correct : wrong;
//     _bottomOptionImg = _answerIsTop ? wrong : correct;

//     _showTopMark = _showBottomMark = false;
//     _topCorrect = _bottomCorrect = false;
//     _instantHideVersion = 0;
//     _waitingNext = false;

//     // 꼬미 상태 기본으로 리셋 (setState 없이)
//     _kkomiMoodNotifier.value = SimpleKkomiMood.base;

//     setState(() {});
//   }

//   Future<void> _next() async {
//     if (_idx < _order.length - 1) {
//       _idx++;
//       _makeQuestion();
//     } else {
//       if (!mounted) return;
//       Navigator.of(context).pushReplacement(
//         PageRouteBuilder(
//           pageBuilder: (c, a, b) => const QuizResultScreen(),
//           transitionsBuilder: (c, a, b, child) =>
//               FadeTransition(opacity: a, child: child),
//           transitionDuration: const Duration(milliseconds: 300),
//         ),
//       );
//     }
//   }

//   Future<void> _prev() async {
//     if (_idx > 0) {
//       _idx--;
//       _makeQuestion();
//     } else {
//       _goHome();
//     }
//   }

//   String _assetPathForMood(SimpleKkomiMood mood) {
//     switch (mood) {
//       case SimpleKkomiMood.base:
//         return 'assets/images/kkomi/base.png';
//       case SimpleKkomiMood.success:
//         return 'assets/images/kkomi/success.png';
//       case SimpleKkomiMood.failure:
//         return 'assets/images/kkomi/failure.png';
//     }
//   }

//   Future<void> _select(bool pickTop) async {
//     // ✅ 이미 정답 처리 중이거나 정답 마크가 떠 있으면 입력 무시 (중복 O/X 방지)
//     final inputLocked =
//         _waitingNext ||
//         (_showTopMark && _topCorrect) ||
//         (_showBottomMark && _bottomCorrect);
//     if (inputLocked) return;

//     final correct = (pickTop && _answerIsTop) || (!pickTop && !_answerIsTop);

//     if (pickTop) {
//       _topCorrect = correct;
//       _showTopMark = true;
//       if (correct) {
//         _showBottomMark = false;
//         _instantHideVersion++;
//       }
//     } else {
//       _bottomCorrect = correct;
//       _showBottomMark = true;
//       if (correct) {
//         _showTopMark = false;
//         _instantHideVersion++;
//       }
//     }

//     // 꼬미 이미지 상태 변경 (setState 없이)
//     _kkomiMoodNotifier.value =
//         correct ? SimpleKkomiMood.success : SimpleKkomiMood.failure;

//     setState(() {});

//     if (correct) {
//       // ✅ 정답 + 성공 효과음
//       await _playSuccessSfx();

//       if (!widget.autoNext) {
//         return;
//       }

//       if (_waitingNext) return;
//       _waitingNext = true;
//       setState(() {});

//       // 정답 이펙트 (샤인)
//       _centerCtrl.showAnswer(widget.answerHold); // fire-and-forget

//       // 정답 상태 잠깐 유지
//       await Future.delayed(widget.answerHold);

//       if (!mounted) {
//         _waitingNext = false;
//         return;
//       }

//       _waitingNext = false;
//       setState(() {});
//       await _next();
//     } else {
//       // ❌ 오답 + 실패 효과음
//       await _playFailureSfx();

//       // ⏱ 오답 마크가 사라질 타이밍에 맞춰 꼬미를 다시 base로
//       Future.delayed(const Duration(milliseconds: 900), () {
//         if (!mounted) return;
//         if (_kkomiMoodNotifier.value == SimpleKkomiMood.failure) {
//           _kkomiMoodNotifier.value = SimpleKkomiMood.base;
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final sz = MediaQuery.of(context).size;
//     final scale = min(sz.width / baseW, sz.height / baseH);
//     final canvasW = baseW * scale;
//     final canvasH = baseH * scale;
//     final leftPad = (sz.width - canvasW) / 2;
//     final topPad = (sz.height - canvasH) / 2;

//     final shouldLockInput =
//         _waitingNext ||
//         (_showTopMark && _topCorrect) ||
//         (_showBottomMark && _bottomCorrect);

//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned(
//             left: leftPad,
//             top: topPad,
//             width: canvasW,
//             height: canvasH,
//             child: Stack(
//               children: [
//                 // 배경
//                 BackgroundLayer(fruit: _answer),

//                 // 꼬미 정적 이미지 (캔버스 전체, mood 전용 빌더)
//                 Positioned(
//                   left: 0,
//                   top: 0,
//                   width: canvasW,
//                   height: canvasH,
//                   child: IgnorePointer(
//                     child: ValueListenableBuilder<SimpleKkomiMood>(
//                       valueListenable: _kkomiMoodNotifier,
//                       builder: (context, mood, _) {
//                         final path = _assetPathForMood(mood);
//                         return AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 250),
//                           transitionBuilder: (child, animation) =>
//                               FadeTransition(
//                                 opacity: animation,
//                                 child: child,
//                               ),
//                           child: SizedBox.expand(
//                             key: ValueKey(path),
//                             child: Image.asset(
//                               path,
//                               fit: BoxFit.cover,
//                               alignment: Alignment.center,
//                               errorBuilder: (c, e, s) =>
//                                   const SizedBox.shrink(),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),

//                 // 중앙 과일 + 샤인
//                 CenterFruitWithShine(
//                   fruit: _answer,
//                   controller: _centerCtrl,
//                   framesBasePath: 'assets/images/effects/shine_seq/shine_',
//                   frameDigits: 3,
//                   frameCount: 5,
//                   fps: 12,
//                   repeats: 3,
//                   autoplay: true,
//                   fxDuration: const Duration(milliseconds: 900),
//                   enableFx: true,
//                 ),

//                 // 타이틀 배너
//                 Positioned(
//                   left: titleRect.left * scale,
//                   top: titleRect.top * scale,
//                   width: titleRect.width * scale,
//                   height: titleRect.height * scale,
//                   child: Image.asset(
//                     'assets/images/ui/title_banner.png',
//                     fit: BoxFit.contain,
//                     errorBuilder: (c, e, s) => const SizedBox.shrink(),
//                   ),
//                 ),

//                 // 보기 옵션
//                 IgnorePointer(
//                   ignoring: shouldLockInput,
//                   child: OptionPair(
//                     slotRect: slotRect,
//                     scale: scale,
//                     slotBgPath: 'assets/images/ui/slot_bg.png',
//                     topImagePath: _topOptionImg,
//                     bottomImagePath: _bottomOptionImg,
//                     onTapTop: () => _select(true),
//                     onTapBottom: () => _select(false),
//                     showTopMark: _showTopMark,
//                     showBottomMark: _showBottomMark,
//                     topCorrect: _topCorrect,
//                     bottomCorrect: _bottomCorrect,
//                     markOPath: 'assets/images/ui/marks/mark_o.png',
//                     markXPath: 'assets/images/ui/marks/mark_x.png',
//                     inputLocked: shouldLockInput,
//                     overlaySeed: _idx,
//                     instantHideVersion: _instantHideVersion,
//                   ),
//                 ),

//                 // 상단 컨트롤 바
//                 Positioned(
//                   top: 35 * scale,
//                   right: 40 * scale,
//                   child: Transform.scale(
//                     scale: scale,
//                     alignment: Alignment.topRight,
//                     child: GameControllerBar(
//                       isPaused: _bgmPaused,
//                       onHome: _goHome,
//                       onPrev: _prev,
//                       onNext: _next,
//                       onPauseToggle: () async {
//                         if (_bgmPaused) {
//                           await _bgm.resume();
//                           await _bgm.setVolume(0.4);
//                         } else {
//                           await _bgm.pause();
//                         }
//                         if (mounted) {
//                           setState(() => _bgmPaused = !_bgmPaused);
//                         }
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// 최적화 버전
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kkomi_adventure/widgets/background_layer.dart';

import '../models/fruit_enum.dart';
import '../widgets/center_fruit_with_shine.dart';
import '../widgets/option_pair.dart';
import '../widgets/game_controller_bar.dart';
import 'quiz_result_screen.dart';
import 'splash_screen.dart';

/// 정적 꼬미 상태용 enum
enum SimpleKkomiMood { base, success, failure }

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

  // 꼬미 정적 이미지 상태 (setState 안 쓰고 따로 관리)
  late final ValueNotifier<SimpleKkomiMood> _kkomiMoodNotifier;

  // 다음 문제로 넘어가기 대기 상태
  bool _waitingNext = false;

  // 중앙 과일 + 샤인 컨트롤러
  final _centerCtrl = CenterFruitWithShineController();

  // BGM
  final AudioPlayer _bgm = AudioPlayer();
  bool _bgmPaused = false;

  // 정오답 효과음용 SFX 플레이어
  final AudioPlayer _sfx = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _kkomiMoodNotifier = ValueNotifier<SimpleKkomiMood>(SimpleKkomiMood.base);

    _order = kFruitInfo.keys.toList();
    if (_order.isEmpty) {
      debugPrint('❗ kFruitInfo가 비어있습니다. Fruit 데이터 확인 필요');
    }
    if (widget.randomize) _order.shuffle(rand);

    _makeQuestion();
    _startBgm();
  }

  @override
  void dispose() {
    _bgm.stop();
    _bgm.dispose();
    _sfx.stop();
    _sfx.dispose();
    _kkomiMoodNotifier.dispose();
    super.dispose();
  }

  Future<void> _startBgm() async {
    await _bgm.setReleaseMode(ReleaseMode.loop);
    await _bgm.setVolume(0.4);
    await _bgm.play(AssetSource('audio/bgm/game_theme.wav'));
  }

  Future<void> _playSuccessSfx() async {
    try {
      await _sfx.stop();
      await _sfx.setVolume(1.0);
      await _sfx.play(AssetSource('audio/sfx/success.wav'));
    } catch (e) {
      debugPrint('⚠️ success SFX 재생 실패: $e');
    }
  }

  Future<void> _playFailureSfx() async {
    try {
      await _sfx.stop();
      await _sfx.setVolume(1.0);
      await _sfx.play(AssetSource('audio/sfx/failure.wav'));
    } catch (e) {
      debugPrint('⚠️ failure SFX 재생 실패: $e');
    }
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
    _instantHideVersion = 0;
    _waitingNext = false;

    // 꼬미 상태 기본으로 리셋 (setState 없이)
    _kkomiMoodNotifier.value = SimpleKkomiMood.base;

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

  String _assetPathForMood(SimpleKkomiMood mood) {
    switch (mood) {
      case SimpleKkomiMood.base:
        return 'assets/images/kkomi/base.png';
      case SimpleKkomiMood.success:
        return 'assets/images/kkomi/success.png';
      case SimpleKkomiMood.failure:
        return 'assets/images/kkomi/failure.png';
    }
  }

  Future<void> _select(bool pickTop) async {
    // ✅ 이미 정답 처리 중이거나 정답 마크가 떠 있으면 입력 무시 (중복 O/X 방지)
    final inputLocked =
        _waitingNext ||
        (_showTopMark && _topCorrect) ||
        (_showBottomMark && _bottomCorrect);
    if (inputLocked) return;

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

    // 꼬미 이미지 상태 변경
    _kkomiMoodNotifier.value =
        correct ? SimpleKkomiMood.success : SimpleKkomiMood.failure;

    setState(() {});

    if (correct) {
      // ✅ 정답 + 성공 효과음
      await _playSuccessSfx();

      if (!widget.autoNext) {
        return;
      }

      if (_waitingNext) return;
      _waitingNext = true;
      setState(() {});

      // 정답 이펙트 (샤인)
      _centerCtrl.showAnswer(widget.answerHold); // fire-and-forget

      // 정답 상태 잠깐 유지
      await Future.delayed(widget.answerHold);

      if (!mounted) {
        _waitingNext = false;
        return;
      }

      _waitingNext = false;
      setState(() {});
      await _next();
    } else {
      // ❌ 오답 + 실패 효과음
      await _playFailureSfx();

      // ⏱ 오답 마크가 사라질 타이밍에 맞춰 꼬미를 다시 base로
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_kkomiMoodNotifier.value == SimpleKkomiMood.failure) {
          _kkomiMoodNotifier.value = SimpleKkomiMood.base;
        }
      });
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

    final shouldLockInput =
        _waitingNext ||
        (_showTopMark && _topCorrect) ||
        (_showBottomMark && _bottomCorrect);

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
                // 배경
                BackgroundLayer(fruit: _answer),

                // 꼬미 정적 이미지 (캔버스 전체, 트랜지션 없이 즉시 교체)
                Positioned(
                  left: 0,
                  top: 0,
                  width: canvasW,
                  height: canvasH,
                  child: IgnorePointer(
                    child: ValueListenableBuilder<SimpleKkomiMood>(
                      valueListenable: _kkomiMoodNotifier,
                      builder: (context, mood, _) {
                        final path = _assetPathForMood(mood);
                        return SizedBox.expand(
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover, // 1920x1080 꽉 채우기
                            alignment: Alignment.center,
                            errorBuilder: (c, e, s) =>
                                const SizedBox.shrink(),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 중앙 과일 + 샤인
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

                // 타이틀 배너
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

                // 보기 옵션
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

                // 상단 컨트롤 바
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
                        if (mounted) {
                          setState(() => _bgmPaused = !_bgmPaused);
                        }
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
