module SourceLanguageCatalog {
  const SOURCE_LANGUAGE_CATALOG_VERSION = "1";
  const SOURCE_LANGUAGE = "українська";

  const CUTLET_DOMAIN = {1..17};
  const MONTH_DOMAIN = {1..47};

  const CUTLET_NAMES_UK: [CUTLET_DOMAIN] string = [
    "бронза",
    "лисиця",
    "нирка",
    "Лагаш",
    "думка",
    "чотири дев’ятих",
    "Палґураш",
    "папірус",
    "гроно",
    "скорпіон",
    "попіл",
    "пшениця",
    "річка",
    "сміх",
    "Аккад",
    "ріг",
    "порожній глек"
  ];

  const MONTH_NAMES_UK: [MONTH_DOMAIN] string = [
    "глина",
    "гранат",
    "лікоть",
    "заздрість",
    "Еріду",
    "зубна паста",
    "три п’ятих",
    "Каршумав",
    "леопард",
    "олово",
    "туман",
    "ладан",
    "веретено",
    "ребро",
    "ріжкове дерево",
    "Урук",
    "сором",
    "верблюд",
    "мідь",
    "криниця",
    "жовток",
    "зірка",
    "мед",
    "селезінка",
    "вапняк",
    "радість",
    "інжир",
    "Ніневія",
    "жаба",
    "бітум",
    "свічка",
    "зачинені двері",
    "кунжут",
    "потилиця",
    "срібло",
    "лілія",
    "буря",
    "віслюк",
    "борошно",
    "каяття",
    "Вавилон",
    "язик",
    "льон",
    "сіль",
    "груша",
    "лук",
    "пісок"
  ];

  proc cutletNameByCanonicalIndex(index: int): string {
    if index < CUTLET_DOMAIN.low || index > CUTLET_DOMAIN.high then
      halt("Некоректний canonicalIndex котлети.");
    return CUTLET_NAMES_UK[index];
  }

  proc monthNameByCanonicalIndex(index: int): string {
    if index < MONTH_DOMAIN.low || index > MONTH_DOMAIN.high then
      halt("Некоректний canonicalIndex місяця.");
    return MONTH_NAMES_UK[index];
  }
}
