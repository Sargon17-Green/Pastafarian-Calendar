#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <array>
#include <iostream>

namespace {

using pastafari::BowlAlias;
using pastafari::BowlState;
using pastafari::Integer;
using pastafari::PermutationOrder;
using pastafari::PourTriplet;
using pastafari::Stone;

PourTriplet poursNormativae(const Integer& drop,
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

PermutationOrder ordoNormativus(const Integer& drop) {
    const auto ref = pastafari::reference::bowlOrderFromDrop(drop);
    PermutationOrder order{};
    for (std::size_t i = 0; i < order.size(); ++i) {
        order[i] = ref[i];
    }
    return order;
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::bowlAtAliasedPosition;
    using pastafari::installBowlAlias;
    using pastafari::legacyPoursToFixedBowlIds;
    using pastafari::poursThroughBowlAlias;

    const BowlState bowls{{Integer{11}, Integer{13}, Integer{17}, Integer{19}, Integer{23}, Integer{29}}};
    const Stone stone{{Integer{2}, Integer{3}, Integer{5}, Integer{7}, Integer{11}}};
    constexpr int index = 4;

    BaseMonsterManager manager;
    int defectus = 0;
    int cicatricesDivergentes = 0;

    for (int d = 1; d <= 720; ++d) {
        const Integer drop{d};
        const PermutationOrder order = ordoNormativus(drop);
        const BowlAlias alias = installBowlAlias(order);
        const PourTriplet expectatae = poursNormativae(drop, index, bowls, stone, order);
        const auto legacy = legacyPoursToFixedBowlIds(drop, index, bowls, stone);
        const auto directus = poursThroughBowlAlias(drop, index, bowls, stone, order);
        const auto report = manager.executeFixedPours(drop, index, bowls, stone);

        if (alias != order || directus.bowlAlias != order || report.bowlAlias != order) {
            std::cerr << "DISCREPANTIA_BOWL_ALIAS drop=" << d << "\n";
            ++defectus;
        }

        const std::array<int, 3> ids{{order[0], order[1], order[2]}};
        if (directus.aliasedBowlIds != ids || report.aliasedBowlIds != ids) {
            std::cerr << "DISCREPANTIA_ID_ALIAS drop=" << d << "\n";
            ++defectus;
        }

        for (int position = 1; position <= 3; ++position) {
            const Integer perAlias = bowlAtAliasedPosition(bowls, alias, position);
            const Integer perId = bowls[static_cast<std::size_t>(order[static_cast<std::size_t>(position - 1)] - 1)];
            if (perAlias != perId) {
                std::cerr << "LECTIO_ALIAS_VITIOSA drop=" << d << " positio=" << position << "\n";
                ++defectus;
            }
        }

        if (directus.pours != expectatae || report.output != expectatae) {
            std::cerr << "FUSIONES_ALIAS_NON_NORMATIVAE drop=" << d << "\n";
            ++defectus;
        }

        if (!report.patch09Applied ||
            report.legacyOutputBeforePatch != legacy.pours ||
            report.legacyFixedBowlIdsBeforePatch != std::array<int, 3>{{1, 2, 3}} ||
            report.fixedBowlIds != std::array<int, 3>{{1, 2, 3}}) {
            std::cerr << "CICATRIX_LEGACY_NON_SERVATA drop=" << d << "\n";
            ++defectus;
        }

        if (legacy.pours != expectatae) {
            ++cicatricesDivergentes;
        }
    }

    const Integer dropScar{241};
    const auto legacyScar = legacyPoursToFixedBowlIds(dropScar, index, bowls, stone);
    const auto diagnostic = manager.executeUnpatchedFixedPoursDiagnostic(dropScar, index, bowls, stone);
    if (diagnostic.output != legacyScar.pours || diagnostic.patch09Applied ||
        diagnostic.handler != "Discovery09FixedPourHandler") {
        std::cerr << "VIA_DIAGNOSTICA_LEGACY_DELETA\n";
        ++defectus;
    }

    if (cicatricesDivergentes == 0) {
        std::cerr << "CICATRIX_FUSIONUM_LEGACY_NON_AMPLIUS_DIVERGIT\n";
        ++defectus;
    }

    bool terminusInferiorReiectus = false;
    bool terminusSuperiorReiectus = false;
    try {
        (void)bowlAtAliasedPosition(bowls, installBowlAlias(ordoNormativus(Integer{1})), 0);
    } catch (const pastafari::BaseValidationError&) {
        terminusInferiorReiectus = true;
    }
    try {
        (void)bowlAtAliasedPosition(bowls, installBowlAlias(ordoNormativus(Integer{1})), 7);
    } catch (const pastafari::BaseValidationError&) {
        terminusSuperiorReiectus = true;
    }
    if (!terminusInferiorReiectus || !terminusSuperiorReiectus) {
        std::cerr << "FINES_POSITIONIS_ALIAS_NON_SERVATI\n";
        ++defectus;
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_09_DEFECIT: " << defectus << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_09_TRANSIIT\n";
    std::cout << "CASUS_PERMUTATIONUM_PROBATI=720\n";
    std::cout << "CICATRICES_LEGACY_DIVERGENTES=" << cicatricesDivergentes << "\n";
    return 0;
}
