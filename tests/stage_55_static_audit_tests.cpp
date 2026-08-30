#include "pastafari/source_language_catalog.hpp"

#include <array>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <regex>
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
    require(static_cast<bool>(in), "fasciculus audit aperiri non potest: " + via.string());
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

std::set<std::string> omnes(const std::string& textus, const std::regex& forma) {
    std::set<std::string> exitus;
    for (std::sregex_iterator it(textus.begin(), textus.end(), forma), finis; it != finis; ++it) {
        exitus.insert((*it)[0].str());
    }
    return exitus;
}

bool habetScriptumProhibitum(const std::string& s) {
    const unsigned char* p = reinterpret_cast<const unsigned char*>(s.data());
    const unsigned char* end = p + s.size();
    while (p < end) {
        unsigned int cp = 0;
        if (*p < 0x80) {
            cp = *p++;
        } else if ((*p & 0xE0) == 0xC0 && p + 1 < end) {
            cp = ((*p & 0x1F) << 6) | (p[1] & 0x3F); p += 2;
        } else if ((*p & 0xF0) == 0xE0 && p + 2 < end) {
            cp = ((*p & 0x0F) << 12) | ((p[1] & 0x3F) << 6) | (p[2] & 0x3F); p += 3;
        } else if ((*p & 0xF8) == 0xF0 && p + 3 < end) {
            cp = ((*p & 0x07) << 18) | ((p[1] & 0x3F) << 12) | ((p[2] & 0x3F) << 6) | (p[3] & 0x3F); p += 4;
        } else {
            ++p; continue;
        }
        if ((cp >= 0x0590 && cp <= 0x05FF) ||
            (cp >= 0x0600 && cp <= 0x06FF) ||
            (cp >= 0x0400 && cp <= 0x052F)) return true;
    }
    return false;
}
}

int main() {
    try {
        const std::string caput = lege("include/pastafari/monster.hpp");
        const std::string productio = lege("src/monster.cpp");

        const auto cicatrices = omnes(caput, std::regex("executeUnpatched[A-Za-z0-9_]*Diagnostic"));
        const auto patchHandlers = omnes(caput, std::regex("class Patch[0-9]{2}[A-Za-z0-9_]*Handler"));
        require(cicatrices.size() == 26, "viginti sex viae diagnosticae legacy requiruntur");
        require(patchHandlers.size() == 26, "viginti sex patch handlers requiruntur");

        for (int i = 1; i <= 26; ++i) {
            std::string numerus = i < 10 ? "0" + std::to_string(i) : std::to_string(i);
            bool inventus = false;
            for (const auto& nomen : patchHandlers) {
                if (nomen.find("Patch" + numerus) != std::string::npos) inventus = true;
            }
            require(inventus, "patch handler canonicus deest: " + numerus);
        }

        require(productio.find("normative_reference") == std::string::npos &&
                productio.find("NormativeOracle") == std::string::npos,
                "productio oracle locale tangere non debet");
        require(caput.find("normative_reference") == std::string::npos &&
                caput.find("NormativeOracle") == std::string::npos,
                "API productionis oracle locale tangere non debet");

        std::set<std::size_t> indicesSegmentorum;
        for (const auto& e : pastafari::CUTLET_SOURCE_CATALOG) indicesSegmentorum.insert(e.canonicalIndex);
        require(indicesSegmentorum.size() == 17, "17 indices segmentorum distincti requiruntur");
        for (std::size_t i = 1; i <= 17; ++i) require(indicesSegmentorum.count(i) == 1, "index segmenti deest");

        std::set<std::size_t> indicesMensium;
        for (const auto& e : pastafari::MONTH_SOURCE_CATALOG) indicesMensium.insert(e.canonicalIndex);
        require(indicesMensium.size() == 47, "47 indices mensium distincti requiruntur");
        for (std::size_t i = 1; i <= 47; ++i) require(indicesMensium.count(i) == 1, "index mensis deest");

        const std::array<fs::path,10> prosa{{
            "DEPENDENCIES.md", "DEVELOPMENT_STAGE.md", "README.md",
            "SOURCE_LANGUAGE_CATALOG.md", "SPAGHETTI_DEVELOPMENT_HISTORY.md",
            "STAGE_55_FINAL_DIFFERENTIAL_LEDGER.md",
            "STAGE_55_SAFE_MONSTER_LEDGER.md",
            "STAGE_55_INVARIANT_LEDGER.md",
            "STAGE_55_LOCAL_TEST_LOG.txt",
            "STAGE_55_FINAL_BYTE_AUDIT.txt"
        }};
        for (const auto& via : prosa) {
            require(!habetScriptumProhibitum(lege(via)),
                    "scriptum humanum alienum inventum est: " + via.string());
        }

        require(productio.find("random_device") == std::string::npos &&
                productio.find("mt19937") == std::string::npos &&
                productio.find("srand(") == std::string::npos &&
                productio.find("rand(") == std::string::npos &&
                productio.find("system_clock") == std::string::npos &&
                productio.find("steady_clock") == std::string::npos,
                "fons nondeterministicus in productione inventus est");

        std::cout << "AUDIT_STATICUS_GRADUS_55_TRANSIIT: cicatrices=26 patches=26 catalogi=17/47 oracle=NONE determinismus=PASS prosa=Neo-Latina\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "AUDIT_STATICUS_GRADUS_55_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
