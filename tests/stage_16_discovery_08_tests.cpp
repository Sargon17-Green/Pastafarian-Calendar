#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <string>
#include <vector>

namespace {

std::string ordoTextus(const pastafari::PermutationOrder& order) {
    std::string textus = "[";
    for (std::size_t i = 0; i < order.size(); ++i) {
        if (i != 0) {
            textus += ",";
        }
        textus += std::to_string(order[i]);
    }
    textus += "]";
    return textus;
}

pastafari::PermutationOrder inOrdinem(const std::vector<int>& values) {
    if (values.size() != 6) {
        throw pastafari::BaseValidationError("sex elementa ad ordinem permutationis requiruntur");
    }
    pastafari::PermutationOrder out{};
    for (std::size_t i = 0; i < out.size(); ++i) {
        out[i] = values[i];
    }
    return out;
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::BaseValidationError;
    using pastafari::PermutationOrder;
    using pastafari::oldPermutationUnrank0;
    using pastafari::reference::permutationUnrank1;

    const PermutationOrder primaLegacy = oldPermutationUnrank0(0);
    const PermutationOrder ultimaLegacy = oldPermutationUnrank0(719);
    if (primaLegacy != PermutationOrder{{1, 2, 3, 4, 5, 6}} ||
        ultimaLegacy != PermutationOrder{{6, 5, 4, 3, 2, 1}}) {
        std::cerr << "DEFECTUS_LEGACY_PERMUTATIONIS: unrank0 terminos zero-based non servat\n";
        return 2;
    }

    bool septingentiVigintiReiectus = false;
    try {
        static_cast<void>(oldPermutationUnrank0(720));
    } catch (const BaseValidationError&) {
        septingentiVigintiReiectus = true;
    }
    if (!septingentiVigintiReiectus) {
        std::cerr << "DEFECTUS_LEGACY_PERMUTATIONIS: rank0=720 reiciendus erat\n";
        return 2;
    }

    const std::array<int, 5> ranks{{1, 2, 3, 719, 720}};
    BaseMonsterManager manager;
    int discrepantiae = 0;

    for (const int rank1 : ranks) {
        const PermutationOrder expectatus = inOrdinem(
            permutationUnrank1(rank1, {1, 2, 3, 4, 5, 6}));
        const auto report = manager.executePermutationOrder(rank1);

        if (!report.found) {
            std::cerr
                << "DISCREPANTIA PERMUTATIONIS rank=" << rank1
                << ": expectatus=" << ordoTextus(expectatus)
                << " actualis=ABSENS\n";
            ++discrepantiae;
            continue;
        }

        if (report.output != expectatus) {
            std::cerr
                << "DISCREPANTIA PERMUTATIONIS rank=" << rank1
                << ": expectatus=" << ordoTextus(expectatus)
                << " actualis=" << ordoTextus(report.output)
                << "\n";
            ++discrepantiae;
        } else {
            std::cout
                << "CONCORDANTIA PERMUTATIONIS rank=" << rank1
                << ": valor=" << ordoTextus(report.output)
                << "\n";
        }
    }

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_08_TRANSIIT\n";
        return 0;
    }

    if (discrepantiae == static_cast<int>(ranks.size())) {
        std::cerr
            << "REGRESSIO_DISCOVERY_08_DEFECIT: "
            << discrepantiae
            << " discrepantiae normativae ex rank one-based directo inventae sunt\n";
        return 1;
    }

    std::cerr
        << "REGRESSIO_DISCOVERY_08_INOPINATE_DEFECIT: "
        << discrepantiae
        << " discrepantiae inventae sunt\n";
    return 2;
}
