import 'package:flutter/material.dart';

/// 과일 Enum (문제, 보기, 색상 관리용)
enum Fruit {
  pineapple,
  carrot,
  melon,
  onion,
  apple,
  cucumber,
  strawberry,
  eggplant,
  kiwi,
  pumpkin,
  orientalMelon,
  radish,
  tangerine,
  paprika,
  persimmon,
  watermelon,
  tomato,
  pear,
  banana,
  grape,
}

/// 각 과일의 이름, 색상 데이터
class FruitInfo {
  final String nameKo;
  final String nameEn;
  final Color bgColor;

  const FruitInfo(this.nameKo, this.nameEn, this.bgColor);
}

/// 전역 팔레트 — BackgroundLayer와 Quiz에서 공용으로 사용
const Map<Fruit, FruitInfo> kFruitInfo = {
  Fruit.pineapple: FruitInfo('파인애플', 'Pineapple', Color(0xFFF1DFBF)),
  Fruit.carrot: FruitInfo('당근', 'Carrot', Color(0xFFF0C6BD)),
  Fruit.melon: FruitInfo('멜론', 'Melon', Color(0xFFB1ECBE)),
  Fruit.onion: FruitInfo('양파', 'Onion', Color(0xFFE4EDF1)),
  Fruit.apple: FruitInfo('사과', 'Apple', Color(0xFFD7B9BE)),
  Fruit.cucumber: FruitInfo('오이', 'Cucumber', Color(0xFFBEDEBE)),
  Fruit.strawberry: FruitInfo('딸기', 'Strawberry', Color(0xFFE4B9BE)),
  Fruit.eggplant: FruitInfo('가지', 'Eggplant', Color(0xFFCBC7F0)),
  Fruit.kiwi: FruitInfo('키위', 'Kiwi', Color(0xFFBFD3BE)),
  Fruit.pumpkin: FruitInfo('호박', 'Pumpkin', Color(0xFFF4D096)),
  Fruit.orientalMelon: FruitInfo('참외', 'Oriental Melon', Color(0xFFF1ECBD)),
  Fruit.radish: FruitInfo('무', 'Radish', Color(0xFFD4F0CE)),
  Fruit.tangerine: FruitInfo('귤', 'Tangerine', Color(0xFFF1DFBF)),
  Fruit.paprika: FruitInfo('파프리카', 'Paprika', Color(0xFFF0C6BD)),
  Fruit.persimmon: FruitInfo('감', 'Persimmon', Color(0xFFF1DFBF)),
  Fruit.watermelon: FruitInfo('수박', 'Watermelon', Color(0xFFB1DFBD)),
  Fruit.tomato: FruitInfo('토마토', 'Tomato', Color(0xFFF0D2BE)),
  Fruit.pear: FruitInfo('배', 'Pear', Color(0xFFF2ECCB)),
  Fruit.banana: FruitInfo('바나나', 'Banana', Color(0xFFF1DFBF)),
  Fruit.grape: FruitInfo('포도', 'Grape', Color(0xFFCAB9FC)),
};
