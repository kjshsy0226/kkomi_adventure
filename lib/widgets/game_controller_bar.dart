import 'package:flutter/material.dart';

class GameControllerBar extends StatefulWidget {
  final VoidCallback? onHome;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onPauseToggle;

  final bool isPaused;

  const GameControllerBar({
    super.key,
    this.onHome,
    this.onPrev,
    this.onNext,
    this.onPauseToggle,
    this.isPaused = false,
  });

  @override
  State<GameControllerBar> createState() => _GameControllerBarState();
}

class _GameControllerBarState extends State<GameControllerBar> {
  bool _pressedHome = false;
  bool _pressedPrev = false;
  bool _pressedPause = false;
  bool _pressedNext = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/ui/controller/bar.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            normal: 'assets/images/ui/controller/btn_home.png',
            pressed: 'assets/images/ui/controller/btn_home_pressed.png',
            pressedFlag: _pressedHome,
            onTapDown: () => setState(() => _pressedHome = true),
            onTapUp: () {
              setState(() => _pressedHome = false);
              widget.onHome?.call();
            },
          ),
          const SizedBox(width: 8),
          _buildButton(
            normal: 'assets/images/ui/controller/btn_prev.png',
            pressed: 'assets/images/ui/controller/btn_prev_pressed.png',
            pressedFlag: _pressedPrev,
            onTapDown: () => setState(() => _pressedPrev = true),
            onTapUp: () {
              setState(() => _pressedPrev = false);
              widget.onPrev?.call();
            },
          ),
          const SizedBox(width: 8),
          _buildButton(
            normal: widget.isPaused
                ? 'assets/images/ui/controller/btn_play.png'
                : 'assets/images/ui/controller/btn_pause.png',
            pressed: widget.isPaused
                ? 'assets/images/ui/controller/btn_play_pressed.png'
                : 'assets/images/ui/controller/btn_pause_pressed.png',
            pressedFlag: _pressedPause,
            onTapDown: () => setState(() => _pressedPause = true),
            onTapUp: () {
              setState(() => _pressedPause = false);
              widget.onPauseToggle?.call();
            },
          ),
          const SizedBox(width: 8),
          _buildButton(
            normal: 'assets/images/ui/controller/btn_next.png',
            pressed: 'assets/images/ui/controller/btn_next_pressed.png',
            pressedFlag: _pressedNext,
            onTapDown: () => setState(() => _pressedNext = true),
            onTapUp: () {
              setState(() => _pressedNext = false);
              widget.onNext?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String normal,
    required String pressed,
    required bool pressedFlag,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: () => setState(() {
        // 탭 도중 취소 시 pressed 플래그 해제
        _pressedHome = _pressedPrev = _pressedPause = _pressedNext = false;
      }),
      child: Image.asset(pressedFlag ? pressed : normal, width: 72, height: 72),
    );
  }
}
