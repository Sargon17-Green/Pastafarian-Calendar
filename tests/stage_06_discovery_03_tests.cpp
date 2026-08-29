#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
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
        {"FOUNDATION_AD_POST", FOUNDATION_DAY_OLD, FOUNDATION_DAY_OLD + 1}
    };

    BaseMonsterManager manager;
    int discrepantiae = 0;
    int defectusViae = 0;

    for (const auto& c : casus) {
        const Integer expectatus = workCounts(c.calculationDay, c.targetDay).distance;
        const Integer legacyDirectus = oldDistance(c.calculationDay, c.targetDay);
        const auto report = manager.executeDistance(c.calculationDay, c.targetDay);

        if (report.calculationDay != c.calculationDay ||
            report.targetDay != c.targetDay ||
            report.branchCount < 4 ||
            report.legacyOutput != legacyDirectus) {
            std::cerr
                << "DEFECTUS_VIAE_DISCOVERY_03 " << c.nomen
                << ": legacy=" << decimal(legacyDirectus)
                << " per_viam=" << decimal(report.output)
                << "\n";
            ++defectusViae;
            continue;
        }

        if (report.output != expectatus) {
            std::cerr
                << "DISCREPANTIA VIAE_DISTANTIAE " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(report.output)
                << "\n";
            ++discrepantiae;
        } else {
            std::cout
                << "CONCORDANTIA VIAE_DISTANTIAE " << c.nomen
                << ": valor=" << decimal(report.output)
                << "\n";
        }
    }

    const std::string viaFontis = argc >= 2 ? argv[1] : "src/monster.cpp";
    const std::string fons = legeTotum(viaFontis);
    if (fons.find("Integer oldDistance(") == std::string::npos) {
        std::cerr << "CICATRIX_OLD_DISTANCE_DELETA\n";
        ++defectusViae;
    }

    if (defectusViae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_03_INOPINATE_DEFECIT: "
            << defectusViae
            << " defectus viae inventi sunt\n";
        return 2;
    }

    if (discrepantiae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_03_DEFECIT: "
            << discrepantiae
            << " discrepantiae normativae inventae sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_DISCOVERY_03_TRANSIIT\n";
    return 0;
}
