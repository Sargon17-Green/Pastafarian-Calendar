#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <array>
#include <iostream>

namespace {

using pastafari::BowlState;
using pastafari::Integer;
using pastafari::PermutationOrder;
using pastafari::PourTriplet;
using pastafari::Stone;

PermutationOrder ordoNormativus(const Integer& drop) {
    const auto ref = pastafari::reference::bowlOrderFromDrop(drop);
    PermutationOrder order{};
    for (std::size_t i = 0; i < order.size(); ++i) {
        order[i] = ref[i];
    }
    return order;
}

PourTriplet fusionesNormativae(const Integer& drop,
                               int index,
                               const BowlState& bowls,
                               const Stone& stone,
                               const PermutationOrder& order) {
    const Integer quadratum = drop * drop;
    PourTriplet out{};
    out[0] = pastafari::reference::SAVE(
        quadratum + stone[0] * bowls[static_cast<std::size_t>(order[0] - 1)] + 3 * index);
    out[1] = pastafari::reference::SAVE(
        quadratum + stone[1] * bowls[static_cast<std::size_t>(order[1] - 1)] + 5 * index);
    out[2] = pastafari::reference::SAVE(
        quadratum + stone[2] * bowls[static_cast<std::size_t>(order[2] - 1)] + 7 * index);
    return out;
}

BowlState commotioNormativa(const BowlState& bowls,
                            int index,
                            const Integer& drop,
                            const Stone& stone,
                            const PermutationOrder& order,
                            const PourTriplet& firstThreePours) {
    const BowlState antiqua = bowls;
    BowlState nova = bowls;
    const std::array<std::size_t, 6> lapisPerPositionem{{0, 1, 2, 3, 4, 0}};

    for (std::size_t position = 0; position < order.size(); ++position) {
        const std::size_t priorPos = (position + order.size() - 1) % order.size();
        const std::size_t nextPos = (position + 1) % order.size();
        const int id = order[position];
        const int priorId = order[priorPos];
        const int nextId = order[nextPos];
        const Integer fusio = position < firstThreePours.size() ? firstThreePours[position] : Integer{0};
        const Integer s = antiqua[static_cast<std::size_t>(id - 1)]
            + 2 * antiqua[static_cast<std::size_t>(priorId - 1)]
            + 3 * antiqua[static_cast<std::size_t>(nextId - 1)]
            + fusio
            + drop
            + stone[lapisPerPositionem[position]];
        nova[static_cast<std::size_t>(id - 1)] = pastafari::reference::SAVE(
            s * s
            + 5 * antiqua[static_cast<std::size_t>(priorId - 1)]
                * antiqua[static_cast<std::size_t>(nextId - 1)]
            + index * static_cast<int>(position + 1));
    }
    return nova;
}

std::string decimal(const Integer& x) {
    return x.convert_to<std::string>();
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::legacyStirBowlsInPlace;

    const BowlState bowls{{Integer{11}, Integer{13}, Integer{17}, Integer{19}, Integer{23}, Integer{29}}};
    const Stone stone{{Integer{2}, Integer{3}, Integer{5}, Integer{7}, Integer{11}}};
    constexpr int index = 4;
    const std::array<Integer, 2> drops{{Integer{1}, Integer{241}}};

    BaseMonsterManager manager;
    int defectusViae = 0;
    int discrepantiae = 0;

    for (const Integer& drop : drops) {
        const PermutationOrder order = ordoNormativus(drop);
        const PourTriplet pours = fusionesNormativae(drop, index, bowls, stone, order);
        const BowlState expectatae = commotioNormativa(bowls, index, drop, stone, order, pours);

        BowlState legacyDirectae = bowls;
        legacyStirBowlsInPlace(legacyDirectae, index, drop, stone, order, pours);
        const auto report = manager.executeInPlaceBowlStir(bowls, index, drop, stone, order, pours);

        if (report.input != bowls || report.drop != drop || report.index != index ||
            report.stoneRow != stone || report.order != order || report.firstThreePours != pours ||
            report.output != legacyDirectae || report.branchCount < 4 ||
            report.handler != "Discovery10InPlaceBowlHandler" ||
            report.status != "LEGACY_IN_PLACE_BOWL_STIR_EXPOSED") {
            std::cerr << "DEFECTUS_VIAE_DISCOVERY_10 drop=" << decimal(drop) << "\n";
            ++defectusViae;
            continue;
        }

        int discrepantiaeCasus = 0;
        for (std::size_t bowl = 0; bowl < report.output.size(); ++bowl) {
            if (report.output[bowl] != expectatae[bowl]) {
                std::cerr
                    << "DISCREPANTIA CRATERIS drop=" << decimal(drop)
                    << " id=" << (bowl + 1)
                    << " expectatus=" << decimal(expectatae[bowl])
                    << " actualis=" << decimal(report.output[bowl])
                    << "\n";
                ++discrepantiaeCasus;
                ++discrepantiae;
            }
        }
        const std::size_t primusId = static_cast<std::size_t>(order[0] - 1);
        if (report.output[primusId] != expectatae[primusId] || discrepantiaeCasus != 5) {
            std::cerr << "FORMA_CONTAMINATIONIS_INOPINATA drop=" << decimal(drop)
                      << " discrepantiae=" << discrepantiaeCasus << "\n";
            ++defectusViae;
        }
        std::cout << "CASUS_COMMOTIONIS drop=" << decimal(drop)
                  << " discrepantiae=" << discrepantiaeCasus << "\n";
    }

    if (defectusViae != 0) {
        std::cerr << "REGRESSIO_DISCOVERY_10_INOPINATE_DEFECIT: "
                  << defectusViae << " defectus viae inventi sunt\n";
        return 2;
    }

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_10_TRANSIIT\n";
        return 0;
    }

    if (discrepantiae == 10) {
        std::cerr << "REGRESSIO_DISCOVERY_10_DEFECIT: 10 discrepantiae craterum ex contaminatione in-place inventae sunt\n";
        return 1;
    }

    std::cerr << "REGRESSIO_DISCOVERY_10_INOPINATE_DEFECIT: "
              << discrepantiae
              << " discrepantiae craterum inventae sunt, sed decem exspectabantur\n";
    return 2;
}
