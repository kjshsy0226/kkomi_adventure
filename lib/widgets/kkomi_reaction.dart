import 'dart:async';
import 'package:flutter/widgets.dart';
import 'sequence_sprites.dart'; // SequenceSprite / SequenceSpriteAudio / controllers

/// 꼬미 리액션 상태
enum KkomiMood { base, success, failure }

/// 외부 제어용 컨트롤러 (성공/실패는 Future로 종료 시점까지 대기 가능)
class KkomiReactionController {
  _KkomiReactionState? _state;

  void _attach(_KkomiReactionState s) => _state = s;
  void _detach(_KkomiReactionState s) {
    if (identical(_state, s)) _state = null;
  }

  void playBase() => _state?._setMood(KkomiMood.base);

  /// 성공 리액션 1사이클 재생이 끝나는 시점에 완료되는 Future
  Future<void> playSuccess() =>
      _state?._playAndWait(KkomiMood.success) ?? Future.value();

  /// 실패 리액션 1사이클 재생이 끝나는 시점에 완료되는 Future
  Future<void> playFailure() =>
      _state?._playAndWait(KkomiMood.failure) ?? Future.value();

  KkomiMood? get mood => _state?._mood;
}

/// 1920×1080 풀스크린 시퀀스를 캔버스(Rect)에 맞춰 그리는 위젯
///
/// - `canvasRect`: 현재 화면에서 1920×1080 캔버스가 차지하는 영역(좌표/크기)
/// - base 는 무한루프(이미지 전용), success/failure 는 1회 재생 + 효과음 후 자동으로 base 복귀
class KkomiReaction extends StatefulWidget {
  const KkomiReaction({
    super.key,
    required this.controller,
    required this.canvasRect, // 화면 픽셀 좌표계(스케일 적용 후)
    this.initialMood = KkomiMood.base,

    // 공통 FPS/자릿수 설정
    this.fps = 24,
    this.frameDigits = 3,
    this.precache = true,

    // 무드별 프레임 수
    this.baseFrameCount = 100, // 000~099
    this.successFrameCount = 48, // 000~047
    this.failureFrameCount = 48, // 000~047
    // 이미지 경로 프리픽스
    this.basePrefix = 'assets/images/kkomi/base/kkomi_base_',
    this.successPrefix = 'assets/images/kkomi/success/kkomi_success_',
    this.failurePrefix = 'assets/images/kkomi/failure/kkomi_failure_',

    // 효과음 경로(원하면 변경)
    this.successSfx = 'assets/audio/sfx/success.wav',
    this.failureSfx = 'assets/audio/sfx/failure.wav',
  });

  final KkomiReactionController controller;
  final Rect canvasRect;

  final KkomiMood initialMood;

  // 공통 재생 설정
  final double fps;
  final int frameDigits;
  final bool precache;

  // 무드별 프레임 카운트
  final int baseFrameCount;
  final int successFrameCount;
  final int failureFrameCount;

  // image path prefixes (###.png 붙음)
  final String basePrefix;
  final String successPrefix;
  final String failurePrefix;

  // sfx
  final String successSfx;
  final String failureSfx;

  @override
  State<KkomiReaction> createState() => _KkomiReactionState();
}

class _KkomiReactionState extends State<KkomiReaction> {
  late KkomiMood _mood;

  final SequenceAudioController _audioCtrl = SequenceAudioController();
  final SequenceController _imgCtrl = SequenceController(); // base 전용 이미지 컨트롤러
  Timer? _autoBackTimer;

  Completer<void>? _playCompleter; // success/failure 종료 대기용

  int _countFor(KkomiMood mood) {
    switch (mood) {
      case KkomiMood.base:
        return widget.baseFrameCount;
      case KkomiMood.success:
        return widget.successFrameCount;
      case KkomiMood.failure:
        return widget.failureFrameCount;
    }
  }

  String _prefixFor(KkomiMood mood) {
    switch (mood) {
      case KkomiMood.base:
        return widget.basePrefix;
      case KkomiMood.success:
        return widget.successPrefix;
      case KkomiMood.failure:
        return widget.failurePrefix;
    }
  }

  List<String> _framesFor(KkomiMood mood) {
    final prefix = _prefixFor(mood);
    final count = _countFor(mood);
    final digits = widget.frameDigits;
    return List.generate(
      count,
      (i) => '$prefix${i.toString().padLeft(digits, '0')}.png',
    );
  }

  String? _sfxFor(KkomiMood mood) {
    switch (mood) {
      case KkomiMood.success:
        return widget.successSfx;
      case KkomiMood.failure:
        return widget.failureSfx;
      case KkomiMood.base:
        return null;
    }
  }

  // 내부: 상태 즉시 변경
  void _setMood(KkomiMood mood) {
    if (!mounted) return;
    _autoBackTimer?.cancel();
    setState(() => _mood = mood);
  }

  // 내부: success/failure 재생 + 종료 시점까지 기다리는 Future 반환
  Future<void> _playAndWait(KkomiMood mood) {
    if (!mounted) return Future.value();

    // 기존 대기자 정리
    _autoBackTimer?.cancel();
    _playCompleter?.complete();
    _playCompleter = Completer<void>();

    _setMood(mood);

    // 현재 무드 프레임 수로 정확한 재생 시간 계산
    final seconds = _countFor(mood) / widget.fps;
    _autoBackTimer = Timer(
      Duration(milliseconds: (seconds * 1000).round()),
      () {
        if (!mounted) return;
        _setMood(KkomiMood.base);
        _playCompleter?.complete(); // 대기중인 Future 완료
        _playCompleter = null;
      },
    );
    return _playCompleter!.future;
  }

  @override
  void initState() {
    super.initState();
    _mood = widget.initialMood;
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _autoBackTimer?.cancel();
    _playCompleter?.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = _framesFor(_mood);

    Widget content;
    if (_mood == KkomiMood.base) {
      // 이미지-only 루프
      content = SequenceSprite(
        controller: _imgCtrl,
        assetPaths: frames,
        fps: widget.fps,
        loop: true,
        autoplay: true,
        holdLastFrameWhenFinished: true,
        precache: widget.precache,
        fit: BoxFit.contain,
      );
    } else {
      // 1회 재생 + 효과음
      content = SequenceSpriteAudio(
        controller: _audioCtrl,
        assetPaths: frames,
        audioAsset: _sfxFor(_mood),
        audioSyncMode: AudioSyncMode.oneShotPerPlay,
        fps: widget.fps,
        loop: false,
        autoplay: true,
        autoplayAudio: true,
        holdLastFrameWhenFinished: true,
        precache: widget.precache,
        fit: BoxFit.contain,
      );
    }

    // ✅ 깜빡임 방지: 키를 timestamp가 아니라 "mood"만 사용
    content = KeyedSubtree(key: ValueKey(_mood), child: content);

    // 1920×1080 풀프레임을 현재 캔버스 사각형에 맞춰 배치
    return Positioned(
      left: widget.canvasRect.left,
      top: widget.canvasRect.top,
      width: widget.canvasRect.width,
      height: widget.canvasRect.height,
      child: content,
    );
  }
}
