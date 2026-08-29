#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyStructureSelectorToken;
using pastafari::LegacyYearAnchor;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static bool sameOrder(const pastafari::PermutationOrder& a,
                      const std::array<int, 6>& b) {
    for (std::size_t i = 0; i < 6; ++i) {
        if (a[i] != b[i]) return false;
    }
    return true;
}

static bool sameToken(const LegacyStructureSelectorToken& token,
                      const SauceResult& sauce) {
    return token.bowl2 == sauce.bowls[1] &&
           sameOrder(token.orderAt46Latch, sauce.orderAtDrop46);
}

static bool sameLegacySauce(const pastafari::Patch11LatchedOrderSauceResult& actual,
                            const SauceResult& expected) {
    for (std::size_t i = 0; i < 6; ++i) {
        if (actual.finalBowls[i] != expected.bowls[i]) return false;
    }
    return sameOrder(actual.orderAt46Latch, expected.orderAtDrop46);
}

static std::string orderText(const pastafari::PermutationOrder& order) {
    std::string out = "[";
    for (std::size_t i = 0; i < order.size(); ++i) {
        if (i != 0) out += ",";
        out += std::to_string(order[i]);
    }
    return out + "]";
}

int main() {
    try {
        NormativeOracle oracle;
        const Integer calculationDay = pastafari::reference::FOUNDATION_DAY;
        const Year year5000 = oracle.year5000(calculationDay);
        const Integer yearFirstDay = year5000.openGateDay + 1;
        const LegacyYearAnchor anchor{
            year5000.number,
            yearFirstDay,
            year5000.closeGateDay
        };
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();

        const SauceResult normativeStructure = pastafari::reference::sauce(
            calculationDay,
            yearFirstDay);

        const auto control = manager.executeDiscovery20StructureSauce(
            anchor,
            yearFirstDay,
            calculationDay);
        require(control.ready, "casus control structure sauce paratus esse debet");
        require(control.selectorConsumedLegacySauce, "selector in DISCOVERY 20 sauce legacy consumere debet");
        require(control.yearFirstDay == yearFirstDay, "primus dies anni controlis differt");
        require(sameLegacySauce(control.legacyStructureSauce, normativeStructure), "oldStructureSauce control cum year.firstDay congruere debet");
        require(sameToken(control.selectorToken, normativeStructure), "selector control sauce normativam videre debet");

        const std::array<Integer, 3> targets{
            yearFirstDay + 1,
            yearFirstDay + 365,
            year5000.closeGateDay
        };

        int discrepancies = 0;
        for (const Integer& originalTargetDay : targets) {
            require(originalTargetDay != yearFirstDay, "witness target a year.firstDay differre debet");
            require(originalTargetDay <= year5000.closeGateDay, "witness target intra annum esse debet");

            const auto report = manager.executeDiscovery20StructureSauce(
                anchor,
                originalTargetDay,
                calculationDay);
            require(report.ready, "structure sauce report paratus esse debet");
            require(report.handler == "Discovery20StructureSauceHandler", "handler DISCOVERY 20 expectatus est");
            require(report.selectorConsumedLegacySauce, "selector oldStructureSauce consumere debet");
            require(report.yearFirstDay == yearFirstDay, "primus dies anni resoluti mutatus est");
            require(report.resolvedYear.number == year5000.number, "annus resolutus 5000 manere debet");

            const SauceResult legacyExpected = pastafari::reference::sauce(
                calculationDay,
                originalTargetDay);
            require(sameLegacySauce(report.legacyStructureSauce, legacyExpected), "oldStructureSauce target originalem exacte sequi debet");
            require(report.selectorToken.bowl2 == report.legacyStructureSauce.finalBowls[1], "selector bowl2 ex sauce legacy venire debet");
            require(report.selectorToken.orderAt46Latch == report.legacyStructureSauce.orderAt46Latch, "selector order ex sauce legacy venire debet");

            const bool divergent = !sameToken(report.selectorToken, normativeStructure);
            if (divergent) {
                ++discrepancies;
                std::cout << "DISCREPANTIA_STRUCTURE_SAUCE"
                          << " originalTargetDay=" << originalTargetDay
                          << " yearFirstDay=" << yearFirstDay
                          << " bowl2_normativus=" << normativeStructure.bowls[1]
                          << " bowl2_legacy=" << report.selectorToken.bowl2
                          << " order_legacy=" << orderText(report.selectorToken.orderAt46Latch)
                          << "\n";
            }
        }

        if (discrepancies == 0) {
            std::cout << "REGRESSIO_DISCOVERY_20_TRANSIIT\n";
            return 0;
        }
        if (discrepancies == 3) {
            std::cerr << "REGRESSIO_DISCOVERY_20_DEFECIT: 3 target originalia sauce structuralem veterem ad selector transmiserunt loco sauce(cDay,year.firstDay)\n";
            return 1;
        }
        std::cerr << "REGRESSIO_DISCOVERY_20_INEXPECTATA: discrepantiae=" << discrepancies << "\n";
        return 2;
    } catch (const std::exception& e) {
        std::cerr << "REGRESSIO_DISCOVERY_20_ERROR: " << e.what() << "\n";
        return 3;
    }
}
