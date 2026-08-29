#include "pastafari/monster.hpp"
#include "reference/normative_reference.hpp"

#include <array>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

using pastafari::BaseMonsterManager;
using pastafari::Integer;
using pastafari::LegacyYearAnchor;
using pastafari::VirtualLegacyList;
using pastafari::reference::BoundedCompositionFamily;
using pastafari::reference::NormativeOracle;
using pastafari::reference::SauceResult;
using pastafari::reference::Year;

static void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

template <typename Function>
static void requireThrows(Function&& function, const std::string& message) {
    bool threw = false;
    try {
        function();
    } catch (const std::exception&) {
        threw = true;
    }
    require(threw, message);
}

static void proveVirtualListAgainstConcreteLegacyOnSmallSpaces() {
    int comparedFamilies = 0;
    int comparedItems = 0;
    for (int monthCount = 1; monthCount <= 5; ++monthCount) {
        const int minTotal = monthCount * pastafari::LEGACY_MONTH_LENGTH_MIN;
        const int maxTotal = minTotal + 12;
        for (int yearLength = minTotal; yearLength <= maxTotal; ++yearLength) {
            const auto concrete = pastafari::legacyMaterializeAllMonthLengthWays(
                yearLength,
                monthCount);
            VirtualLegacyList virtualList(yearLength, monthCount);
            BoundedCompositionFamily normativeFamily(
                yearLength,
                monthCount,
                pastafari::reference::MIN_MONTH_DAYS,
                pastafari::reference::MAX_MONTH_DAYS);
            require(virtualList.yearLength() == yearLength,
                    "VirtualLegacyList longitudinem anni servare debet");
            require(virtualList.monthCount() == monthCount,
                    "VirtualLegacyList numerum mensium servare debet");
            require(virtualList.count() == Integer{concrete.size()},
                    "count DP VirtualLegacyList a lista concreta legacy differt");
            require(virtualList.count() == normativeFamily.count(),
                    "count DP VirtualLegacyList ab oracle C++ differt");
            for (std::size_t index = 0; index < concrete.size(); ++index) {
                const Integer rank1{index + 1};
                const auto item = virtualList.itemAt1(rank1);
                require(item == concrete[index],
                        "itemAt1 VirtualLegacyList ordinem concretum legacy non servat");
                require(item == normativeFamily.unrank1(rank1),
                        "itemAt1 VirtualLegacyList ab unrank normativo C++ differt");
                ++comparedItems;
            }
            requireThrows(
                [&]() { (void)virtualList.itemAt1(Integer{0}); },
                "itemAt1 VirtualLegacyList rank zero recusare debet");
            requireThrows(
                [&]() { (void)virtualList.itemAt1(virtualList.count() + 1); },
                "itemAt1 VirtualLegacyList rank ultra count recusare debet");
            ++comparedFamilies;
        }
    }
    require(comparedFamilies == 65,
            "numerus familiarum parvarum force-brute PATCH 23 mutatus est");
    require(comparedItems > 0,
            "probatio force-brute PATCH 23 membra comparare debet");
    std::cout << "SMALL_VIRTUAL_FAMILIES=" << comparedFamilies
              << " SMALL_VIRTUAL_ITEMS=" << comparedItems << "\n";
}

static void proveHugeVirtualListWithoutMaterialization() {
    NormativeOracle oracle;
    BaseMonsterManager manager;
    manager.clearLegacyYearNumberCacheDiagnostic();

    const std::array<Integer, 3> calculationGateIndices{
        Integer{0}, Integer{1}, Integer{2}
    };
    int hugeCases = 0;

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
        const LegacyYearAnchor anchor{
            year5000.number,
            yearFirstDay,
            year5000.closeGateDay
        };

        BoundedCompositionFamily normativeFamily(
            yearLength,
            monthCount,
            pastafari::reference::MIN_MONTH_DAYS,
            pastafari::reference::MAX_MONTH_DAYS);
        const Integer normativeCount = normativeFamily.count();
        VirtualLegacyList directVirtual(yearLength, monthCount);
        require(directVirtual.count() == normativeCount,
                "count directus VirtualLegacyList ab oracle C++ differt");

        const Integer firstRank{1};
        const Integer middleRank = (normativeCount + 1) / 2;
        const Integer lastRank = normativeCount;
        require(directVirtual.itemAt1(firstRank) == normativeFamily.unrank1(firstRank),
                "primus itemAt1 familiae enormis ab oracle differt");
        require(directVirtual.itemAt1(middleRank) == normativeFamily.unrank1(middleRank),
                "medius itemAt1 familiae enormis ab oracle differt");
        require(directVirtual.itemAt1(lastRank) == normativeFamily.unrank1(lastRank),
                "ultimus itemAt1 familiae enormis ab oracle differt");

        const auto report = manager.executeDiscovery23MonthLengthMaterialization(
            anchor,
            yearFirstDay,
            calculationDay,
            calculationGateIndex,
            cutletCount,
            monthCount);
        require(report.ready && report.patch23Applied,
                "PATCH 23 materializationem mensium virtualem paratam reddere debet");
        require(report.handler == "Patch23MonthLengthMaterializationHandler",
                "handler PATCH 23 expectatus est");
        require(report.patch23LegacyExecuted,
                "PATCH 23 legacy materializationem ut cicatricem currere debet");
        require(report.legacyConcreteListContractReached,
                "contractus API legacy listae omnes vias servandus est");
        require(report.blockedBeforeAllocation,
                "familia concreta enormis ante allocationem sistere debet");
        require(!report.legacyConcreteEnumerationEntered &&
                !report.legacyConcreteMaterializationCompleted &&
                report.materializedItemCount == 0,
                "PATCH 23 materializationem concretam familiae enormis facere non debet");
        require(report.patch23VirtualBackendUsed,
                "PATCH 23 VirtualLegacyList backend activum habere debet");
        require(report.virtualCount == normativeCount,
                "count semanticus VirtualLegacyList ab oracle C++ differt");
        require(report.virtualProbeRank == middleRank,
                "probe rank PATCH 23 medium familiae exactum esse debet");
        require(report.virtualProbeItem == normativeFamily.unrank1(middleRank),
                "probe item PATCH 23 ab oracle C++ differt");

        const auto diagnostic =
            manager.executeUnpatchedDiscovery23MonthLengthMaterializationDiagnostic(
                anchor,
                yearFirstDay,
                calculationDay,
                calculationGateIndex,
                cutletCount,
                monthCount);
        require(diagnostic.ready && !diagnostic.patch23Applied,
                "diagnosticum DISCOVERY 23 sine PATCH 23 manere debet");
        require(!diagnostic.patch23VirtualBackendUsed,
                "diagnosticum DISCOVERY 23 backend virtualem videre non debet");
        require(diagnostic.exactFamilyCount == report.exactFamilyCount,
                "cicatrix DISCOVERY 23 count eundem servare debet");

        ++hugeCases;
        std::cout << "PATCH23_WITNESS_GATE=" << calculationGateIndex
                  << " YEAR_LENGTH=" << yearLength
                  << " MONTH_COUNT=" << monthCount
                  << " COUNT=" << normativeCount
                  << "\n";
    }

    require(hugeCases == 3,
            "tres witness familiae enormis PATCH 23 requiruntur");
}

int main() {
    try {
        proveVirtualListAgainstConcreteLegacyOnSmallSpaces();
        proveHugeVirtualListWithoutMaterialization();
        std::cout << "REGRESSIO_PATCH_23_TRANSIIT\n";
        std::cout << "VIRTUAL_LEGACY_LIST=PASS\n";
        std::cout << "EXACT_DP_COUNT=PASS\n";
        std::cout << "EXACT_LEXICOGRAPHIC_ITEM_AT_1=PASS\n";
        std::cout << "OOM_ACTUALIS=NO\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "REGRESSIO_PATCH_23_ERROR: " << error.what() << "\n";
        return 1;
    }
}
