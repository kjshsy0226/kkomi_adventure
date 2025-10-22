import 'dart:async';
import 'package:flutter/widgets.dart';

/// 외부에서 start/stop만 제어할 수 있는 간단 PNG 시퀀스 플레이어.
/// - assets 경로 리스트를 그대로 넘깁니다 (000~099 등 자유).
/// - fps: 초당 프레임 재생 속도
/// - loop: true면 반복 재생
/// - fit: 이미지 맞춤 방식
/// - gaplessPlayback: 프레임 전환시 깜빡임 최소화
///
/// 사용:
///   final ctrl = PngSequenceController();
///   PngSequencePlayer(
///     controller: ctrl,
///     assetPaths: frames, // ['assets/..._000.png', ...]
///     fps: 24,
///     loop: true,
///   );
///   ctrl.start(); // 재생
///   ctrl.stop();  // 정지(첫 프레임으로)
class PngSequencePlayer extends StatefulWidget {
  final PngSequenceController controller;
  final List<String> assetPaths;
  final double fps;
  final bool loop;
  final BoxFit fit;
  final bool gaplessPlayback;
  final Size? fixedSize; // null이면 부모 제약에 따름
  final bool precache; // 시작 전에 전부 메모리에 로드

  const PngSequencePlayer({
    super.key,
    required this.controller,
    required this.assetPaths,
    this.fps = 24,
    this.loop = true,
    this.fit = BoxFit.contain,
    this.gaplessPlayback = true,
    this.fixedSize,
    this.precache = false,
  });

  @override
  State<PngSequencePlayer> createState() => _PngSequencePlayerState();
}

class _PngSequencePlayerState extends State<PngSequencePlayer>
    with SingleTickerProviderStateMixin {
  late int _frameCount;
  int _index = 0;
  Timer? _timer;
  bool _isPlaying = false;
  List<ImageProvider>? _cachedProviders; // precache용

  Duration get _frameDuration => Duration(
    microseconds: (1e6 / widget.fps).round(), // fps → 프레임 간격
  );

  @override
  void initState() {
    super.initState();
    _frameCount = widget.assetPaths.length.clamp(0, 1 << 20);
    widget.controller._attach(this);

    if (widget.precache && _frameCount > 0) {
      _precacheAll();
    }
  }

  @override
  void didUpdateWidget(covariant PngSequencePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPaths != widget.assetPaths ||
        oldWidget.fps != widget.fps ||
        oldWidget.loop != widget.loop) {
      // 구성 변경 시 재생 상태 유지해서 새 파라미터 반영
      final wasPlaying = _isPlaying;
      stop();
      _frameCount = widget.assetPaths.length.clamp(0, 1 << 20);
      if (wasPlaying) start();
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _timer?.cancel();
    super.dispose();
  }

  // --- 외부 제어 진입점 ---
  void start() {
    if (_frameCount == 0 || _isPlaying) return;
    _isPlaying = true;
    _timer?.cancel();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        _index++;
        if (_index >= _frameCount) {
          if (widget.loop) {
            _index = 0;
          } else {
            _index = _frameCount - 1;
            stop(); // 루프 아니면 멈춤
          }
        }
      });
    });
    setState(() {});
  }

  void stop() {
    _timer?.cancel();
    _isPlaying = false;
    _index = 0; // 첫 프레임으로
    if (mounted) setState(() {});
  }
  // --- 외부 제어 끝 ---

  Future<void> _precacheAll() async {
    _cachedProviders = widget.assetPaths.map((p) => AssetImage(p)).toList();
    for (final provider in _cachedProviders!) {
      if (!mounted) return;
      await precacheImage(provider, context);
    }
    if (mounted) setState(() {}); // 캐시 완료 후 한 번 리빌드
  }

  @override
  Widget build(BuildContext context) {
    if (_frameCount == 0) {
      return const SizedBox.shrink();
    }

    final child = Image.asset(
      widget.assetPaths[_index],
      fit: widget.fit,
      gaplessPlayback: widget.gaplessPlayback,
    );

    if (widget.fixedSize != null) {
      return SizedBox(
        width: widget.fixedSize!.width,
        height: widget.fixedSize!.height,
        child: child,
      );
    }
    return child;
  }
}

/// start/stop만 노출하는 간단 컨트롤러
class PngSequenceController {
  _PngSequencePlayerState? _state;

  void _attach(_PngSequencePlayerState s) => _state = s;
  void _detach(_PngSequencePlayerState s) {
    if (identical(_state, s)) _state = null;
  }

  void start() => _state?.start();
  void stop() => _state?.stop();

  bool get isPlaying => _state?._isPlaying ?? false;
  int get frameIndex => _state?._index ?? 0;
}
