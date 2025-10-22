import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          '게임 모드 (추후 구현)',
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
      ),
    );
  }
}
