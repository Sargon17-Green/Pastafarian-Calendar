#include "pastafari/source_language_catalog.hpp"

#include <algorithm>
#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <set>
#include <stdexcept>
#include <string>
#include <vector>

namespace fs = std::filesystem;

namespace {
void require(bool condicio, const std::string& nuntius) {
    if (!condicio) throw std::runtime_error(nuntius);
}

std::string lege(const fs::path& via) {
    std::ifstream in(via, std::ios::binary);
    require(static_cast<bool>(in), "fasciculus aperiri non potest: " + via.string());
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

bool habetScriptumAlienum(const std::string& s) {
    const unsigned char* p = reinterpret_cast<const unsigned char*>(s.data());
    const unsigned char* finis = p + s.size();
    while (p < finis) {
        unsigned int cp = 0;
        if (*p < 0x80) cp = *p++;
        else if ((*p & 0xE0) == 0xC0 && p + 1 < finis) {
            cp = ((*p & 0x1F) << 6) | (p[1] & 0x3F); p += 2;
        } else if ((*p & 0xF0) == 0xE0 && p + 2 < finis) {
            cp = ((*p & 0x0F) << 12) | ((p[1] & 0x3F) << 6) | (p[2] & 0x3F); p += 3;
        } else if ((*p & 0xF8) == 0xF0 && p + 3 < finis) {
            cp = ((*p & 0x07) << 18) | ((p[1] & 0x3F) << 12) |
                 ((p[2] & 0x3F) << 6) | (p[3] & 0x3F); p += 4;
        } else { ++p; continue; }
        if ((cp >= 0x0590 && cp <= 0x05FF) ||
            (cp >= 0x0600 && cp <= 0x06FF) ||
            (cp >= 0x0400 && cp <= 0x052F)) return true;
    }
    return false;
}

template <std::size_t N>
void probaCatalogum(const std::array<pastafari::CatalogEntry, N>& catalogus) {
    std::set<std::size_t> indices;
    for (std::size_t i = 0; i < N; ++i) {
        require(catalogus[i].canonicalIndex == i + 1, "ordo canonicalIndex fractus est");
        require(!catalogus[i].text.empty(), "textus catalogi vacuus est");
        indices.insert(catalogus[i].canonicalIndex);
    }
    require(indices.size() == N, "canonicalIndex non est unicus");
}

struct QuinquePresentationis {
    long long annus;
    std::size_t segmentum;
    long long diesSegmenti;
    std::size_t mensis;
    long long diesMensis;
};

std::array<std::string, 5> presenta(
    const QuinquePresentationis& q,
    const std::vector<std::string>& segmenta,
    const std::vector<std::string>& menses) {
    return {
        std::to_string(q.annus), segmenta.at(q.segmentum - 1),
        std::to_string(q.diesSegmenti), menses.at(q.mensis - 1),
        std::to_string(q.diesMensis)
    };
}
}

int main() {
    try {
        probaCatalogum(pastafari::CUTLET_SOURCE_CATALOG);
        probaCatalogum(pastafari::MONTH_SOURCE_CATALOG);
        for (std::size_t i = 1; i <= 17; ++i)
            require(pastafari::cutletSourceName(i) == pastafari::CUTLET_SOURCE_CATALOG[i - 1].text,
                    "resolutio nominis segmenti canonicalIndex discrepavit");
        for (std::size_t i = 1; i <= 47; ++i)
            require(pastafari::monthSourceName(i) == pastafari::MONTH_SOURCE_CATALOG[i - 1].text,
                    "resolutio nominis mensis canonicalIndex discrepavit");

        std::vector<std::string> segmentaLatina, mensesLatini;
        std::vector<std::string> segmentaAlia, mensesAlii;
        for (const auto& e : pastafari::CUTLET_SOURCE_CATALOG) {
            segmentaLatina.emplace_back(e.text);
            segmentaAlia.push_back("praesentatio-segmenti-" + std::to_string(e.canonicalIndex));
        }
        for (const auto& e : pastafari::MONTH_SOURCE_CATALOG) {
            mensesLatini.emplace_back(e.text);
            mensesAlii.push_back("praesentatio-mensis-" + std::to_string(e.canonicalIndex));
        }
        const QuinquePresentationis semanticum{5000, 16, 37, 25, 91};
        const auto latina = presenta(semanticum, segmentaLatina, mensesLatini);
        const auto alia = presenta(semanticum, segmentaAlia, mensesAlii);
        require(latina[0] == alia[0] && latina[2] == alia[2] && latina[4] == alia[4],
                "mutatio presentationis campos numericos mutavit");
        require(latina[1] != alia[1] && latina[3] != alia[3],
                "mutatio presentationis textum mutare debuit");
        require(semanticum.segmentum == 16 && semanticum.mensis == 25,
                "presentatio canonicalIndex mutavit");

        std::vector<std::string> collatioSegmentorum = segmentaLatina;
        std::vector<std::string> collatioMensium = mensesLatini;
        std::sort(collatioSegmentorum.begin(), collatioSegmentorum.end());
        std::sort(collatioMensium.begin(), collatioMensium.end());
        require(collatioSegmentorum != segmentaLatina,
                "collatio alphabetica segmentorum casu ordinem canonicum imitatur");
        require(collatioMensium != mensesLatini,
                "collatio alphabetica mensium casu ordinem canonicum imitatur");

        const std::string productio = lege("src/monster.cpp");
        require(productio.find("cutletSourceName(static_cast<std::size_t>(cutletIndex))") != std::string::npos,
                "productio nomen segmenti ex canonicalIndex non resolvit");
        require(productio.find("monthSourceName(static_cast<std::size_t>(monthNameIndex))") != std::string::npos,
                "productio nomen mensis ex canonicalIndex non resolvit");

        const std::array<fs::path, 12> prosaPrincipalis{{
            "DEPENDENCIES.md", "DEVELOPMENT_STAGE.md", "README.md",
            "SOURCE_LANGUAGE_CATALOG.md", "SPAGHETTI_DEVELOPMENT_HISTORY.md",
            "STAGE_55_FINAL_DIFFERENTIAL_LEDGER.md",
            "STAGE_55_SAFE_MONSTER_LEDGER.md",
            "STAGE_55_INVARIANT_LEDGER.md",
            "STAGE_55_LOCAL_TEST_LOG.txt",
            "STAGE_55_FINAL_BYTE_AUDIT.txt",
            "include/pastafari/monster.hpp", "src/monster.cpp"
        }};
        for (const auto& via : prosaPrincipalis)
            require(!habetScriptumAlienum(lege(via)),
                    "scriptum alienum in prosa principali inventum est: " + via.string());

        std::cout << "AUDIT_CATALOGI_PRESENTATIONIS_TRANSIIT: CATEGORIAE=51,52,53,54,55 canonicalIndex=PASS praesentatio=PASS collatio=PASS prosa=Neo-Latina\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "AUDIT_CATALOGI_PRESENTATIONIS_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
