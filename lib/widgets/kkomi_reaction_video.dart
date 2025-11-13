import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/fruit_enum.dart';

/// 리액션 상태
enum KkomiMood { base, success, failure }

/// 외부 제어용 컨트롤러
class KkomiReactionController {
  _KkomiReactionVideoState? _state;

  void _attach(_KkomiReactionVideoState s) => _state = s;
  void _detach(_KkomiReactionVideoState s) {
    if (identical(_state, s)) _state = null;
  }

  void playBase() => _state?._setMood(KkomiMood.base);

  /// ✅ success:
  ///  - looping = true 상태에서 한 번 전체 재생(0→끝→0 랩어라운드 감지)
  ///  - 다시 0으로 돌아왔을 때 pause + 0초에 정지
  Future<void> playSuccess() =>
      _state?._playAndWait(KkomiMood.success) ?? Future.value();

  /// 실패: 끝까지 재생 후 base로 복귀
  Future<void> playFailure() =>
      _state?._playAndWait(KkomiMood.failure) ?? Future.value();

  /// 필요 시 전체 초기화
  Future<void> cutToBase() => _state?._cutToBase() ?? Future.value();

  KkomiMood? get mood => _state?._mood;
}

/// 과일별 비디오 경로 세트
class KkomiVideoSet {
  final String base; // 무한 루프
  final String success; // 단발(여기서는 loop = true 로 씀)
  final String failure; // 단발
  const KkomiVideoSet({
    required this.base,
    required this.success,
    required this.failure,
  });
}

typedef KkomiVideoResolver = KkomiVideoSet Function(Fruit fruit);

KkomiVideoSet defaultKkomiVideoResolver(Fruit fruit) {
  final dir = 'assets/videos/kkomi/${fruit.name}';
  return KkomiVideoSet(
    base: '$dir/base.mp4',
    success: '$dir/success.mp4',
    failure: '$dir/failure.mp4',
  );
}

/// ─────────────────────────────────────────────────────────────────────
/// 컨트롤러 풀(캐시)
/// ─────────────────────────────────────────────────────────────────────
class _KkomiPool {
  static final _KkomiPool i = _KkomiPool._();
  _KkomiPool._();

  final Map<Fruit, _Triplet> _map = {};

  Future<_Triplet> get(Fruit f, KkomiVideoResolver resolve) async {
    if (_map.containsKey(f)) return _map[f]!;
    final set = resolve(f);

    final base = VideoPlayerController.asset(set.base)..setLooping(true);
    // ⭐ success는 loop = true 로: 한 바퀴 끝 → 다시 0으로 오는 순간 잡아낼 것
    final succ = VideoPlayerController.asset(set.success)..setLooping(true);
    final fail = VideoPlayerController.asset(set.failure)..setLooping(false);

    await Future.wait([base.initialize(), succ.initialize(), fail.initialize()]);

    // 워밍업(첫 프레임 텍스처 확보)
    for (final c in [base, succ, fail]) {
      await c.play();
      await c.pause();
      await c.seekTo(Duration.zero);
    }

    final t = _Triplet(base, succ, fail);
    _map[f] = t;
    return t;
  }

  Future<void> disposeAll() async {
    final futures = <Future<void>>[];
    for (final t in _map.values) {
      futures.addAll([t.base.dispose(), t.succ.dispose(), t.fail.dispose()]);
    }
    await Future.wait(futures);
    _map.clear();
  }
}

class _Triplet {
  final VideoPlayerController base, succ, fail;
  _Triplet(this.base, this.succ, this.fail);
}

/// 1920×1080 전체 프레임 mp4를 현재 캔버스 사각형에 맞춰 그리는 위젯
/// - base: 무한 루프
/// - success:
///   * loop = true
///   * 0→(팔 올리고 내리고)→끝→0 으로 랩어라운드 되는 순간 pause
///   * 그 상태(0초 프레임)로 정지
/// - failure: loop = false, 끝까지 재생 후 base로 복귀
class KkomiReactionVideo extends StatefulWidget {
  const KkomiReactionVideo({
    super.key,
    required this.controller,
    required this.fruit,
    required this.canvasRect,
    this.resolve = defaultKkomiVideoResolver,
    this.fit = BoxFit.contain,

    /// 실패쪽 타임아웃 여유
    this.endSlack = const Duration(milliseconds: 200),

    // SFX 옵션
    this.successSfx = 'audio/sfx/success.wav',
    this.failureSfx = 'audio/sfx/failure.wav',
    this.sfxVolume = 0.9,
    this.enableSfx = true,

    // 준비 완료 콜백(부모에서 gate용)
    this.onReady,
  });

  final KkomiReactionController controller;
  final Fruit fruit;
  final Rect canvasRect;
  final KkomiVideoResolver resolve;
  final BoxFit fit;
  final Duration endSlack;

  final String? successSfx;
  final String? failureSfx;
  final double sfxVolume;
  final bool enableSfx;

  final VoidCallback? onReady;

  @override
  State<KkomiReactionVideo> createState() => _KkomiReactionVideoState();
}

class _KkomiReactionVideoState extends State<KkomiReactionVideo> {
  KkomiMood _mood = KkomiMood.base;

  VideoPlayerController? _baseC;
  VideoPlayerController? _successC;
  VideoPlayerController? _failureC;

  bool _ready = false;

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
    _baseC = _successC = _failureC = null;

    _sfxPlayer.stop();
    _sfxPlayer.dispose();
    super.dispose();
  }

  void _setMood(KkomiMood mood) {
    if (!mounted) return;
    setState(() => _mood = mood);
    _applyPlaybackFor(mood);
    _maybePlaySfxFor(mood);
  }

  /// 실패용: isCompleted 플래그로 끝까지 재생 여부 확인
  Future<void> _waitControllerEnd(VideoPlayerController? c) async {
    if (c == null) return;
    if (!c.value.isInitialized) return;

    if (c.value.isCompleted) return;

    final completer = Completer<void>();

    final timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      final v = c.value;
      if (!v.isInitialized) return;
      if (v.isCompleted) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    final timeout = Future.delayed(
      const Duration(seconds: 12),
      () {},
    );

    await Future.any([completer.future, timeout]);
    timer.cancel();
  }

  /// ✅ success 한 바퀴 끝까지 재생 후, 다시 0으로 돌아왔을 때 정지
  Future<void> _waitSuccessFirstLoop(VideoPlayerController? c) async {
    if (c == null) return;
    if (!c.value.isInitialized) return;

    // 항상 0에서 시작하도록
    await c.seekTo(Duration.zero);
    if (!c.value.isPlaying) {
      await c.play();
    }

    final completer = Completer<void>();
    Duration? lastPos;

    final timer = Timer.periodic(const Duration(milliseconds: 30), (_) async {
      final v = c.value;
      if (!v.isInitialized) return;

      final pos = v.position;
      final dur = v.duration;

      // duration 모르면 할 수 있는 게 없으니 타임아웃에 맡김
      if (dur == Duration.zero) {
        lastPos = pos;
        return;
      }

      // 랩어라운드 감지:
      // - lastPos가 어느 정도 진행된 상태에서
      // - pos가 갑자기 작아져서 "초반 구간"에 다시 들어오면 0으로 돌아온 것으로 판단
      if (lastPos != null) {
        final bool wasNearEnd =
            lastPos! > Duration.zero &&
            lastPos! >= dur * 0.7; // 전체의 70% 이상 진행되었었다가

        final bool nowNearStart = pos <= dur * 0.2; // 다시 앞 구간으로 돌아옴

        if (wasNearEnd && nowNearStart) {
          try {
            await c.pause();
            await c.seekTo(Duration.zero); // 0초 프레임에서 정지
          } catch (_) {}
          if (!completer.isCompleted) completer.complete();
          return;
        }
      }

      lastPos = pos;
    });

    final timeout = Future.delayed(const Duration(seconds: 12), () {});
    await Future.any([completer.future, timeout]);
    timer.cancel();
  }

  Future<void> _playAndWait(KkomiMood mood) async {
    if (!mounted) return;

    _setMood(mood);

    if (mood == KkomiMood.success) {
      // ⭐ success: loop = true, 1회 재생 끝 → 다시 앞 구간으로 돌아오는 순간까지 대기
      await _waitSuccessFirstLoop(_successC);
      return;
    }

    if (mood == KkomiMood.failure) {
      // 실패: 끝까지 재생 후 base로 복귀
      await _waitControllerEnd(_failureC);
      if (!mounted) return;
      _setMood(KkomiMood.base);
      return;
    }

    // base는 대기 필요 없음
  }

  Future<void> _cutToBase() async {
    if (!_ready) return;
    try {
      await _sfxPlayer.stop();
    } catch (_) {}

    final all = <VideoPlayerController?>[_baseC, _successC, _failureC];
    for (final c in all) {
      if (c == null) continue;
      try {
        if (c.value.isPlaying) await c.pause();
        if (c.value.position != Duration.zero) {
          await c.seekTo(Duration.zero);
        }
      } catch (_) {}
    }
    _mood = KkomiMood.base;
    if (mounted) setState(() {});
  }

  Future<void> _switchFruit(Fruit f) async {
    _baseC = _successC = _failureC = null;
    _ready = false;
    if (mounted) setState(() {});
    await _initForFruit(f);
  }

  Future<void> _initForFruit(Fruit f) async {
    final t = await _KkomiPool.i.get(f, widget.resolve);
    _baseC = t.base;
    _successC = t.succ;
    _failureC = t.fail;

    if (widget.enableSfx) {
      await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _sfxPlayer.setVolume(widget.sfxVolume.clamp(0.0, 1.0));
    }

    _ready = true;

    _mood = KkomiMood.base;
    await _applyPlaybackFor(_mood);

    if (mounted) {
      widget.onReady?.call();
      setState(() {});
    }
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
        // success도 여기서는 단순히 "현재 위치에서 재생"만,
        // 실제 1회전 감시는 _waitSuccessFirstLoop에서 처리
        if (!c.value.isPlaying) await c.play();
      } else {
        if (c.value.isPlaying) await c.pause();
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
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(asset));
    } catch (_) {}
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
          key: UniqueKey(), // 텍스처 잔상 방지
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
