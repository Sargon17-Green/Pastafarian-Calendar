// Ĉi tiu katalogo estas la sola kanona homlingva fonto por ĉi tiu realiga linio.
// La normiga ordo dependas nur de canonicalIndex, neniam de la montrata teksto.

pub const catalog_version = "1.0.0"

pub const natural_language = "Esperanto"

pub const cutlet_count = 17

pub const month_count = 47

pub fn cutlet_name(canonical_index: Int) -> String {
  case canonical_index {
    1 -> "bronzo"
    2 -> "vulpo"
    3 -> "reno"
    4 -> "Lagaŝo"
    5 -> "penso"
    6 -> "kvar naŭonoj"
    7 -> "Palgurŝ"
    8 -> "papiruso"
    9 -> "grapolo"
    10 -> "skorpio"
    11 -> "cindro"
    12 -> "tritiko"
    13 -> "rivero"
    14 -> "rido"
    15 -> "Akado"
    16 -> "korno"
    17 -> "la malplena kruĉo"
    _ -> panic as "Nevalida kanona indekso de kotleto"
  }
}

pub fn month_name(canonical_index: Int) -> String {
  case canonical_index {
    1 -> "argilo"
    2 -> "granato"
    3 -> "kubuto"
    4 -> "envio"
    5 -> "Eriduo"
    6 -> "dentopasto"
    7 -> "tri kvinonoj"
    8 -> "Karŝumab"
    9 -> "leopardo"
    10 -> "stano"
    11 -> "nebulo"
    12 -> "olibano"
    13 -> "spindelo"
    14 -> "ripo"
    15 -> "karobo"
    16 -> "Uruko"
    17 -> "honto"
    18 -> "kamelo"
    19 -> "kupro"
    20 -> "puto"
    21 -> "ovoflavo"
    22 -> "stelo"
    23 -> "mielo"
    24 -> "lieno"
    25 -> "kalkŝtono"
    26 -> "ĝojo"
    27 -> "figo"
    28 -> "Ninevo"
    29 -> "rano"
    30 -> "gudro"
    31 -> "kandelo"
    32 -> "la fermita pordo"
    33 -> "sezamo"
    34 -> "nuko"
    35 -> "arĝento"
    36 -> "lilio"
    37 -> "ŝtormo"
    38 -> "azeno"
    39 -> "faruno"
    40 -> "bedaŭro"
    41 -> "Babilono"
    42 -> "lango"
    43 -> "lino"
    44 -> "salo"
    45 -> "piro"
    46 -> "arko"
    47 -> "sablo"
    _ -> panic as "Nevalida kanona indekso de monato"
  }
}
