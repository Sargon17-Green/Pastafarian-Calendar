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

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::legacyStirBowlsInPlace;
    using pastafari::stirBowlsThroughVaultOld;

    const BowlState bowls{{Integer{11}, Integer{13}, Integer{17}, Integer{19}, Integer{23}, Integer{29}}};
    const Stone stone{{Integer{2}, Integer{3}, Integer{5}, Integer{7}, Integer{11}}};

    BaseMonsterManager manager;
    int defectus = 0;
    int cicatricesDivergentes = 0;

    for (int raw = 1; raw <= 720; ++raw) {
        const Integer drop = raw;
        const int index = ((raw - 1) % 46) + 1;
        const PermutationOrder order = ordoNormativus(drop);
        const PourTriplet pours = fusionesNormativae(drop, index, bowls, stone, order);
        const BowlState expectatae = commotioNormativa(bowls, index, drop, stone, order, pours);

        BowlState legacy = bowls;
        legacyStirBowlsInPlace(legacy, index, drop, stone, order, pours);
        if (legacy != expectatae) {
            ++cicatricesDivergentes;
        }

        const auto directa = stirBowlsThroughVaultOld(bowls, index, drop, stone, order, pours);
        if (directa.vaultOld != bowls || directa.pending != expectatae || directa.output != expectatae) {
            std::cerr << "DEFECTUS_DIRECTUS_PATCH_10 raw=" << raw << "\n";
            ++defectus;
            continue;
        }

        const auto report = manager.executeInPlaceBowlStir(bowls, index, drop, stone, order, pours);
        if (report.output != expectatae || report.legacyOutputBeforePatch != legacy ||
            report.vaultOld != bowls || report.pending != expectatae || !report.patch10Applied ||
            report.handler != "Patch10InPlaceBowlHandler" ||
            report.status != "PATCHED_DEFERRED_BOWL_STIR_EXPOSED" ||
            report.branchCount < 5) {
            std::cerr << "DEFECTUS_VIAE_PATCH_10 raw=" << raw << "\n";
            ++defectus;
            continue;
        }

        const auto diagnosticum = manager.executeUnpatchedInPlaceBowlStirDiagnostic(
            bowls, index, drop, stone, order, pours);
        if (diagnosticum.output != legacy || diagnosticum.patch10Applied ||
            diagnosticum.handler != "Discovery10InPlaceBowlHandler" ||
            diagnosticum.status != "LEGACY_IN_PLACE_BOWL_STIR_EXPOSED") {
            std::cerr << "DEFECTUS_CICATRICIS_PATCH_10 raw=" << raw << "\n";
            ++defectus;
        }
    }

    if (cicatricesDivergentes == 0) {
        std::cerr << "CICATRIX_LEGACY_NON_OBSERVATA\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_10_DEFECIT: " << defectus << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_10_TRANSIIT\n";
    std::cout << "ORDINES_PROBATI=720\n";
    std::cout << "CICATRICES_LEGACY_DIVERGENTES=" << cicatricesDivergentes << "\n";
    return 0;
}
