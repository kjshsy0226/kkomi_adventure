import 'dart:async';
import 'package:flutter/material.dart';

class OptionPair extends StatelessWidget {
  const OptionPair({
    super.key,
    required this.slotRect, // 슬롯 BG 전체 영역(345×778)
    required this.scale,
    required this.slotBgPath,
    required this.topImagePath, // 287×304
    required this.bottomImagePath,
    required this.onTapTop,
    required this.onTapBottom,
    required this.showTopMark,
    required this.showBottomMark,
    required this.topCorrect,
    required this.bottomCorrect,
    this.inputLocked = false, // ✅ 정답 시 전체 잠금
    this.markOPath = 'assets/images/ui/marks/mark_o.png',
    this.markXPath = 'assets/images/ui/marks/mark_x.png',
    required this.overlaySeed, // ✅ 문제 전환 시 오버레이 state 초기화용 시드
    this.instantHideVersion = 0, // ✅ 정답 순간 반대편 X 즉시 숨김 트리거
  });

  final Rect slotRect;
  final double scale;
  final String slotBgPath;
  final String topImagePath;
  final String bottomImagePath;
  final VoidCallback onTapTop;
  final VoidCallback onTapBottom;
  final bool showTopMark;
  final bool showBottomMark;
  final bool topCorrect;
  final bool bottomCorrect;
  final bool inputLocked; // ✅ 추가됨
  final String markOPath;
  final String markXPath;
  final int overlaySeed; // ✅ 문제 전환마다 오버레이 state 초기화
  final int instantHideVersion; // ✅ 정답 순간 반대편 X 즉시 OFF 트리거

  // 옵션(보기) 고정 사이즈/오프셋 (디자인 기준 px)
  static const double _optW = 287;
  static const double _optH = 304;
  static const double _optX = 29;
  static const double _optTopY = 29;
  static const double _optBottomY = 423;

  @override
  Widget build(BuildContext context) {
    final left = slotRect.left * scale;
    final top = slotRect.top * scale;
    final w = slotRect.width * scale;
    final h = slotRect.height * scale;

    Widget option(
      String path,
      bool showMark,
      bool correct,
      VoidCallback onTap,
      double ox,
      double oy,
    ) {
      final optW = _optW * scale;
      final optH = _optH * scale;

      final bool lockThis =
          inputLocked || (showMark && correct); // ✅ 정답 O 떠있는 동안도 잠금

      return Positioned(
        left: (slotRect.left + ox) * scale,
        top: (slotRect.top + oy) * scale,
        width: optW,
        height: optH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 클릭 가능 영역
            IgnorePointer(
              ignoring: lockThis, // ✅ 잠금 반영
              child: GestureDetector(
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22 * scale),
                  child: Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: const Text('Image'),
                    ),
                  ),
                ),
              ),
            ),
            // 옵션과 동일 크기로 덮는 마크 (O는 유지, X는 0.8s 후 자동 숨김)
            _AutoMarkOverlay(
              key: ValueKey(
                'ov-$overlaySeed-$path-$showMark-$correct',
              ), // ✅ 문제 바뀔 때 state 리셋
              show: showMark,
              correct: correct,
              width: optW,
              height: optH,
              markOPath: markOPath,
              markXPath: markXPath,
              instantHideVersion: instantHideVersion, // ✅ 정답 순간 즉시 OFF
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // 슬롯 배경
        Positioned(
          left: left,
          top: top,
          width: w,
          height: h,
          child: Image.asset(
            slotBgPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
        // 상단/하단 옵션
        option(
          topImagePath,
          showTopMark,
          topCorrect,
          onTapTop,
          _optX,
          _optTopY,
        ),
        option(
          bottomImagePath,
          showBottomMark,
          bottomCorrect,
          onTapBottom,
          _optX,
          _optBottomY,
        ),
      ],
    );
  }
}

/// 옵션 위에 덮는 O/X 마크.
/// - show=true일 때 보이기
/// - correct=false(X)면 0.8초 후 자동으로 숨김
/// - instantHideVersion 이 갱신되면 **애니메이션 없이 즉시 감춤**
class _AutoMarkOverlay extends StatefulWidget {
  const _AutoMarkOverlay({
    super.key,
    required this.show,
    required this.correct,
    required this.width,
    required this.height,
    required this.markOPath,
    required this.markXPath,
    this.instantHideVersion = 0, // ✅ 추가
  });

  final bool show;
  final bool correct;
  final double width;
  final double height;
  final String markOPath;
  final String markXPath;
  final int instantHideVersion; // ✅ 추가

  @override
  State<_AutoMarkOverlay> createState() => _AutoMarkOverlayState();
}

class _AutoMarkOverlayState extends State<_AutoMarkOverlay> {
  bool _visible = false;
  Timer? _hideTimer;
  int _lastInstantHideVersion = 0; // ✅ 추가

  @override
  void initState() {
    super.initState();
    _applyShowLogic(force: true);
    _lastInstantHideVersion = widget.instantHideVersion;
  }

  @override
  void didUpdateWidget(covariant _AutoMarkOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 즉시 숨김 신호가 갱신되면, 애니메이션 없이 바로 감춤
    if (widget.instantHideVersion != _lastInstantHideVersion) {
      _lastInstantHideVersion = widget.instantHideVersion;
      _hideTimer?.cancel();
      if (mounted) {
        setState(() => _visible = false);
      }
      return; // 즉시 처리 후 종료
    }

    if (oldWidget.show != widget.show || oldWidget.correct != widget.correct) {
      _applyShowLogic(force: true);
    } else {
      // ✅ 같은 문제에서 오답을 연타해도 X가 매번 다시 떠야 함
      if (widget.show && !widget.correct) {
        _applyShowLogic(force: true);
      }
    }
  }

  void _applyShowLogic({bool force = false}) {
    _hideTimer?.cancel();

    if (widget.show) {
      if (force || !_visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _visible = true);
          if (!widget.correct) {
            _hideTimer = Timer(const Duration(milliseconds: 800), () {
              if (mounted) setState(() => _visible = false);
            });
          }
        });
      }
    } else {
      if (_visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _visible = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true, // 터치는 뒤의 옵션 이미지로 통과
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Image.asset(
          widget.correct ? widget.markOPath : widget.markXPath,
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
