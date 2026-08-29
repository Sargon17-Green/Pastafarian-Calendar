#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <string>
#include <vector>

namespace {

struct CasusPatch {
    std::string nomen;
    pastafari::Integer input;
};

std::string decimal(const pastafari::Integer& x) {
    return x.convert_to<std::string>();
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::Integer;
    using pastafari::M_OLD;
    using pastafari::oldRemainder;
    using pastafari::savePatch;
    using pastafari::reference::SAVE;

    const std::vector<CasusPatch> casus{
        {"1", Integer{1}},
        {"M-1", M_OLD - 1},
        {"M", M_OLD},
        {"M+1", M_OLD + 1},
        {"2M", 2 * M_OLD},
        {"3M", 3 * M_OLD}
    };

    BaseMonsterManager manager;
    int defectus = 0;

    if (oldRemainder(M_OLD) != 0 || oldRemainder(2 * M_OLD) != 0 || oldRemainder(3 * M_OLD) != 0) {
        std::cerr << "CICATRIX_LEGACY_DELETA: oldRemainder non iam vitium historicum servat\n";
        ++defectus;
    }

    for (const auto& c : casus) {
        const Integer expectatus = SAVE(c.input);
        const Integer directus = savePatch(c.input);
        const auto report = manager.executeLegacyRemainder(c.input);

        if (directus != expectatus) {
            std::cerr
                << "DISCREPANTIA savePatch " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(directus)
                << "\n";
            ++defectus;
        }

        if (report.output != expectatus || !report.patch01Applied) {
            std::cerr
                << "DISCREPANTIA viae productionis " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(report.output)
                << " status=" << report.status
                << "\n";
            ++defectus;
        }

        if (report.legacyOutputBeforePatch != oldRemainder(c.input)) {
            std::cerr
                << "DISCREPANTIA cicatricis " << c.nomen
                << ": valor legacy ante patch non servatus est\n";
            ++defectus;
        }
    }

    if (defectus != 0) {
        std::cerr
            << "REGRESSIO_PATCH_01_DEFECIT: "
            << defectus
            << " defectus inventi sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_PATCH_01_TRANSIIT\n";
    return 0;
}
