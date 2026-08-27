export const SOURCE_LANGUAGE_CATALOG_VERSION = "1.0.0" as const;
export const SOURCE_LANGUAGE = "मराठी" as const;

type NameKind = "meaning" | "proper" | "invented";

export type CatalogEntry = Readonly<{
  canonicalIndex: number;
  text: string;
  kind: NameKind;
}>;

function freezeEntries(entries: CatalogEntry[]): readonly CatalogEntry[] {
  return Object.freeze(entries.map((entry) => Object.freeze({ ...entry })));
}

export const CUTLET_CATALOG = freezeEntries([
  { canonicalIndex: 1, text: "कांस्य", kind: "meaning" },
  { canonicalIndex: 2, text: "कोल्हा", kind: "meaning" },
  { canonicalIndex: 3, text: "मूत्रपिंड", kind: "meaning" },
  { canonicalIndex: 4, text: "लगश", kind: "proper" },
  { canonicalIndex: 5, text: "विचार", kind: "meaning" },
  { canonicalIndex: 6, text: "नऊपैकी चार भाग", kind: "meaning" },
  { canonicalIndex: 7, text: "पलगुरश", kind: "invented" },
  { canonicalIndex: 8, text: "लव्हाळा", kind: "meaning" },
  { canonicalIndex: 9, text: "घड", kind: "meaning" },
  { canonicalIndex: 10, text: "विंचू", kind: "meaning" },
  { canonicalIndex: 11, text: "राख", kind: "meaning" },
  { canonicalIndex: 12, text: "गहू", kind: "meaning" },
  { canonicalIndex: 13, text: "नदी", kind: "meaning" },
  { canonicalIndex: 14, text: "हसू", kind: "meaning" },
  { canonicalIndex: 15, text: "अक्कद", kind: "proper" },
  { canonicalIndex: 16, text: "शिंग", kind: "meaning" },
  { canonicalIndex: 17, text: "रिकामा घडा", kind: "meaning" }
]);

export const MONTH_CATALOG = freezeEntries([
  { canonicalIndex: 1, text: "चिकणमाती", kind: "meaning" },
  { canonicalIndex: 2, text: "डाळिंब", kind: "meaning" },
  { canonicalIndex: 3, text: "कोपर", kind: "meaning" },
  { canonicalIndex: 4, text: "मत्सर", kind: "meaning" },
  { canonicalIndex: 5, text: "एरिडू", kind: "proper" },
  { canonicalIndex: 6, text: "दातांची पेस्ट", kind: "meaning" },
  { canonicalIndex: 7, text: "पाचपैकी तीन भाग", kind: "meaning" },
  { canonicalIndex: 8, text: "खर्शुमव", kind: "invented" },
  { canonicalIndex: 9, text: "वाघ", kind: "meaning" },
  { canonicalIndex: 10, text: "कथील", kind: "meaning" },
  { canonicalIndex: 11, text: "धुके", kind: "meaning" },
  { canonicalIndex: 12, text: "लोबान", kind: "meaning" },
  { canonicalIndex: 13, text: "तकळी", kind: "meaning" },
  { canonicalIndex: 14, text: "बरगडी", kind: "meaning" },
  { canonicalIndex: 15, text: "करोब", kind: "meaning" },
  { canonicalIndex: 16, text: "उरुक", kind: "proper" },
  { canonicalIndex: 17, text: "लाज", kind: "meaning" },
  { canonicalIndex: 18, text: "उंट", kind: "meaning" },
  { canonicalIndex: 19, text: "तांबे", kind: "meaning" },
  { canonicalIndex: 20, text: "विहीर", kind: "meaning" },
  { canonicalIndex: 21, text: "पिवळा बलक", kind: "meaning" },
  { canonicalIndex: 22, text: "तारा", kind: "meaning" },
  { canonicalIndex: 23, text: "मध", kind: "meaning" },
  { canonicalIndex: 24, text: "प्लीहा", kind: "meaning" },
  { canonicalIndex: 25, text: "चुनखडी", kind: "meaning" },
  { canonicalIndex: 26, text: "आनंद", kind: "meaning" },
  { canonicalIndex: 27, text: "अंजीर", kind: "meaning" },
  { canonicalIndex: 28, text: "निनेवे", kind: "proper" },
  { canonicalIndex: 29, text: "बेडूक", kind: "meaning" },
  { canonicalIndex: 30, text: "डांबर", kind: "meaning" },
  { canonicalIndex: 31, text: "मेणबत्ती", kind: "meaning" },
  { canonicalIndex: 32, text: "बंद दरवाजा", kind: "meaning" },
  { canonicalIndex: 33, text: "तीळ", kind: "meaning" },
  { canonicalIndex: 34, text: "मानेचा मागचा भाग", kind: "meaning" },
  { canonicalIndex: 35, text: "चांदी", kind: "meaning" },
  { canonicalIndex: 36, text: "लिली", kind: "meaning" },
  { canonicalIndex: 37, text: "वादळ", kind: "meaning" },
  { canonicalIndex: 38, text: "गाढव", kind: "meaning" },
  { canonicalIndex: 39, text: "पीठ", kind: "meaning" },
  { canonicalIndex: 40, text: "पश्चात्ताप", kind: "meaning" },
  { canonicalIndex: 41, text: "बॅबिलोन", kind: "proper" },
  { canonicalIndex: 42, text: "जीभ", kind: "meaning" },
  { canonicalIndex: 43, text: "जवस", kind: "meaning" },
  { canonicalIndex: 44, text: "मीठ", kind: "meaning" },
  { canonicalIndex: 45, text: "नाशपाती", kind: "meaning" },
  { canonicalIndex: 46, text: "धनुष्य", kind: "meaning" },
  { canonicalIndex: 47, text: "वाळू", kind: "meaning" }
]);

export const SourceLanguageCatalog = Object.freeze({
  version: SOURCE_LANGUAGE_CATALOG_VERSION,
  language: SOURCE_LANGUAGE,
  cutlets: CUTLET_CATALOG,
  months: MONTH_CATALOG
});

function resolve(entries: readonly CatalogEntry[], canonicalIndex: number): string {
  const entry = entries[canonicalIndex - 1];
  if (entry === undefined || entry.canonicalIndex !== canonicalIndex) {
    throw new RangeError("कॅनॉनिकल अनुक्रमांक वैध नाही");
  }
  return entry.text;
}

export function cutletNameByCanonicalIndex(canonicalIndex: number): string {
  return resolve(CUTLET_CATALOG, canonicalIndex);
}

export function monthNameByCanonicalIndex(canonicalIndex: number): string {
  return resolve(MONTH_CATALOG, canonicalIndex);
}
