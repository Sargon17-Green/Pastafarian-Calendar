#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <cstddef>
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

std::size_t positionOneBased(const pastafari::PermutationOrder& order, int queriedId) {
    for (std::size_t i = 0; i < order.size(); ++i) {
        if (order[i] == queriedId) {
            return i + 1;
        }
    }
    throw pastafari::BaseValidationError("queried ID in ordine testis non inventus est");
}

int successorCircularIndependent(const pastafari::PermutationOrder& order, int queriedId) {
    const std::size_t pos1 = positionOneBased(order, queriedId);
    return order[pos1 % order.size()];
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::nextBowlThroughOrderAt46Latch;
    using pastafari::oldNextBowlFixedName;
    namespace ref = pastafari::reference;

    const auto expectedSauce = ref::sauce(ref::FOUNDATION_DAY, ref::FOUNDATION_DAY);
    const auto expectedLatch = expectedSauce.orderAtDrop46;

    BaseMonsterManager manager;
    int defectus = 0;
    int cicatricesLegacyDivergentes = 0;

    for (int queriedId = 1; queriedId <= 6; ++queriedId) {
        const int expectedFixed = queriedId == 6 ? 1 : queriedId + 1;
        const int expectedPatched = successorCircularIndependent(expectedLatch, queriedId);
        const std::size_t expectedPosition = positionOneBased(expectedLatch, queriedId);

        const int directLegacy = oldNextBowlFixedName(queriedId);
        const int directPatched = nextBowlThroughOrderAt46Latch(expectedLatch, queriedId);
        const auto diagnostic = manager.executeUnpatchedNextBowlDiagnostic(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            queriedId);
        const auto active = manager.executeLegacyNextBowl(
            FOUNDATION_DAY_OLD,
            FOUNDATION_DAY_OLD,
            queriedId);

        if (directLegacy != expectedFixed ||
            diagnostic.outputBowlId != expectedFixed ||
            diagnostic.legacyOutputBeforePatch != expectedFixed ||
            diagnostic.patch12Applied ||
            diagnostic.handler != "Discovery12NextBowlHandler") {
            std::cerr << "DEFECTUS_CICATRICIS_PATCH_12 queried=" << queriedId
                      << ": directus=" << directLegacy
                      << " diagnosticus=" << diagnostic.outputBowlId
                      << " legacy_report=" << diagnostic.legacyOutputBeforePatch
                      << " patch12=" << diagnostic.patch12Applied
                      << " handler=" << diagnostic.handler << '\n';
            ++defectus;
        }

        if (!active.patch11Prepared || active.latchWriteCount != 1 ||
            active.orderAt46Latch != expectedLatch || !active.patch12Applied ||
            active.queriedPosition != expectedPosition ||
            active.legacyOutputBeforePatch != expectedFixed ||
            active.handler != "Patch12NextBowlHandler") {
            std::cerr << "DEFECTUS_VIAE_PATCH_12 queried=" << queriedId
                      << ": latch=" << orderText(active.orderAt46Latch)
                      << " scripturae=" << active.latchWriteCount
                      << " positio=" << active.queriedPosition
                      << " legacy=" << active.legacyOutputBeforePatch
                      << " patch12=" << active.patch12Applied
                      << " handler=" << active.handler << '\n';
            ++defectus;
        }

        if (directPatched != expectedPatched || active.outputBowlId != expectedPatched) {
            std::cerr << "DEFECTUS_SUCCESSORIS_CIRCULARIS queried=" << queriedId
                      << ": expectatus=" << expectedPatched
                      << " directus=" << directPatched
                      << " activus=" << active.outputBowlId << '\n';
            ++defectus;
        }

        if (expectedFixed != expectedPatched) {
            ++cicatricesLegacyDivergentes;
        }
    }

    const int queriedAtLastPosition = expectedLatch.back();
    const auto wrapReport = manager.executeLegacyNextBowl(
        FOUNDATION_DAY_OLD,
        FOUNDATION_DAY_OLD,
        queriedAtLastPosition);
    if (wrapReport.queriedPosition != expectedLatch.size() ||
        wrapReport.outputBowlId != expectedLatch.front()) {
        std::cerr << "DEFECTUS_WRAP_PATCH_12 queried=" << queriedAtLastPosition
                  << ": positio=" << wrapReport.queriedPosition
                  << " expectatus=" << expectedLatch.front()
                  << " actualis=" << wrapReport.outputBowlId << '\n';
        ++defectus;
    }

    bool invalidumInferius = false;
    bool invalidumSuperius = false;
    try {
        static_cast<void>(nextBowlThroughOrderAt46Latch(expectedLatch, 0));
    } catch (const pastafari::BaseValidationError&) {
        invalidumInferius = true;
    }
    try {
        static_cast<void>(nextBowlThroughOrderAt46Latch(expectedLatch, 7));
    } catch (const pastafari::BaseValidationError&) {
        invalidumSuperius = true;
    }
    if (!invalidumInferius || !invalidumSuperius) {
        std::cerr << "DEFECTUS_FINIUM_PATCH_12: ID 0 et 7 reici debent\n";
        ++defectus;
    }

    if (cicatricesLegacyDivergentes != 3) {
        std::cerr << "DEFECTUS_NUMERI_CICATRICUM_PATCH_12: expectatae=3 actualis="
                  << cicatricesLegacyDivergentes << '\n';
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_12_DEFECIT: " << defectus
                  << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_12_TRANSIIT\n";
    std::cout << "LATCH=" << orderText(expectedLatch) << '\n';
    std::cout << "CICATRICES_LEGACY_DIVERGENTES=" << cicatricesLegacyDivergentes << '\n';
    std::cout << "WRAP_QUERIED=" << queriedAtLastPosition
              << " WRAP_OUTPUT=" << expectedLatch.front() << '\n';
    return 0;
}
