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

        int preservedEnormousLegacyFamilies = 0;
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
                    "PATCH 23 materializationem mensium paratam reddere debet");
            require(report.handler == "Patch23MonthLengthMaterializationHandler",
                    "handler PATCH 23 viae activae expectatus est");
            require(report.patch22Prepared,
                    "PATCH 23 PATCH 22 paratum servare debet");
            require(report.patch23Applied,
                    "PATCH 23 via activa applicari debet");
            require(report.patch23LegacyExecuted,
                    "cicatrix materializationis legacy ante PATCH 23 vere exsequi debet");
            require(report.patch23VirtualBackendUsed,
                    "PATCH 23 backend VirtualLegacyList uti debet");
            require(report.patch23CountMatchesLegacyProof,
                    "count DP PATCH 23 probationi exactae legacy congruere debet");
            require(report.yearLength == yearLength && report.monthCount == monthCount,
                    "fines familiae mensium PATCH 23 discrepare non debent");
            require(report.exactFamilyCount == normativeCount,
                    "probatio exacta familiae legacy ab oracle C++ differt");
            require(report.virtualCount == normativeCount,
                    "count VirtualLegacyList ab oracle C++ differt");
            require(report.virtualProbeItem == normativeFamily.unrank1(report.virtualProbeRank),
                    "itemAt1 VirtualLegacyList ab unrank normativo C++ differt");
            require(report.concreteListIndexCapacity == platformCapacity,
                    "capacitas concretae listae platformae discrepat");
            require(report.legacyConcreteListContractReached,
                    "API legacy omnes vias ut listam concretam exponere debet");
            require(report.exactFamilyCount > report.concreteListIndexCapacity,
                    "witness DISCOVERY 23 familiam ultra capacitatem concretam requirit");
            require(report.blockedBeforeAllocation,
                    "cicatrix familiae enormis ante allocationem actualem tuto sistere debet");
            require(!report.legacyConcreteEnumerationEntered,
                    "enumeratio concreta cicatricis enormis incipi non debet");
            require(!report.legacyConcreteMaterializationCompleted,
                    "materializatio concreta cicatricis enormis compleri non potest");
            require(report.materializedItemCount == 0,
                    "familia enormis nullum membrum materializatum relinquere debet");

            const auto diagnostic =
                manager.executeUnpatchedDiscovery23MonthLengthMaterializationDiagnostic(
                    anchor,
                    yearFirstDay,
                    calculationDay,
                    calculationGateIndex,
                    cutletCount,
                    monthCount);
            require(diagnostic.ready,
                    "diagnosticum DISCOVERY 23 paratum esse debet");
            require(diagnostic.handler == "Discovery23MonthLengthMaterializationHandler",
                    "diagnosticum handler DISCOVERY 23 servare debet");
            require(!diagnostic.patch23Applied,
                    "diagnosticum DISCOVERY 23 PATCH 23 applicare non debet");
            require(!diagnostic.patch23VirtualBackendUsed,
                    "diagnosticum DISCOVERY 23 VirtualLegacyList uti non debet");
            require(diagnostic.exactFamilyCount == report.exactFamilyCount,
                    "diagnosticum eundem numerum familiae legacy servare debet");
            require(diagnostic.blockedBeforeAllocation &&
                    !diagnostic.legacyConcreteEnumerationEntered &&
                    diagnostic.materializedItemCount == 0,
                    "diagnosticum cicatricem materializationis enormis servare debet");

            ++preservedEnormousLegacyFamilies;
            std::cout << "WITNESS_GATE=" << calculationGateIndex
                      << " YEAR_LENGTH=" << yearLength
                      << " MONTH_COUNT=" << monthCount
                      << " FAMILY_COUNT=" << report.exactFamilyCount
                      << " VIRTUAL_PROBE_RANK=" << report.virtualProbeRank
                      << "\n";
        }

        require(preservedEnormousLegacyFamilies == 3,
                "tres cicatrices familiae enormis DISCOVERY 23 post PATCH 23 servandae sunt");

        std::cout << "REGRESSIO_DISCOVERY_23_POST_PATCH_TRANSIIT\n";
        std::cout << "LEGACY_ENORMOUS_FAMILIES_PRESERVED=3\n";
        std::cout << "SEMANTIC_VIRTUAL_BACKEND=PASS\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_DISCOVERY_23_POST_PATCH_ERROR: " << error.what() << "\n";
        return 1;
    }
}
