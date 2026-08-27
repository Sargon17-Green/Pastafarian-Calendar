from dataclasses import dataclass
from types import MappingProxyType
from typing import Tuple


@dataclass(frozen=True, slots=True)
class SourceName:
    canonical_index: int
    text: str


@dataclass(frozen=True, slots=True)
class SourceLanguageCatalog:
    version: str
    natural_language: str
    cutlets: Tuple[SourceName, ...]
    months: Tuple[SourceName, ...]

    def cutlet_text(self, canonical_index: int) -> str:
        if not 1 <= canonical_index <= len(self.cutlets):
            raise IndexError("Köfte kanonik indisi aralık dışında")
        return self.cutlets[canonical_index - 1].text

    def month_text(self, canonical_index: int) -> str:
        if not 1 <= canonical_index <= len(self.months):
            raise IndexError("Ay kanonik indisi aralık dışında")
        return self.months[canonical_index - 1].text


_CUTLET_TEXTS = (
    "Tunç",
    "Tilki",
    "Böbrek",
    "Melez ağacı",
    "Düşünce",
    "Dokuzda dört",
    "Palguraş",
    "Papirüs",
    "Salkım",
    "Akrep",
    "Kül",
    "Buğday",
    "Nehir",
    "Kahkaha",
    "Akad",
    "Boynuz",
    "Boş testi",
)

_MONTH_TEXTS = (
    "Kil",
    "Nar",
    "Dirsek",
    "Kıskançlık",
    "Eridu",
    "Diş macunu",
    "Beşte üç",
    "Karşumab",
    "Leopar",
    "Kalay",
    "Sis",
    "Akgünlük",
    "İğ",
    "Kaburga",
    "Keçiboynuzu",
    "Uruk",
    "Utanç",
    "Deve",
    "Bakır",
    "Kuyu",
    "Yumurta sarısı",
    "Yıldız",
    "Bal",
    "Dalak",
    "Kireçtaşı",
    "Sevinç",
    "İncir",
    "Ninova",
    "Kurbağa",
    "Zift",
    "Mum",
    "Kapalı kapı",
    "Susam",
    "Ense",
    "Gümüş",
    "Zambak",
    "Fırtına",
    "Eşek",
    "Un",
    "Pişmanlık",
    "Babil",
    "Dil",
    "Keten",
    "Tuz",
    "Armut",
    "Yay",
    "Kum",
)

SOURCE_LANGUAGE_CATALOG = SourceLanguageCatalog(
    version="1.3.1",
    natural_language="Türkçe",
    cutlets=tuple(SourceName(i + 1, text) for i, text in enumerate(_CUTLET_TEXTS)),
    months=tuple(SourceName(i + 1, text) for i, text in enumerate(_MONTH_TEXTS)),
)

CUTLET_BY_INDEX = MappingProxyType(
    {item.canonical_index: item.text for item in SOURCE_LANGUAGE_CATALOG.cutlets}
)
MONTH_BY_INDEX = MappingProxyType(
    {item.canonical_index: item.text for item in SOURCE_LANGUAGE_CATALOG.months}
)
