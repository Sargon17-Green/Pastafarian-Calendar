#pragma once

#include <array>
#include <cstddef>
#include <string_view>

namespace pastafari {

struct CatalogEntry {
    std::size_t canonicalIndex;
    std::string_view text;
};

inline constexpr std::array<CatalogEntry, 17> CUTLET_SOURCE_CATALOG{{
    {1, "aes"},
    {2, "vulpes"},
    {3, "ren"},
    {4, "larix"},
    {5, "cogitatio"},
    {6, "quattuor partes ex novem"},
    {7, "Palguras"},
    {8, "cyperus"},
    {9, "racemus"},
    {10, "scorpio"},
    {11, "cinis"},
    {12, "triticum"},
    {13, "flumen"},
    {14, "risus"},
    {15, "Accad"},
    {16, "cornu"},
    {17, "urna vacua"}
}};

inline constexpr std::array<CatalogEntry, 47> MONTH_SOURCE_CATALOG{{
    {1, "lutum"},
    {2, "malum granatum"},
    {3, "cubitus"},
    {4, "invidia"},
    {5, "Eridu"},
    {6, "dentifricium"},
    {7, "tres partes ex quinque"},
    {8, "Carsumav"},
    {9, "pardus"},
    {10, "stannum"},
    {11, "nebula"},
    {12, "olibanum"},
    {13, "fusus"},
    {14, "costa"},
    {15, "ceratonia"},
    {16, "Uruk"},
    {17, "pudor"},
    {18, "camelus"},
    {19, "cuprum"},
    {20, "puteus"},
    {21, "vitellus"},
    {22, "stella"},
    {23, "mel"},
    {24, "lien"},
    {25, "lapis calcarius"},
    {26, "laetitia"},
    {27, "ficus"},
    {28, "Ninive"},
    {29, "rana"},
    {30, "bitumen"},
    {31, "candela"},
    {32, "ianua clausa"},
    {33, "sesamum"},
    {34, "occiput"},
    {35, "argentum"},
    {36, "lilium"},
    {37, "tempestas"},
    {38, "asinus"},
    {39, "farina"},
    {40, "paenitentia"},
    {41, "Babylon"},
    {42, "lingua"},
    {43, "linum"},
    {44, "sal"},
    {45, "pirum"},
    {46, "arcus"},
    {47, "arena"}
}};

constexpr std::string_view cutletSourceName(std::size_t canonicalIndex) {
    return CUTLET_SOURCE_CATALOG.at(canonicalIndex - 1).text;
}

constexpr std::string_view monthSourceName(std::size_t canonicalIndex) {
    return MONTH_SOURCE_CATALOG.at(canonicalIndex - 1).text;
}

} // namespace pastafari
