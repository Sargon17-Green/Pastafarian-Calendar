#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
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

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::oldDayTag;
    using pastafari::reference::dayCount;

    const std::vector<CasusDiei> casus{
        {"FOUNDATION", FOUNDATION_DAY_OLD},
        {"FOUNDATION+1", FOUNDATION_DAY_OLD + 1},
        {"FOUNDATION+2", FOUNDATION_DAY_OLD + 2},
        {"FOUNDATION-1", FOUNDATION_DAY_OLD - 1},
        {"FOUNDATION-2", FOUNDATION_DAY_OLD - 2}
    };

    BaseMonsterManager manager;
    int discrepantiae = 0;
    int defectusViae = 0;

    for (const auto& c : casus) {
        const Integer expectatus = dayCount(c.dies);
        const Integer legacyDirectus = oldDayTag(c.dies);
        const auto report = manager.executeLegacyDayTag(c.dies);

        if (report.output != legacyDirectus || report.input != c.dies || report.branchCount < 4) {
            std::cerr
                << "DEFECTUS_VIAE_DISCOVERY_02 " << c.nomen
                << ": directus=" << decimal(legacyDirectus)
                << " per_viam=" << decimal(report.output)
                << "\n";
            ++defectusViae;
            continue;
        }

        if (report.status != "LEGACY_DAY_TAG_RESULT_EXPOSED" ||
            report.handler != "Discovery02DayTagHandler") {
            std::cerr
                << "DEFECTUS_STATUS_DISCOVERY_02 " << c.nomen
                << ": status=" << report.status
                << " handler=" << report.handler
                << "\n";
            ++defectusViae;
            continue;
        }

        if (legacyDirectus != expectatus) {
            std::cerr
                << "DISCREPANTIA oldDayTag " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(legacyDirectus)
                << "\n";
            ++discrepantiae;
        } else {
            std::cout
                << "CONCORDANTIA oldDayTag " << c.nomen
                << ": valor=" << decimal(legacyDirectus)
                << "\n";
        }
    }

    if (defectusViae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_02_INOPINATE_DEFECIT: "
            << defectusViae
            << " defectus viae inventi sunt\n";
        return 2;
    }

    if (discrepantiae != 3) {
        std::cerr
            << "REGRESSIO_DISCOVERY_02_INOPINATE_DEFECIT: "
            << discrepantiae
            << " discrepantiae inventae sunt, sed tres exspectabantur\n";
        return 2;
    }

    std::cerr
        << "REGRESSIO_DISCOVERY_02_DEFECIT: "
        << discrepantiae
        << " discrepantiae normativae exspectatae inventae sunt\n";
    return 1;
}
