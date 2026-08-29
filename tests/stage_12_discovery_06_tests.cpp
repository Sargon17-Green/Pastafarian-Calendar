#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <string>

namespace {

std::string decimal(const pastafari::Integer& x) {
    return x.convert_to<std::string>();
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::BaseValidationError;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::Integer;
    using pastafari::VisibleDropStore;
    using pastafari::legacyPrior;
    using pastafari::reference::buildHiddenDrops;
    using pastafari::reference::buildStones;
    using pastafari::reference::workCounts;

    const Integer calculationDay = FOUNDATION_DAY_OLD + 17;
    const Integer targetDay = FOUNDATION_DAY_OLD + 43;
    const VisibleDropStore visibiles{Integer{101}, Integer{202}, Integer{303}};

    int defectusStructurae = 0;

    if (legacyPrior(visibiles, 4, 1) != 303 ||
        legacyPrior(visibiles, 4, 2) != 202 ||
        legacyPrior(visibiles, 4, 3) != 101) {
        std::cerr << "DEFECTUS_PRIOR_VISIBILIS: helper legacy historiam visibilem recte non legit\n";
        ++defectusStructurae;
    }

    bool retroNimisReiectum = false;
    try {
        static_cast<void>(legacyPrior(visibiles, 4, 4));
    } catch (const BaseValidationError&) {
        retroNimisReiectum = true;
    }
    if (!retroNimisReiectum) {
        std::cerr << "DEFECTUS_LIMINIS_PRIOR: index non visibilis a helper legacy non reiectus est\n";
        ++defectusStructurae;
    }

    BaseMonsterManager manager;
    const auto validum = manager.executePrior(calculationDay, targetDay, visibiles, 4, 2);
    if (validum.output != 202 ||
        validum.i != 4 ||
        validum.back != 2 ||
        validum.status != "LEGACY_PRIOR_VISIBLE_RESULT_EXPOSED" ||
        validum.handler != "Discovery06PriorHandler" ||
        validum.branchCount < 4) {
        std::cerr << "DEFECTUS_VIAE_DISCOVERY_06: via activa historiam visibilem recte non exposuit\n";
        ++defectusStructurae;
    }

    const auto counts = workCounts(calculationDay, targetDay);
    const auto stones = buildStones();
    const auto occultae = buildHiddenDrops(counts, stones);

    int discrepantiae = 0;
    for (int back = 1; back <= 7; ++back) {
        bool legacyReiecit = false;
        try {
            static_cast<void>(legacyPrior(visibiles, 1, back));
        } catch (const BaseValidationError&) {
            legacyReiecit = true;
        }
        if (!legacyReiecit) {
            std::cerr
                << "DEFECTUS_CICATRICIS_PRIOR back=" << back
                << ": helper legacy iam historiam occultam intelligit\n";
            ++defectusStructurae;
            continue;
        }

        try {
            const auto report = manager.executePrior(
                calculationDay, targetDay, visibiles, 1, back);
            const Integer expectatus = occultae[static_cast<std::size_t>(back - 1)];
            if (report.output != expectatus) {
                std::cerr
                    << "DISCREPANTIA PRIOR_OCCULTUS back=" << back
                    << ": expectatus=" << decimal(expectatus)
                    << " actualis=" << decimal(report.output)
                    << "\n";
                ++discrepantiae;
            } else {
                std::cout
                    << "CONCORDANTIA PRIOR_OCCULTUS back=" << back
                    << ": valor=" << decimal(report.output)
                    << "\n";
            }
        } catch (const BaseValidationError& error) {
            std::cerr
                << "DISCREPANTIA PRIOR_OCCULTUS back=" << back
                << ": expectatus="
                << decimal(occultae[static_cast<std::size_t>(back - 1)])
                << " actualis=NON_RESOLUTUS"
                << " causa=" << error.what()
                << "\n";
            ++discrepantiae;
        }
    }

    if (defectusStructurae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_06_INOPINATE_DEFECIT: "
            << defectusStructurae
            << " defectus structurae inventi sunt\n";
        return 2;
    }

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_06_TRANSIIT\n";
        return 0;
    }

    if (discrepantiae != 7) {
        std::cerr
            << "REGRESSIO_DISCOVERY_06_INOPINATE_DEFECIT: "
            << discrepantiae
            << " discrepantiae inventae sunt, sed aut septem ante patch aut nullae post patch exspectabantur\n";
        return 2;
    }

    std::cerr
        << "REGRESSIO_DISCOVERY_06_DEFECIT: "
        << discrepantiae
        << " petitiones historiae occultae a helper legacy non resolutae sunt\n";
    return 1;
}
