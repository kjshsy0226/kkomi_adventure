import 'package:flutter/material.dart';

class TopControlBar extends StatelessWidget {
  final bool isPlaying;
  final double volume;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onChangeVolume;
  final VoidCallback onToggleFullScreen;

  const TopControlBar({
    super.key,
    required this.isPlaying,
    required this.volume,
    required this.onTogglePlay,
    required this.onChangeVolume,
    required this.onToggleFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Colors.black26,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '홈',
            onPressed: () {},
            icon: const Icon(Icons.home_rounded),
          ),
          IconButton(
            tooltip: '이전',
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          IconButton(
            tooltip: isPlaying ? '일시정지' : '재생',
            onPressed: onTogglePlay,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            ),
          ),
          SizedBox(
            width: 160,
            child: Row(
              children: [
                const Icon(Icons.volume_down, size: 20),
                Expanded(
                  child: Slider(value: volume, onChanged: onChangeVolume),
                ),
                const Icon(Icons.volume_up, size: 20),
              ],
            ),
          ),
          IconButton(
            tooltip: '풀스크린 토글',
            onPressed: onToggleFullScreen,
            icon: const Icon(Icons.fullscreen),
          ),
        ],
      ),
    );
  }
}
