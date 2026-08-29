#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <string>
#include <vector>

namespace {

struct CasusDistantiae {
    std::string nomen;
    pastafari::Integer calculationDay;
    pastafari::Integer targetDay;
};

std::string decimal(const pastafari::Integer& x) {
    return x.convert_to<std::string>();
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::distanceWithChronologicalPatch;
    using pastafari::oldDistance;
    using pastafari::reference::workCounts;

    const std::vector<CasusDistantiae> casus{
        {"IDEM_FOUNDATION", FOUNDATION_DAY_OLD, FOUNDATION_DAY_OLD},
        {"IDEM_POST", FOUNDATION_DAY_OLD + 7, FOUNDATION_DAY_OLD + 7},
        {"ADIACENS_POST", FOUNDATION_DAY_OLD + 1, FOUNDATION_DAY_OLD + 2},
        {"DUO_POST", FOUNDATION_DAY_OLD + 1, FOUNDATION_DAY_OLD + 3},
        {"ADIACENS_ANTE", FOUNDATION_DAY_OLD - 2, FOUNDATION_DAY_OLD - 1},
        {"DUO_ANTE", FOUNDATION_DAY_OLD - 3, FOUNDATION_DAY_OLD - 1},
        {"TRANS_FOUNDATION", FOUNDATION_DAY_OLD - 1, FOUNDATION_DAY_OLD + 1},
        {"FOUNDATION_AD_POST", FOUNDATION_DAY_OLD, FOUNDATION_DAY_OLD + 1},
        {"LONGE_POST", FOUNDATION_DAY_OLD + 101, FOUNDATION_DAY_OLD + 409},
        {"LONGE_ANTE", FOUNDATION_DAY_OLD - 701, FOUNDATION_DAY_OLD - 19},
        {"TRANS_LONGE", FOUNDATION_DAY_OLD - 333, FOUNDATION_DAY_OLD + 888}
    };

    BaseMonsterManager manager;
    int defectus = 0;

    if (oldDistance(FOUNDATION_DAY_OLD, FOUNDATION_DAY_OLD) != 0 ||
        oldDistance(FOUNDATION_DAY_OLD + 1, FOUNDATION_DAY_OLD + 3) != 4 ||
        oldDistance(FOUNDATION_DAY_OLD - 1, FOUNDATION_DAY_OLD + 1) != 1) {
        std::cerr << "CICATRIX_OLD_DISTANCE_DELETA_AUT_MUTATA\n";
        ++defectus;
    }

    for (const auto& c : casus) {
        const Integer expectatus = workCounts(c.calculationDay, c.targetDay).distance;
        const Integer legacy = oldDistance(c.calculationDay, c.targetDay);
        const Integer directus = distanceWithChronologicalPatch(
            c.calculationDay, c.targetDay, legacy);
        const auto report = manager.executeDistance(c.calculationDay, c.targetDay);
        const auto diagnosticus = manager.executeUnpatchedDistanceDiagnostic(
            c.calculationDay, c.targetDay);

        if (directus != expectatus) {
            std::cerr
                << "DISCREPANTIA PATCH_DIRECTUS " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(directus)
                << "\n";
            ++defectus;
        }

        if (report.output != expectatus || !report.patch03Applied) {
            std::cerr
                << "DISCREPANTIA VIA_PATCH_03 " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(report.output)
                << "\n";
            ++defectus;
        }

        if (report.legacyOutput != legacy) {
            std::cerr
                << "DISCREPANTIA CICATRICIS " << c.nomen
                << ": legacy expectatus=" << decimal(legacy)
                << " servatus=" << decimal(report.legacyOutput)
                << "\n";
            ++defectus;
        }

        if (diagnosticus.output != legacy ||
            diagnosticus.legacyOutput != legacy ||
            diagnosticus.patch03Applied) {
            std::cerr
                << "DISCREPANTIA VIA_DIAGNOSTICA " << c.nomen
                << ": legacy=" << decimal(legacy)
                << " diagnosticus=" << decimal(diagnosticus.output)
                << "\n";
            ++defectus;
        }

        Integer chronological = c.targetDay - c.calculationDay;
        if (chronological < 0) {
            chronological = -chronological;
        }
        if (legacy == chronological && directus != legacy + 1) {
            std::cerr << "RAMUS_CONCORDANS_NON_INCLUSIVUS " << c.nomen << "\n";
            ++defectus;
        }
        if (legacy != chronological && directus != chronological + 1) {
            std::cerr << "RAMUS_DIVERGENS_NON_CORRECTUS " << c.nomen << "\n";
            ++defectus;
        }
    }

    if (defectus != 0) {
        std::cerr
            << "REGRESSIO_PATCH_03_DEFECIT: "
            << defectus
            << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_03_TRANSIIT\n";
    return 0;
}
