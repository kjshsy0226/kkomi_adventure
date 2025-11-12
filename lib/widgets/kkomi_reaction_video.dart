import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/fruit_enum.dart'; // Fruit

/// 리액션 상태 (기존 API와 동일)
enum KkomiMood { base, success, failure }

/// 외부 제어용 컨트롤러 (기존 KkomiReactionController와 동일 API/이름 유지)
class KkomiReactionController {
  _KkomiReactionVideoState? _state;

  void _attach(_KkomiReactionVideoState s) => _state = s;
  void _detach(_KkomiReactionVideoState s) {
    if (identical(_state, s)) _state = null;
  }

  void playBase() => _state?._setMood(KkomiMood.base);
  Future<void> playSuccess() =>
      _state?._playAndWait(KkomiMood.success) ?? Future.value();
  Future<void> playFailure() =>
      _state?._playAndWait(KkomiMood.failure) ?? Future.value();

  KkomiMood? get mood => _state?._mood;
}

/// 과일별 비디오 경로 세트
class KkomiVideoSet {
  final String base; // 무한 루프
  final String success; // 1회 재생 후 base 복귀
  final String failure; // 1회 재생 후 base 복귀
  const KkomiVideoSet({
    required this.base,
    required this.success,
    required this.failure,
  });
}

/// 비디오 경로 결정 함수 타입
typedef KkomiVideoResolver = KkomiVideoSet Function(Fruit fruit);

KkomiVideoSet defaultKkomiVideoResolver(Fruit fruit) {
  final dir = 'assets/videos/kkomi/${fruit.name}';
  return KkomiVideoSet(
    base: '$dir/base.mp4',
    success: '$dir/success.mp4',
    failure: '$dir/failure.mp4',
  );
}

/// 1920×1080 전체 프레임 mp4를 현재 캔버스 사각형에 맞춰 그리는 위젯
/// - base는 무한 루프, success/failure는 1회 재생 후 자동 base 복귀
class KkomiReactionVideo extends StatefulWidget {
  const KkomiReactionVideo({
    super.key,
    required this.controller,
    required this.fruit,
    required this.canvasRect,
    this.resolve = defaultKkomiVideoResolver,
    this.fit = BoxFit.contain,
    this.endSlack = const Duration(milliseconds: 120),

    // ▼ SFX 옵션
    this.successSfx = 'audio/sfx/success.wav',
    this.failureSfx = 'audio/sfx/failure.wav',
    this.sfxVolume = 0.9,
    this.enableSfx = true,
  });

  final KkomiReactionController controller;
  final Fruit fruit;
  final Rect canvasRect;
  final KkomiVideoResolver resolve; // 과일별 base/success/failure mp4 경로
  final BoxFit fit;
  final Duration endSlack;

  // SFX
  final String? successSfx;
  final String? failureSfx;
  final double sfxVolume; // 0.0 ~ 1.0
  final bool enableSfx;

  @override
  State<KkomiReactionVideo> createState() => _KkomiReactionVideoState();
}

class _KkomiReactionVideoState extends State<KkomiReactionVideo> {
  KkomiMood _mood = KkomiMood.base;

  VideoPlayerController? _baseC;
  VideoPlayerController? _successC;
  VideoPlayerController? _failureC;

  VoidCallback? _succListener;
  VoidCallback? _failListener;

  bool _ready = false;

  // 단발 SFX 플레이어(성공/실패 공용)
  final AudioPlayer _sfxPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _initForFruit(widget.fruit);
  }

  @override
  void didUpdateWidget(covariant KkomiReactionVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fruit != widget.fruit) {
      _switchFruit(widget.fruit);
    }
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _removeListeners();
    _disposeAll();
    // SFX 정리
    _sfxPlayer.stop();
    _sfxPlayer.dispose();
    super.dispose();
  }

  // 외부 제어: 무드 전환
  void _setMood(KkomiMood mood) {
    if (!mounted) return;
    setState(() => _mood = mood);
    _applyPlaybackFor(mood);
    _maybePlaySfxFor(mood);
  }

  Future<void> _playAndWait(KkomiMood mood) async {
    if (!mounted) return;
    _setMood(mood);

    final completer = Completer<void>();
    final timeout = Future.delayed(const Duration(seconds: 12), () {
      if (!completer.isCompleted) completer.complete();
    });

    void poll() {
      if (_mood == KkomiMood.base && !completer.isCompleted) {
        completer.complete();
      }
    }

    final ticker = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => poll(),
    );
    await Future.any([completer.future, timeout]);
    ticker.cancel();
  }

  // ── 과일 전환 ──────────────────────────────────────────────────────
  Future<void> _switchFruit(Fruit f) async {
    _removeListeners();
    await _disposeAll();
    await _initForFruit(f);
  }

  Future<void> _initForFruit(Fruit f) async {
    final set = widget.resolve(f);

    _baseC = VideoPlayerController.asset(set.base)..setLooping(true);
    _successC = VideoPlayerController.asset(set.success)..setLooping(false);
    _failureC = VideoPlayerController.asset(set.failure)..setLooping(false);

    await Future.wait([
      _baseC!.initialize(),
      _successC!.initialize(),
      _failureC!.initialize(),
    ]);

    // 워밍업
    await _baseC!.play();
    await _baseC!.pause();
    await _baseC!.seekTo(Duration.zero);
    await _successC!.play();
    await _successC!.pause();
    await _successC!.seekTo(Duration.zero);
    await _failureC!.play();
    await _failureC!.pause();
    await _failureC!.seekTo(Duration.zero);

    _installEndListeners();
    _ready = true;

    _mood = KkomiMood.base;
    _applyPlaybackFor(_mood);

    if (mounted) setState(() {});
  }

  void _installEndListeners() {
    _removeListeners();

    _succListener = () {
      final v = _successC?.value;
      if (v == null || !v.isInitialized) return;
      final done =
          v.duration > Duration.zero &&
          (v.duration - v.position) <= widget.endSlack;
      if (done && _mood == KkomiMood.success) {
        _setMood(KkomiMood.base);
      }
    };
    _successC?.addListener(_succListener!);

    _failListener = () {
      final v = _failureC?.value;
      if (v == null || !v.isInitialized) return;
      final done =
          v.duration > Duration.zero &&
          (v.duration - v.position) <= widget.endSlack;
      if (done && _mood == KkomiMood.failure) {
        _setMood(KkomiMood.base);
      }
    };
    _failureC?.addListener(_failListener!);
  }

  void _removeListeners() {
    if (_succListener != null && _successC != null) {
      _successC!.removeListener(_succListener!);
      _succListener = null;
    }
    if (_failListener != null && _failureC != null) {
      _failureC!.removeListener(_failListener!);
      _failListener = null;
    }
  }

  Future<void> _disposeAll() async {
    Future<void> safeDispose(VideoPlayerController? c) async {
      if (c == null) return;
      try {
        await c.dispose();
      } catch (_) {}
    }

    await Future.wait([
      safeDispose(_baseC),
      safeDispose(_successC),
      safeDispose(_failureC),
    ]);
    _baseC = _successC = _failureC = null;
    _ready = false;
  }

  Future<void> _applyPlaybackFor(KkomiMood mood) async {
    if (!_ready) return;
    final all = <VideoPlayerController?>[_baseC, _successC, _failureC];

    VideoPlayerController? target;
    switch (mood) {
      case KkomiMood.base:
        target = _baseC;
        break;
      case KkomiMood.success:
        target = _successC;
        break;
      case KkomiMood.failure:
        target = _failureC;
        break;
    }

    for (final c in all) {
      if (c == null) continue;
      if (c == target) {
        if (c.value.position != Duration.zero) {
          await c.seekTo(Duration.zero);
        }
        if (!c.value.isPlaying) await c.play();
      } else {
        if (c.value.isPlaying) await c.pause();
        if (c.value.position != Duration.zero) {
          await c.seekTo(Duration.zero);
        }
      }
    }
  }

  Future<void> _maybePlaySfxFor(KkomiMood mood) async {
    if (!widget.enableSfx) return;

    String? asset;
    switch (mood) {
      case KkomiMood.success:
        asset = widget.successSfx;
        break;
      case KkomiMood.failure:
        asset = widget.failureSfx;
        break;
      case KkomiMood.base:
        asset = null;
        break;
    }
    if (asset == null || asset.isEmpty) return;

    try {
      // 겹침 방지: 기존 재생 중이면 정지 후 재생
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(widget.sfxVolume.clamp(0.0, 1.0));
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.play(AssetSource(asset));
    } catch (_) {
      // SFX 실패는 앱 흐름에 영향 주지 않음
    }
  }

  @override
  Widget build(BuildContext context) {
    final show =
        _ready && _baseC != null && _successC != null && _failureC != null;

    Widget videoBox(VideoPlayerController? c) {
      if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
      return FittedBox(
        fit: widget.fit,
        child: SizedBox(
          key: UniqueKey(), // 텍스처 재사용 잔상 방지
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      );
    }

    return Positioned(
      left: widget.canvasRect.left,
      top: widget.canvasRect.top,
      width: widget.canvasRect.width,
      height: widget.canvasRect.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!show)
            const SizedBox.shrink()
          else ...[
            Visibility(
              visible: _mood == KkomiMood.base,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: videoBox(_baseC),
            ),
            Visibility(
              visible: _mood == KkomiMood.success,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: videoBox(_successC),
            ),
            Visibility(
              visible: _mood == KkomiMood.failure,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: videoBox(_failureC),
            ),
          ],
        ],
      ),
    );
  }
}
