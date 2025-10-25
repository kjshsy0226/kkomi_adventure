import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kkomi_adventure/models/fruit_enum.dart';
import 'package:kkomi_adventure/widgets/sequence_sprites.dart';

/// CenterFruitWithShine 제어용 컨트롤러
class CenterFruitWithShineController {
  void Function(Duration hold, Completer<void> done)? _requestShowAnswer;

  /// 외부에서 호출: 정답 이미지를 hold 동안 보여주고 Future 완료
  Future<void> showAnswer(Duration hold) {
    final c = Completer<void>();
    final call = _requestShowAnswer;
    if (call != null) {
      call(hold, c);
    } else {
      c.complete();
    }
    return c.future;
  }
}

/// 1920×1080 풀캔버스 과일 이미지 + 샤인 + (내장) 정답 오버레이
class CenterFruitWithShine extends StatefulWidget {
  const CenterFruitWithShine({
    super.key,
    required this.fruit,
    required this.controller,

    // Shine sequence
    this.framesBasePath = 'assets/images/effects/shine_seq/shine_',
    this.frameDigits = 3,
    this.frameCount = 5,
    this.fps = 12,
    this.repeats = 3,
    this.autoplay = true,

    // 과일 등장 FX
    this.fxDuration = const Duration(milliseconds: 900),
    this.enableFx = true,
  });

  final Fruit fruit;
  final CenterFruitWithShineController controller;

  final String framesBasePath;
  final int frameDigits;
  final int frameCount;
  final double fps;
  final int repeats;
  final bool autoplay;

  final Duration fxDuration;
  final bool enableFx;

  @override
  State<CenterFruitWithShine> createState() => _CenterFruitWithShineState();
}

class _CenterFruitWithShineState extends State<CenterFruitWithShine>
    with SingleTickerProviderStateMixin {
  late final SequenceController _seqCtrl;
  late List<String> _frames;

  late final AnimationController _fxCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  // 정답 오버레이 상태
  bool _showAnswer = false;
  Duration _answerHold = const Duration(milliseconds: 900);
  Completer<void>? _answerDone;

  int _looped = 0;

  String get _fruitFileName => widget.fruit.name;
  String get _fruitPath => 'assets/images/fruits/center/$_fruitFileName.png';
  String get _answerPath =>
      'assets/images/fruits/answer/${_fruitFileName}_answer.png';

  @override
  void initState() {
    super.initState();

    // 컨트롤러 바인딩
    widget.controller._requestShowAnswer = _onRequestShowAnswer;

    _buildShineFrames();

    _seqCtrl = SequenceController()
      ..onLoopRestart = () {
        _looped++;
        if (_looped >= max(1, widget.repeats)) {
          _seqCtrl.stop();
        }
      };

    _fxCtrl = AnimationController(vsync: this, duration: widget.fxDuration);

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.04,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
    ]).animate(_fxCtrl);

    _fadeAnim = CurvedAnimation(parent: _fxCtrl, curve: Curves.easeInOut);

    if (widget.autoplay) _startAll();
  }

  void _buildShineFrames() {
    _frames = List.generate(widget.frameCount, (i) {
      final n = i.toString().padLeft(widget.frameDigits, '0');
      return '${widget.framesBasePath}$n.png';
    });
  }

  // 외부 트리거: 정답 오버레이 보여주기
  void _onRequestShowAnswer(Duration hold, Completer<void> done) async {
    // 진행 중 플로우가 있으면 안전하게 종료
    if (_answerDone != null && !_answerDone!.isCompleted) {
      _answerDone!.complete();
    }
    _answerHold = hold;
    _answerDone = done;

    setState(() => _showAnswer = true);

    await Future.delayed(_answerHold);

    if (!mounted) {
      if (!_answerDone!.isCompleted) _answerDone!.complete();
      return;
    }
    setState(() => _showAnswer = false);
    if (!_answerDone!.isCompleted) _answerDone!.complete();
  }

  @override
  void didUpdateWidget(covariant CenterFruitWithShine oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 컨트롤러 재바인딩
    if (oldWidget.controller != widget.controller) {
      widget.controller._requestShowAnswer = _onRequestShowAnswer;
    }

    // 과일 변경 시 FX/샤인 리셋 + 오버레이 안전 종료
    if (oldWidget.fruit != widget.fruit) {
      _looped = 0;
      _seqCtrl.stop();
      _showAnswer = false;
      if (_answerDone != null && !_answerDone!.isCompleted) {
        _answerDone!.complete(); // ✅ 이미 완료된 Future 중복 complete 방지 처리
      }
      _answerDone = null;

      if (widget.autoplay) {
        _startAll();
      } else {
        _fxCtrl.forward(from: 0);
      }
    }

    // 샤인 프레임 설정 변경 시 재구성
    final shineChanged =
        oldWidget.framesBasePath != widget.framesBasePath ||
        oldWidget.frameDigits != widget.frameDigits ||
        oldWidget.frameCount != widget.frameCount;
    if (shineChanged) {
      _buildShineFrames();
      _looped = 0;
      _seqCtrl.stop();
      if (widget.autoplay) _seqCtrl.start();
    }
  }

  void _startAll() {
    _fxCtrl.forward(from: 0);
    _seqCtrl.start();
  }

  @override
  void dispose() {
    if (_answerDone != null && !_answerDone!.isCompleted) {
      _answerDone!.complete();
    }
    _fxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1) 풀스크린 샤인
          if (_frames.isNotEmpty)
            SequenceSprite(
              controller: _seqCtrl,
              assetPaths: _frames,
              fps: widget.fps,
              loop: true,
              autoplay: widget.autoplay,
              holdLastFrameWhenFinished: false,
              precache: true,
              fit: BoxFit.cover,
            ),

          // 2) 문제 과일(1920×1080) + FX
          AnimatedBuilder(
            animation: _fxCtrl,
            builder: (context, child) => Opacity(
              opacity: widget.enableFx ? _fadeAnim.value : 1.0,
              child: Transform.scale(
                scale: widget.enableFx ? _scaleAnim.value : 1.0,
                child: child,
              ),
            ),
            child: Image.asset(
              _fruitPath,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // 3) 정답 오버레이
          if (_showAnswer)
            _AnswerOverlayImage(
              imagePath: _answerPath,
              fallbackText: _fruitFileName,
            ),
        ],
      ),
    );
  }
}

/// 정답 이미지(1920×1080) 오버레이: 페이드 + 살짝 줌
class _AnswerOverlayImage extends StatefulWidget {
  const _AnswerOverlayImage({
    required this.imagePath,
    required this.fallbackText,
  });

  final String imagePath;
  final String fallbackText;

  @override
  State<_AnswerOverlayImage> createState() => _AnswerOverlayImageState();
}

class _AnswerOverlayImageState extends State<_AnswerOverlayImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a;
  late final Animation<double> _fade;
  late final Animation<double> _zoom;

  @override
  void initState() {
    super.initState();
    _a = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..forward();
    _fade = CurvedAnimation(parent: _a, curve: Curves.easeOutCubic);
    _zoom = Tween(
      begin: 0.98,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_a);
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) => Opacity(
          opacity: _fade.value,
          child: Transform.scale(
            scale: _zoom.value,
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.fill, // 부모가 1920×1080 프레임
              errorBuilder: (context, error, stack) => Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFDF7D7),
                    borderRadius: BorderRadius.circular(48),
                    border: Border.all(
                      color: const Color(0xFFE8D27A),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 6),
                        color: Color(0x40000000),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.fallbackText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5C4B00),
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
