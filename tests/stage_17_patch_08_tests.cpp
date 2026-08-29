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

struct CasusDrop {
    const char* nomen;
    pastafari::Integer drop;
};

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::BaseValidationError;
    using pastafari::Integer;
    using pastafari::PermutationOrder;
    using pastafari::oldPermutationUnrank0;
    using pastafari::regularMod;
    using pastafari::reference::permutationUnrank1;

    int defectus = 0;

    if (oldPermutationUnrank0(0) != PermutationOrder{{1, 2, 3, 4, 5, 6}} ||
        oldPermutationUnrank0(719) != PermutationOrder{{6, 5, 4, 3, 2, 1}}) {
        std::cerr << "CICATRIX_LEGACY_DELETA: oldPermutationUnrank0 terminos suos mutavit\n";
        ++defectus;
    }
    bool rank720Reiectus = false;
    try {
        static_cast<void>(oldPermutationUnrank0(720));
    } catch (const BaseValidationError&) {
        rank720Reiectus = true;
    }
    if (!rank720Reiectus) {
        std::cerr << "CICATRIX_LEGACY_DELETA: oldPermutationUnrank0(720) non reiecit\n";
        ++defectus;
    }

    BaseMonsterManager manager;
    const auto diagnosticusPrimus = manager.executeUnpatchedPermutationDiagnostic(1);
    if (!diagnosticusPrimus.found || diagnosticusPrimus.output != oldPermutationUnrank0(1) ||
        diagnosticusPrimus.patch08Applied) {
        std::cerr << "DEFECTUS_DIAGNOSTICUS: via legacy rank=1 non servata est\n";
        ++defectus;
    }
    const auto diagnosticusUltimus = manager.executeUnpatchedPermutationDiagnostic(720);
    if (diagnosticusUltimus.found || diagnosticusUltimus.patch08Applied) {
        std::cerr << "DEFECTUS_DIAGNOSTICUS: via legacy rank=720 non servata est\n";
        ++defectus;
    }

    const std::array<CasusDrop, 8> casus{{
        {"DROP_1", Integer{1}},
        {"DROP_2", Integer{2}},
        {"DROP_719", Integer{719}},
        {"DROP_720", Integer{720}},
        {"DROP_721", Integer{721}},
        {"DROP_0", Integer{0}},
        {"DROP_NEG_1", Integer{-1}},
        {"DROP_1441", Integer{1441}},
    }};

    for (const auto& c : casus) {
        const Integer oneBasedInteger = regularMod(c.drop - 1, Integer{720}) + 1;
        const int oneBased = oneBasedInteger.convert_to<int>();
        const int legacyRank0 = oneBased - 1;
        const PermutationOrder expectatus = inOrdinem(
            permutationUnrank1(oneBased, {1, 2, 3, 4, 5, 6}));
        const auto report = manager.executePermutationFromDrop(c.drop);

        if (!report.found || !report.patch08Applied || report.output != expectatus ||
            report.patchedOneBasedRank != oneBased ||
            report.patchedLegacyRank0 != legacyRank0 ||
            report.dropInput != c.drop) {
            std::cerr
                << "DISCREPANTIA PATCH_08 " << c.nomen
                << ": oneBased=" << oneBased
                << " legacyRank0=" << legacyRank0
                << " expectatus=" << ordoTextus(expectatus)
                << " actualis=" << (report.found ? ordoTextus(report.output) : "ABSENS")
                << "\n";
            ++defectus;
        }

        if (report.legacyRank0Input != oneBased) {
            std::cerr
                << "DEFECTUS_CICATRICIS " << c.nomen
                << ": caller legacy non accepit oneBased directe ut rank0\n";
            ++defectus;
        }
        if (oneBased == 720) {
            if (report.legacyFoundBeforePatch) {
                std::cerr << "DEFECTUS_CICATRICIS " << c.nomen
                          << ": rank0 legacy 720 non debuit inveniri\n";
                ++defectus;
            }
        } else if (!report.legacyFoundBeforePatch ||
                   report.legacyOutputBeforePatch != oldPermutationUnrank0(oneBased)) {
            std::cerr << "DEFECTUS_CICATRICIS " << c.nomen
                      << ": exitus legacy ante patch non servatus est\n";
            ++defectus;
        }
    }

    if (defectus != 0) {
        std::cerr << "REGRESSIO_PATCH_08_DEFECIT: " << defectus << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_08_TRANSIIT\n";
    return 0;
}
