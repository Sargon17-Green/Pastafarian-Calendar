#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CatalogEntry {
    pub canonical_index: u8,
    pub source_text: &'static str,
}

pub const CATALOG_VERSION: &str = "az-1";

pub const CUTLET_NAMES: [CatalogEntry; 17] = [
    CatalogEntry { canonical_index: 1, source_text: "bürünc" },
    CatalogEntry { canonical_index: 2, source_text: "tülkü" },
    CatalogEntry { canonical_index: 3, source_text: "böyrək" },
    CatalogEntry { canonical_index: 4, source_text: "Laqaş" },
    CatalogEntry { canonical_index: 5, source_text: "düşüncə" },
    CatalogEntry { canonical_index: 6, source_text: "doqquzun dörd hissəsi" },
    CatalogEntry { canonical_index: 7, source_text: "Palguraş" },
    CatalogEntry { canonical_index: 8, source_text: "papirus" },
    CatalogEntry { canonical_index: 9, source_text: "salxım" },
    CatalogEntry { canonical_index: 10, source_text: "əqrəb" },
    CatalogEntry { canonical_index: 11, source_text: "kül" },
    CatalogEntry { canonical_index: 12, source_text: "buğda" },
    CatalogEntry { canonical_index: 13, source_text: "çay" },
    CatalogEntry { canonical_index: 14, source_text: "gülüş" },
    CatalogEntry { canonical_index: 15, source_text: "Akkad" },
    CatalogEntry { canonical_index: 16, source_text: "buynuz" },
    CatalogEntry { canonical_index: 17, source_text: "boş küp" },
];

pub const MONTH_NAMES: [CatalogEntry; 47] = [
    CatalogEntry { canonical_index: 1, source_text: "gil" },
    CatalogEntry { canonical_index: 2, source_text: "nar" },
    CatalogEntry { canonical_index: 3, source_text: "dirsək" },
    CatalogEntry { canonical_index: 4, source_text: "qısqanclıq" },
    CatalogEntry { canonical_index: 5, source_text: "Eridu" },
    CatalogEntry { canonical_index: 6, source_text: "diş məcunu" },
    CatalogEntry { canonical_index: 7, source_text: "beşin üç hissəsi" },
    CatalogEntry { canonical_index: 8, source_text: "Karşumab" },
    CatalogEntry { canonical_index: 9, source_text: "pələng" },
    CatalogEntry { canonical_index: 10, source_text: "qalay" },
    CatalogEntry { canonical_index: 11, source_text: "duman" },
    CatalogEntry { canonical_index: 12, source_text: "kündür" },
    CatalogEntry { canonical_index: 13, source_text: "iy" },
    CatalogEntry { canonical_index: 14, source_text: "qabırğa" },
    CatalogEntry { canonical_index: 15, source_text: "keçibuynuzu" },
    CatalogEntry { canonical_index: 16, source_text: "Uruk" },
    CatalogEntry { canonical_index: 17, source_text: "utanc" },
    CatalogEntry { canonical_index: 18, source_text: "dəvə" },
    CatalogEntry { canonical_index: 19, source_text: "mis" },
    CatalogEntry { canonical_index: 20, source_text: "quyu" },
    CatalogEntry { canonical_index: 21, source_text: "yumurta sarısı" },
    CatalogEntry { canonical_index: 22, source_text: "ulduz" },
    CatalogEntry { canonical_index: 23, source_text: "bal" },
    CatalogEntry { canonical_index: 24, source_text: "dalaq" },
    CatalogEntry { canonical_index: 25, source_text: "əhəngdaşı" },
    CatalogEntry { canonical_index: 26, source_text: "sevinc" },
    CatalogEntry { canonical_index: 27, source_text: "əncir" },
    CatalogEntry { canonical_index: 28, source_text: "Ninova" },
    CatalogEntry { canonical_index: 29, source_text: "qurbağa" },
    CatalogEntry { canonical_index: 30, source_text: "qatran" },
    CatalogEntry { canonical_index: 31, source_text: "şam" },
    CatalogEntry { canonical_index: 32, source_text: "bağlı qapı" },
    CatalogEntry { canonical_index: 33, source_text: "küncüt" },
    CatalogEntry { canonical_index: 34, source_text: "ənsə" },
    CatalogEntry { canonical_index: 35, source_text: "gümüş" },
    CatalogEntry { canonical_index: 36, source_text: "zanbaq" },
    CatalogEntry { canonical_index: 37, source_text: "fırtına" },
    CatalogEntry { canonical_index: 38, source_text: "eşşək" },
    CatalogEntry { canonical_index: 39, source_text: "un" },
    CatalogEntry { canonical_index: 40, source_text: "peşmanlıq" },
    CatalogEntry { canonical_index: 41, source_text: "Babil" },
    CatalogEntry { canonical_index: 42, source_text: "dil" },
    CatalogEntry { canonical_index: 43, source_text: "kətan" },
    CatalogEntry { canonical_index: 44, source_text: "duz" },
    CatalogEntry { canonical_index: 45, source_text: "armud" },
    CatalogEntry { canonical_index: 46, source_text: "yay" },
    CatalogEntry { canonical_index: 47, source_text: "qum" },
];

pub fn cutlet_name(canonical_index: u8) -> Option<&'static str> {
    CUTLET_NAMES
        .get(usize::from(canonical_index.checked_sub(1)?))
        .map(|entry| entry.source_text)
}

pub fn month_name(canonical_index: u8) -> Option<&'static str> {
    MONTH_NAMES
        .get(usize::from(canonical_index.checked_sub(1)?))
        .map(|entry| entry.source_text)
}
