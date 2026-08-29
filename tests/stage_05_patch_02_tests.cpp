#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace {

struct CasusDiei {
    std::string nomen;
    pastafari::Integer dies;
};

std::string decimal(const pastafari::Integer& x) {
    return x.convert_to<std::string>();
}

std::string legeTotum(const std::string& via) {
    std::ifstream f(via);
    std::ostringstream s;
    s << f.rdbuf();
    return s.str();
}

} // namespace

int main(int argc, char** argv) {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::dayTagWithFoundationScar;
    using pastafari::oldDayTag;
    using pastafari::reference::dayCount;

    const std::vector<CasusDiei> casus{
        {"FOUNDATION", FOUNDATION_DAY_OLD},
        {"FOUNDATION+1", FOUNDATION_DAY_OLD + 1},
        {"FOUNDATION+2", FOUNDATION_DAY_OLD + 2},
        {"FOUNDATION-1", FOUNDATION_DAY_OLD - 1},
        {"FOUNDATION-2", FOUNDATION_DAY_OLD - 2},
        {"LONGE_POST", FOUNDATION_DAY_OLD + Integer{123456789}},
        {"LONGE_ANTE", FOUNDATION_DAY_OLD - Integer{123456789}}
    };

    int defectus = 0;
    BaseMonsterManager manager;

    if (oldDayTag(FOUNDATION_DAY_OLD) != 0 ||
        oldDayTag(FOUNDATION_DAY_OLD + 1) != 2 ||
        oldDayTag(FOUNDATION_DAY_OLD + 2) != 4 ||
        oldDayTag(FOUNDATION_DAY_OLD - 1) != 2) {
        std::cerr << "CICATRIX_OLD_DAY_TAG_DELETA_VEL_MUTATA\n";
        ++defectus;
    }

    for (const auto& c : casus) {
        const Integer expectatus = dayCount(c.dies);
        const Integer directus = dayTagWithFoundationScar(c.dies);
        const auto report = manager.executeLegacyDayTag(c.dies);
        const auto diagnosticum = manager.executeUnpatchedDayTagDiagnostic(c.dies);

        if (directus != expectatus) {
            std::cerr
                << "DISCREPANTIA dayTagWithFoundationScar " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(directus)
                << "\n";
            ++defectus;
        }

        if (report.output != expectatus || !report.patch02Applied ||
            report.legacyOutputBeforePatch != oldDayTag(c.dies)) {
            std::cerr
                << "DISCREPANTIA VIAE_PATCH_02 " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(report.output)
                << " legacy=" << decimal(report.legacyOutputBeforePatch)
                << "\n";
            ++defectus;
        }

        if (report.status != "PATCHED_DAY_TAG_RESULT_EXPOSED" ||
            report.handler != "Patch02DayTagHandler") {
            std::cerr
                << "DEFECTUS_STATUS_PATCH_02 " << c.nomen
                << ": status=" << report.status
                << " handler=" << report.handler
                << "\n";
            ++defectus;
        }

        if (diagnosticum.output != oldDayTag(c.dies) || diagnosticum.patch02Applied) {
            std::cerr
                << "DEFECTUS_VIAE_DIAGNOSTICAE_OLD_DAY_TAG " << c.nomen
                << "\n";
            ++defectus;
        }
    }

    const std::string viaFontis = argc >= 2 ? argv[1] : "src/monster.cpp";
    const std::string fons = legeTotum(viaFontis);
    const std::string custosPrimus = "if (day >= FOUNDATION_DAY_OLD)";
    const std::string custosSecundus = "if (day == FOUNDATION_DAY_OLD && n != 1)";

    if (fons.find(custosPrimus) == std::string::npos ||
        fons.find(custosSecundus) == std::string::npos) {
        std::cerr << "CICATRIX_PATCH_02_INCOMPLETA: duo custodes physice requiruntur\n";
        ++defectus;
    }

    if (fons.find("patchedCounts") != std::string::npos ||
        fons.find("Patch03") != std::string::npos ||
        fons.find("patch03") != std::string::npos) {
        std::cerr << "CONTAMINATIO_PATCH_03_INVENTA\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr
            << "REGRESSIO_PATCH_02_DEFECIT: "
            << defectus
            << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_02_TRANSIIT\n";
    return 0;
}
