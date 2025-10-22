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
  Fruit.pineapple: FruitInfo('파인애플', 'Pineapple', Color(0xFFF4D9A5)),
  Fruit.carrot: FruitInfo('당근', 'Carrot', Color(0xFFF1B38C)),
  Fruit.melon: FruitInfo('멜론', 'Melon', Color(0xFFCDEBCF)),
  Fruit.onion: FruitInfo('양파', 'Onion', Color(0xFFDCE7EE)),
  Fruit.apple: FruitInfo('사과', 'Apple', Color(0xFFEBD3D4)),
  Fruit.cucumber: FruitInfo('오이', 'Cucumber', Color(0xFFCFE8D6)),
  Fruit.strawberry: FruitInfo('딸기', 'Strawberry', Color(0xFFF1C0C3)),
  Fruit.eggplant: FruitInfo('가지', 'Eggplant', Color(0xFFD7DDEB)),
  Fruit.kiwi: FruitInfo('키위', 'Kiwi', Color(0xFFD7EACF)),
  Fruit.pumpkin: FruitInfo('호박', 'Pumpkin', Color(0xFFF3D09F)),
  Fruit.orientalMelon: FruitInfo('참외', 'Oriental Melon', Color(0xFFF6E3B3)),
  Fruit.radish: FruitInfo('무', 'Radish', Color(0xFFDCEDE4)),
  Fruit.tangerine: FruitInfo('귤', 'Tangerine', Color(0xFFF6C6A2)),
  Fruit.paprika: FruitInfo('파프리카', 'Paprika', Color(0xFFF3B9AA)),
  Fruit.persimmon: FruitInfo('감', 'Persimmon', Color(0xFFF1C1A0)),
  Fruit.watermelon: FruitInfo('수박', 'Watermelon', Color(0xFFE5F0D9)),
  Fruit.tomato: FruitInfo('토마토', 'Tomato', Color(0xFFF2C0BF)),
  Fruit.pear: FruitInfo('배', 'Pear', Color(0xFFF4E5C5)),
  Fruit.banana: FruitInfo('바나나', 'Banana', Color(0xFFF7E7A7)),
  Fruit.grape: FruitInfo('포도', 'Grape', Color(0xFFE0D7F6)),
};
