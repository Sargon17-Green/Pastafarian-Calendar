#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <string>

namespace {

std::string decimal(const pastafari::Integer& x) {
    return x.convert_to<std::string>();
}

} // spatium nominum

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::StoneTable;
    using pastafari::buildStonesThroughWrongLegacyMutation;
    using pastafari::reference::buildStones;

    const StoneTable legacyDirecta = buildStonesThroughWrongLegacyMutation();
    const auto normativa = buildStones();

    int defectusViae = 0;
    int discrepantiae = 0;
    bool cicatrixDiscrepat = false;

    if (legacyDirecta[1] != normativa[1]) {
        std::cerr << "PRIMUS_LAPIS_LEGACY_INOPINATE_DISCREPAT\n";
        ++defectusViae;
    }

    for (int i = 2; i <= 46; ++i) {
        for (int k = 0; k < 5; ++k) {
            if (legacyDirecta[i][k] != normativa[i][k]) {
                cicatrixDiscrepat = true;
            }
        }
    }

    if (!cicatrixDiscrepat) {
        std::cerr << "CICATRIX_MUTATIONIS_SEQUENTIALIS_NON_APPARET\n";
        ++defectusViae;
    }

    BaseMonsterManager manager;
    const auto report = manager.executeStoneTable();

    if (report.status != "LEGACY_STONE_TABLE_EXPOSED" ||
        report.handler != "Discovery04StoneMutationHandler" ||
        report.branchCount < 4) {
        std::cerr
            << "DEFECTUS_VIAE_DISCOVERY_04"
            << ": status=" << report.status
            << " handler=" << report.handler
            << " rami=" << report.branchCount
            << "\n";
        ++defectusViae;
    }

    for (int i = 1; i <= 46; ++i) {
        for (int k = 0; k < 5; ++k) {
            if (report.output[i][k] != normativa[i][k]) {
                if (discrepantiae < 10) {
                    std::cerr
                        << "DISCREPANTIA LAPIDUM i=" << i
                        << " pars=" << (k + 1)
                        << ": expectatus=" << decimal(normativa[i][k])
                        << " actualis=" << decimal(report.output[i][k])
                        << "\n";
                }
                ++discrepantiae;
            }
        }
    }

    if (defectusViae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_04_INOPINATE_DEFECIT: "
            << defectusViae
            << " defectus viae inventi sunt\n";
        return 2;
    }

    if (discrepantiae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_04_DEFECIT: "
            << discrepantiae
            << " discrepantiae componentium normativae inventae sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_DISCOVERY_04_TRANSIIT\n";
    return 0;
}
