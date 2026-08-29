#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::reference::BoundedCompositionFamily;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

static void proveConcreteLegacyListOnSmallFamily() {
    const auto ways = pastafari::legacyMaterializeAllMonthLengthWays(12, 2);
    const std::vector<std::vector<int>> expected{
        {4,8}, {5,7}, {6,6}, {7,5}, {8,4}
    };
    require(ways == expected,
            "API legacy listae concretae ordinem lexicographicum parvum non servat");
    require(pastafari::legacyMonthLengthConcreteFamilyCountProof(12, 2) == Integer{5},
            "probatio numeri familiae parvae a materializatione legacy differt");
}

int main() {
    try {
        proveConcreteLegacyListOnSmallFamily();

        NormativeOracle oracle;
        BaseMonsterManager manager;
        manager.clearLegacyYearNumberCacheDiagnostic();

        const std::array<Integer, 3> calculationGateIndices{
            Integer{0}, Integer{1}, Integer{2}
        };
        const Integer platformCapacity{
            std::numeric_limits<std::size_t>::max()};

        int enormousFamilies = 0;
        for (const Integer& calculationGateIndex : calculationGateIndices) {
            const Integer calculationDay = oracle.gateValueForTest(calculationGateIndex);
            const Year year5000 = oracle.year5000(calculationDay);
            const Integer yearFirstDay = year5000.openGateDay + 1;
            const int yearLength = (year5000.closeGateDay - year5000.openGateDay)
                .convert_to<int>();
            const SauceResult structureSauce = pastafari::reference::sauce(
                calculationDay,
                yearFirstDay);
            const int cutletCount = oracle.chooseCutletCount(structureSauce, year5000);
            const int monthCount = oracle.chooseMonthCount(structureSauce, year5000);
            BoundedCompositionFamily normativeFamily(
                yearLength,
                monthCount,
                pastafari::reference::MIN_MONTH_DAYS,
                pastafari::reference::MAX_MONTH_DAYS);
            const Integer normativeCount = normativeFamily.count();
            const LegacyYearAnchor anchor{
                year5000.number,
                yearFirstDay,
                year5000.closeGateDay
            };

            const auto report = manager.executeDiscovery23MonthLengthMaterialization(
                anchor,
                yearFirstDay,
                calculationDay,
                calculationGateIndex,
                cutletCount,
                monthCount);

            require(report.ready,
                    "DISCOVERY 23 paratus esse debet");
            require(report.handler == "Discovery23MonthLengthMaterializationHandler",
                    "handler DISCOVERY 23 expectatus est");
            require(report.patch22Prepared,
                    "DISCOVERY 23 PATCH 22 paratum servare debet");
            require(!report.patch23Applied,
                    "PATCH 23 in DISCOVERY 23 praemature adesse non debet");
            require(report.yearLength == yearLength && report.monthCount == monthCount,
                    "fines familiae mensium DISCOVERY 23 discrepare non debent");
            require(report.exactFamilyCount == normativeCount,
                    "probatio exacta familiae legacy ab oracle C++ differt");
            require(report.concreteListIndexCapacity == platformCapacity,
                    "capacitas concretae listae platformae discrepat");
            require(report.legacyConcreteListContractReached,
                    "API legacy omnes vias ut listam concretam exponere debet");
            require(report.exactFamilyCount > report.concreteListIndexCapacity,
                    "witness DISCOVERY 23 familiam ultra capacitatem concretam requirit");
            require(report.blockedBeforeAllocation,
                    "familia enormis ante allocationem actualem tuto sisti debet");
            require(!report.legacyConcreteEnumerationEntered,
                    "enumeratio concreta familiae enormis incipi non debet");
            require(!report.legacyConcreteMaterializationCompleted,
                    "materializatio concreta familiae enormis compleri non potest");
            require(report.materializedItemCount == 0,
                    "familia enormis nullum membrum materializatum relinquere debet");

            ++enormousFamilies;
            std::cout << "WITNESS_GATE=" << calculationGateIndex
                      << " YEAR_LENGTH=" << yearLength
                      << " MONTH_COUNT=" << monthCount
                      << " FAMILY_COUNT=" << report.exactFamilyCount << "\n";
        }

        require(enormousFamilies == 3,
                "tres witness familiae enormis DISCOVERY 23 requiruntur");

        std::cout << "LEGACY_SMALL_CONCRETE_LIST=PASS\n";
        std::cout << "ENORMOUS_FAMILIES=3\n";
        std::cout << "OOM_ACTUALIS=NO\n";
        std::cout << "VIRTUAL_LEGACY_LIST=NO\n";
        std::cout << "FAILURE=REGRESSIO_DISCOVERY_23_DEFECIT\n";
        return 1;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_23_ERROR: " << error.what() << "\n";
        return 2;
    }
}
