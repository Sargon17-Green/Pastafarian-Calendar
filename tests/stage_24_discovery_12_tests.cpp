#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <algorithm>
#include <iostream>
#include <sstream>

namespace {

std::string orderText(const pastafari::PermutationOrder& order) {
    std::ostringstream out;
    out << '[';
    for (std::size_t i = 0; i < order.size(); ++i) {
        if (i != 0) {
            out << ',';
        }
        out << order[i];
    }
    out << ']';
    return out.str();
}

int successorCircular(const pastafari::PermutationOrder& order, int queriedId) {
    const auto it = std::find(order.begin(), order.end(), queriedId);
    if (it == order.end()) {
        throw pastafari::BaseValidationError("queried ID in latch non inventus est");
    }
    const std::size_t pos = static_cast<std::size_t>(std::distance(order.begin(), it));
    return order[(pos + 1) % order.size()];
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::oldNextBowlFixedName;
    namespace ref = pastafari::reference;

    const auto expectedSauce = ref::sauce(ref::FOUNDATION_DAY, ref::FOUNDATION_DAY);
    const auto expectedLatch = expectedSauce.orderAtDrop46;

    BaseMonsterManager manager;
    int defectusViae = 0;
    int discrepantiaeActivae = 0;
    int cicatricesLegacy = 0;

    for (int queriedId = 1; queriedId <= 6; ++queriedId) {
        const int legacyDirectus = oldNextBowlFixedName(queriedId);
        const int expectatus = successorCircular(expectedLatch, queriedId);
        const auto report = manager.executeLegacyNextBowl(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            queriedId);

        const int expectatusLegacy = queriedId == 6 ? 1 : queriedId + 1;
        if (legacyDirectus != expectatusLegacy) {
            std::cerr << "DEFECTUS_CICATRICIS_NEXT_BOWL queried=" << queriedId
                      << ": expectatus_legacy=" << expectatusLegacy
                      << " actualis_legacy=" << legacyDirectus << '\n';
            ++defectusViae;
        }
        if (!report.patch11Prepared || report.latchWriteCount != 1 ||
            report.orderAt46Latch != expectedLatch || report.branchCount < 8) {
            std::cerr << "DEFECTUS_VIAE_DISCOVERY_12 queried=" << queriedId
                      << ": latch=" << orderText(report.orderAt46Latch)
                      << " scripturae=" << report.latchWriteCount
                      << " patch11=" << report.patch11Prepared
                      << " rami=" << report.branchCount << '\n';
            ++defectusViae;
            continue;
        }

        if (legacyDirectus != expectatus) {
            ++cicatricesLegacy;
        }
        if (report.outputBowlId != expectatus) {
            ++discrepantiaeActivae;
            std::cerr << "DISCREPANTIA_NEXT_BOWL queried=" << queriedId
                      << ": latch=" << orderText(report.orderAt46Latch)
                      << " expectatus=" << expectatus
                      << " actualis=" << report.outputBowlId
                      << " legacy=" << legacyDirectus << '\n';
        } else {
            std::cout << "CONCORDANTIA_NEXT_BOWL queried=" << queriedId
                      << ": valor=" << report.outputBowlId << '\n';
        }
    }

    if (defectusViae != 0) {
        std::cerr << "REGRESSIO_DISCOVERY_12_INOPINATE_DEFECIT: "
                  << defectusViae << " defectus viae inventi sunt\n";
        return 2;
    }
    if (cicatricesLegacy != 3) {
        std::cerr << "REGRESSIO_DISCOVERY_12_INOPINATE_DEFECIT: cicatrix legacy "
                  << cicatricesLegacy << " discrepantias habet, sed tres exspectantur\n";
        return 2;
    }
    if (discrepantiaeActivae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_12_TRANSIIT\n";
        return 0;
    }
    if (discrepantiaeActivae != 3) {
        std::cerr << "REGRESSIO_DISCOVERY_12_INOPINATE_DEFECIT: "
                  << discrepantiaeActivae
                  << " discrepantiae activae inventae sunt, sed tres exspectantur ante patch\n";
        return 2;
    }

    std::cerr << "REGRESSIO_DISCOVERY_12_DEFECIT: 3 discrepantiae normativae ex successore numerico fixo inventae sunt\n";
    return 1;
}
