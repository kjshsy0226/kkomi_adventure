import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kkomi_adventure/models/fruit_enum.dart';
import 'package:kkomi_adventure/widgets/sequence_sprites.dart';

/// 중앙 과일 + 풀스크린 샤인 효과
/// - 샤인: 부모 Stack 크기(캔버스)에 꽉 채움
/// - 과일: rect 중심에 490×490, scale 반영
class CenterFruitWithShine extends StatefulWidget {
  const CenterFruitWithShine({
    super.key,
    required this.fruit,
    required this.rect,
    required this.scale,

    // Shine sequence
    this.framesBasePath = 'assets/images/quiz/effects/shine_seq/shine_',
    this.frameDigits = 3,
    this.frameCount = 5,
    this.fps = 12,
    this.repeats = 3, // N회 반복 후 정지 (<=1 이면 1회)
    this.autoplay = true,

    // 스케일/페이드 FX
    this.fxDuration = const Duration(milliseconds: 900),
    this.enableFx = true,
  });

  final Fruit fruit;
  final Rect rect; // 과일을 중앙 정렬할 기준 영역(캔버스 좌표계)
  final double scale; // 캔버스 스케일

  // shine
  final String framesBasePath;
  final int frameDigits;
  final int frameCount;
  final double fps;
  final int repeats;
  final bool autoplay;

  // 과일 FX
  final Duration fxDuration;
  final bool enableFx;

  @override
  State<CenterFruitWithShine> createState() => _CenterFruitWithShineState();
}

class _CenterFruitWithShineState extends State<CenterFruitWithShine>
    with SingleTickerProviderStateMixin {
  late final SequenceController _seqCtrl;
  late final List<String> _frames;

  late final AnimationController _fxCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  int _looped = 0;

  String get _fruitFileName => widget.fruit.name; // enum 이름과 파일명 동일
  String get _centerPath => 'assets/images/fruits/center/$_fruitFileName.png';

  @override
  void initState() {
    super.initState();

    _frames = List.generate(widget.frameCount, (i) {
      final n = i.toString().padLeft(widget.frameDigits, '0');
      return '${widget.framesBasePath}$n.png';
    });

    _seqCtrl = SequenceController()
      ..onLoopRestart = () {
        _looped++;
        if (_looped >= max(1, widget.repeats)) {
          // sequence_sprites.dart의 stop() 시그니처에 resetToFirstFrame 없으면 그냥 stop();
          _seqCtrl.stop();
        }
      };

    _fxCtrl = AnimationController(vsync: this, duration: widget.fxDuration);
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_fxCtrl);
    _fadeAnim = CurvedAnimation(parent: _fxCtrl, curve: Curves.easeInOut);

    if (widget.autoplay) _startAll();
  }

  @override
  void didUpdateWidget(covariant CenterFruitWithShine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruit != widget.fruit) {
      _looped = 0;
      _seqCtrl.stop();
      if (widget.autoplay) _startAll();
    }
  }

  void _startAll() {
    _fxCtrl.forward(from: 0);
    _seqCtrl.start(); // loop 켜두고 repeats 카운팅으로 정지
  }

  @override
  void dispose() {
    _fxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 과일: rect 중심에 490×490 배치
    const double fruitBaseSize = 490.0;
    final double fruitSize = fruitBaseSize * widget.scale;

    final double cx = (widget.rect.left + widget.rect.width / 2) * widget.scale;
    final double cy = (widget.rect.top + widget.rect.height / 2) * widget.scale;

    final double left = cx - fruitSize / 2;
    final double top = cy - fruitSize / 2;

    return Stack(
      fit: StackFit.expand, // 부모 캔버스에 꽉 차도록
      children: [
        // ── Shine: 풀스크린(캔버스 전체)
        if (_frames.isNotEmpty)
          SizedBox.expand(
            child: SequenceSprite(
              controller: _seqCtrl,
              assetPaths: _frames,
              fps: widget.fps,
              loop: true,
              autoplay: widget.autoplay,
              holdLastFrameWhenFinished: false,
              precache: true,
              fit: BoxFit.cover, // 1920x1080을 화면 꽉 채우기
            ),
          ),

        // ── 과일: 490×490, rect 중심 정렬 + FX
        Positioned(
          left: left,
          top: top,
          width: fruitSize,
          height: fruitSize,
          child: AnimatedBuilder(
            animation: _fxCtrl,
            builder: (context, child) => Opacity(
              opacity: widget.enableFx ? _fadeAnim.value : 1.0,
              child: Transform.scale(
                scale: widget.enableFx ? _scaleAnim.value : 1.0,
                child: child,
              ),
            ),
            child: Image.asset(
              _centerPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
