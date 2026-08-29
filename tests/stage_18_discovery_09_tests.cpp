#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <string>

namespace {

using pastafari::BowlState;
using pastafari::Integer;
using pastafari::PermutationOrder;
using pastafari::PourTriplet;
using pastafari::Stone;

std::string decimal(const Integer& x) {
    return x.convert_to<std::string>();
}

PourTriplet poursNormativae(const Integer& drop,
                            int index,
                            const BowlState& oldBowls,
                            const Stone& stoneRow,
                            const PermutationOrder& order) {
    const Integer quadratum = drop * drop;
    PourTriplet out{};
    out[0] = pastafari::reference::SAVE(
        quadratum + stoneRow[0] * oldBowls[static_cast<std::size_t>(order[0] - 1)] + 3 * index);
    out[1] = pastafari::reference::SAVE(
        quadratum + stoneRow[1] * oldBowls[static_cast<std::size_t>(order[1] - 1)] + 5 * index);
    out[2] = pastafari::reference::SAVE(
        quadratum + stoneRow[2] * oldBowls[static_cast<std::size_t>(order[2] - 1)] + 7 * index);
    return out;
}

int discrepantiae(const PourTriplet& actualis, const PourTriplet& expectatus) {
    int n = 0;
    for (std::size_t p = 0; p < actualis.size(); ++p) {
        if (actualis[p] != expectatus[p]) {
            ++n;
        }
    }
    return n;
}

void imprimeOrdinem(const PermutationOrder& order) {
    std::cout << '[';
    for (std::size_t i = 0; i < order.size(); ++i) {
        if (i != 0) {
            std::cout << ',';
        }
        std::cout << order[i];
    }
    std::cout << ']';
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::legacyPoursToFixedBowlIds;
    using pastafari::reference::bowlOrderFromDrop;

    const BowlState bowls{{Integer{11}, Integer{13}, Integer{17}, Integer{19}, Integer{23}, Integer{29}}};
    const Stone stones{{Integer{2}, Integer{3}, Integer{5}, Integer{7}, Integer{11}}};
    constexpr int index = 4;

    BaseMonsterManager manager;
    int defectusViae = 0;
    int discrepantiaeActivae = 0;

    const std::array<Integer, 2> drops{{Integer{1}, Integer{241}}};
    for (const Integer& drop : drops) {
        const auto orderRef = bowlOrderFromDrop(drop);
        PermutationOrder order{};
        for (std::size_t p = 0; p < order.size(); ++p) {
            order[p] = orderRef[p];
        }

        const PourTriplet expectatus = poursNormativae(drop, index, bowls, stones, order);
        const auto legacyDirectus = legacyPoursToFixedBowlIds(drop, index, bowls, stones);
        const auto report = manager.executeFixedPours(drop, index, bowls, stones);

        if (legacyDirectus.order != order || report.order != order) {
            std::cerr << "DEFECTUS_ORDINIS_DISCOVERY_09 drop=" << decimal(drop) << "\n";
            ++defectusViae;
            continue;
        }
        if (legacyDirectus.fixedBowlIds != std::array<int, 3>{{1, 2, 3}}) {
            std::cerr << "CICATRIX_IDS_FIXORUM_DELETA drop=" << decimal(drop) << "\n";
            ++defectusViae;
            continue;
        }
        if (report.drop != drop || report.index != index || report.oldBowls != bowls || report.stoneRow != stones ||
            report.branchCount < 4) {
            std::cerr << "DEFECTUS_VIAE_DISCOVERY_09 drop=" << decimal(drop) << "\n";
            ++defectusViae;
            continue;
        }

        const int legacyDiff = discrepantiae(legacyDirectus.pours, expectatus);
        const int activeDiff = discrepantiae(report.output, expectatus);

        std::cout << "CASUS_FUSIONIS drop=" << decimal(drop) << " ordo=";
        imprimeOrdinem(order);
        std::cout << " discrepantiae_legacy=" << legacyDiff
                  << " discrepantiae_activae=" << activeDiff << "\n";

        if (drop == 1 && legacyDiff != 0) {
            std::cerr << "COINCIDENTIA_IDENTITATIS_NON_SERVATA\n";
            ++defectusViae;
        }
        if (drop == 241 && legacyDiff != 3) {
            std::cerr << "CICATRIX_FUSIONUM_NON_TRIPLEX: inventae=" << legacyDiff << "\n";
            ++defectusViae;
        }

        for (std::size_t p = 0; p < report.output.size(); ++p) {
            if (report.output[p] != expectatus[p]) {
                std::cerr
                    << "DISCREPANTIA FUSIONIS drop=" << decimal(drop)
                    << " positio=" << (p + 1)
                    << " crater_normativus=" << order[p]
                    << " crater_legacy=" << (p + 1)
                    << " expectatus=" << decimal(expectatus[p])
                    << " actualis=" << decimal(report.output[p])
                    << "\n";
                ++discrepantiaeActivae;
            }
        }
    }

    if (defectusViae != 0) {
        std::cerr << "REGRESSIO_DISCOVERY_09_INOPINATE_DEFECIT: "
                  << defectusViae << " defectus viae inventi sunt\n";
        return 2;
    }

    if (discrepantiaeActivae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_09_TRANSIIT\n";
        return 0;
    }

    if (discrepantiaeActivae == 3) {
        std::cerr << "REGRESSIO_DISCOVERY_09_DEFECIT: 3 discrepantiae normativae ex crateris fixis inventae sunt\n";
        return 1;
    }

    std::cerr << "REGRESSIO_DISCOVERY_09_INOPINATE_DEFECIT: "
              << discrepantiaeActivae << " discrepantiae inventae sunt\n";
    return 2;
}
