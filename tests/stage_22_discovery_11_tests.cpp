#include "pastafari/monster.hpp"
#include "tests/reference/normative_reference.hpp"

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

int mismatchCount(const pastafari::PermutationOrder& a,
                  const pastafari::PermutationOrder& b) {
    int n = 0;
    for (std::size_t i = 0; i < a.size(); ++i) {
        if (a[i] != b[i]) {
            ++n;
        }
    }
    return n;
}

} // namespace

int main() {
    using pastafari::BaseMonsterManager;
    using pastafari::FOUNDATION_DAY_OLD;
    using pastafari::PermutationOrder;
    namespace ref = pastafari::reference;

    const auto counts = ref::workCounts(ref::FOUNDATION_DAY, ref::FOUNDATION_DAY);
    const auto stones = ref::buildStones();
    const auto hidden = ref::buildHiddenDrops(counts, stones);
    const auto visible = ref::buildVisibleDrops(counts, stones, hidden);
    const PermutationOrder expectedOrder46 = ref::bowlOrderFromDrop(visible[46]);

    BaseMonsterManager manager;
    const auto report = manager.executeOverwritableOrderMemorySauce(
        FOUNDATION_DAY_OLD, FOUNDATION_DAY_OLD);

    int defectusViae = 0;
    if (report.orderWriteCount != 58) {
        std::cerr << "DEFECTUS_SCRIPTURARUM_ORDINIS: expectatus=58 actualis="
                  << report.orderWriteCount << '\n';
        ++defectusViae;
    }
    if (report.finalOrderSource != "post-commotio 12") {
        std::cerr << "DEFECTUS_FONTIS_ORDINIS_FINALIS: actualis="
                  << report.finalOrderSource << '\n';
        ++defectusViae;
    }
    if (report.queryOrder != report.finalPostStirOrder) {
        std::cerr << "DEFECTUS_MEMORIAE_ULTIMAE: query=" << orderText(report.queryOrder)
                  << " post12=" << orderText(report.finalPostStirOrder) << '\n';
        ++defectusViae;
    }
    if (report.orderAtDrop46Diagnostic != expectedOrder46) {
        std::cerr << "DEFECTUS_ORDINIS_GUTTAE_46: expectatus=" << orderText(expectedOrder46)
                  << " actualis=" << orderText(report.orderAtDrop46Diagnostic) << '\n';
        ++defectusViae;
    }
    if (report.status != "OVERWRITTEN_QUERY_ORDER_EXPOSED" ||
        report.handler != "Discovery11OverwrittenOrderHandler" ||
        report.branchCount < 4) {
        std::cerr << "DEFECTUS_VIAE_DISCOVERY_11: status=" << report.status
                  << " handler=" << report.handler
                  << " rami=" << report.branchCount << '\n';
        ++defectusViae;
    }

    if (defectusViae != 0) {
        std::cerr << "REGRESSIO_DISCOVERY_11_INOPINATE_DEFECIT: "
                  << defectusViae << " defectus viae inventi sunt\n";
        return 2;
    }

    const int discrepantiae = mismatchCount(report.queryOrder, expectedOrder46);
    std::cout << "ORDO_GUTTAE_46=" << orderText(expectedOrder46) << '\n';
    std::cout << "ORDO_QUERY_LEGACY=" << orderText(report.queryOrder) << '\n';
    std::cout << "ORDO_POST_COMMOTIONIS_12=" << orderText(report.finalPostStirOrder) << '\n';
    std::cout << "SCRIPTURAE_MEMORIAE=" << report.orderWriteCount << '\n';
    std::cout << "FONS_FINALIS=" << report.finalOrderSource << '\n';

    if (discrepantiae == 0) {
        std::cout << "REGRESSIO_DISCOVERY_11_TRANSIIT\n";
        return 0;
    }

    std::cerr << "REGRESSIO_DISCOVERY_11_DEFECIT: "
              << discrepantiae
              << " positiones query ordinis post superscriptionem a gutta 46 discrepant\n";
    return 1;
}
