#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

#include <iostream>
#include <string>
#include <vector>

namespace {

struct CasusRemainder {
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
    using pastafari::reference::SAVE;

    const std::vector<CasusRemainder> casus{
        {"M", M_OLD},
        {"2M", 2 * M_OLD},
        {"3M", 3 * M_OLD},
        {"M+1", M_OLD + 1}
    };

    BaseMonsterManager manager;
    int discrepantiae = 0;

    for (const auto& c : casus) {
        const auto report = manager.executeLegacyRemainder(c.input);
        const Integer expectatus = SAVE(c.input);
        if (report.output != expectatus) {
            ++discrepantiae;
            std::cerr
                << "DISCREPANTIA oldRemainder " << c.nomen
                << ": expectatus=" << decimal(expectatus)
                << " actualis=" << decimal(report.output)
                << " status=" << report.status
                << "\n";
        } else {
            std::cout
                << "CONCORDANTIA oldRemainder " << c.nomen
                << ": valor=" << decimal(report.output)
                << "\n";
        }
    }

    if (discrepantiae != 0) {
        std::cerr
            << "REGRESSIO_DISCOVERY_01_DEFECIT: "
            << discrepantiae
            << " discrepantiae normativae inventae sunt\n";
        return 1;
    }

    std::cout << "REGRESSIO_DISCOVERY_01_TRANSIIT\n";
    return 0;
}
