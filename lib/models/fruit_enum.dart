/// 과일 Enum (문제, 보기)
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

/// 각 과일의 이름
class FruitInfo {
  final String nameKo;
  final String nameEn;

  const FruitInfo(this.nameKo, this.nameEn);
}

/// 전역 팔레트 — Quiz에서 사용
const Map<Fruit, FruitInfo> kFruitInfo = {
  Fruit.pineapple: FruitInfo('파인애플', 'Pineapple'),
  Fruit.carrot: FruitInfo('당근', 'Carrot'),
  Fruit.melon: FruitInfo('멜론', 'Melon'),
  Fruit.onion: FruitInfo('양파', 'Onion'),
  Fruit.apple: FruitInfo('사과', 'Apple'),
  Fruit.cucumber: FruitInfo('오이', 'Cucumber'),
  Fruit.strawberry: FruitInfo('딸기', 'Strawberry'),
  Fruit.eggplant: FruitInfo('가지', 'Eggplant'),
  Fruit.kiwi: FruitInfo('키위', 'Kiwi'),
  Fruit.pumpkin: FruitInfo('호박', 'Pumpkin'),
  Fruit.orientalMelon: FruitInfo('참외', 'Oriental Melon'),
  Fruit.radish: FruitInfo('무', 'Radish'),
  Fruit.tangerine: FruitInfo('귤', 'Tangerine'),
  Fruit.paprika: FruitInfo('파프리카', 'Paprika'),
  Fruit.persimmon: FruitInfo('감', 'Persimmon'),
  Fruit.watermelon: FruitInfo('수박', 'Watermelon'),
  Fruit.tomato: FruitInfo('토마토', 'Tomato'),
  Fruit.pear: FruitInfo('배', 'Pear'),
  Fruit.banana: FruitInfo('바나나', 'Banana'),
  Fruit.grape: FruitInfo('포도', 'Grape'),
};
