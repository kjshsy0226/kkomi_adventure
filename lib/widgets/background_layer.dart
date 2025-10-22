import 'package:flutter/material.dart';
import '../models/fruit_enum.dart';

class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({
    super.key,
    required this.fruit,
    this.fade = const Duration(milliseconds: 250),
    this.tintColor,
    this.tintAlpha = 0,
  });

  final Fruit fruit;
  final Duration fade;
  final Color? tintColor;
  final int tintAlpha;

  @override
  Widget build(BuildContext context) {
    final base = kFruitInfo[fruit]?.bgColor ?? const Color(0xFFF4E5C5);
    final colors = _pastel(base);

    return SizedBox.expand(
      child: AnimatedContainer(
        duration: fade,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: (tintColor != null && tintAlpha > 0)
            ? ColoredBox(color: tintColor!.withAlpha(tintAlpha))
            : const SizedBox.shrink(),
      ),
    );
  }

  static List<Color> _pastel(Color c) => [
    Color.lerp(c, Colors.white, 0.35)!,
    Color.lerp(c, Colors.white, 0.10)!,
  ];
}
