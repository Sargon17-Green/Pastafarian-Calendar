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
        const auto report = manager.executeLegacyDayTag(c.dies);

        if (report.input != c.dies || report.branchCount < 4) {
            std::cerr
                << "DEFECTUS_VIAE_DISCOVERY_02 " << c.nomen
                << ": input=" << decimal(report.input)
                << " rami=" << report.branchCount
                << "\n";
            ++defectusViae;
            continue;
        }

        if (report.output != expectatus) {
            std::cerr
                << "DISCREPANTIA VIAE_DIEI " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(report.output)
                << "\n";
            ++discrepantiae;
        } else {
            std::cout
                << "CONCORDANTIA VIAE_DIEI " << c.nomen
                << ": valor=" << decimal(report.output)
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

    if (discrepantiae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_02_DEFECIT: "
            << discrepantiae
            << " discrepantiae normativae inventae sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_DISCOVERY_02_TRANSIIT\n";
    return 0;
}
