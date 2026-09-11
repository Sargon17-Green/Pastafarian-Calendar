#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"
#include "stage_55_fast_reference.hpp"

#include <chrono>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
using pastafari::reference::Big;
using pastafari::reference::CalendarDate;
using pastafari::reference::NormativeOracle;
using pastafari::reference::Year;
using pastafari::reference::YearStructure;
using Clock = std::chrono::steady_clock;

constexpr long long BASE_CALCULATION_DAY = -15048173LL;
constexpr long long FOUNDATION_DAY = -15055671LL;

long long calculationDayForShard(int shard) {
    if (shard == 0 || shard == 44 || shard == 83) return FOUNDATION_DAY;
    return BASE_CALCULATION_DAY + static_cast<long long>(shard - 50) * 137LL;
}

long long targetOffsetForPair(int shard, int localIndex) {
    if (shard == 83) return 101LL + static_cast<long long>(localIndex);
    if (shard == 44) return 201LL + static_cast<long long>(localIndex);
    return static_cast<long long>((localIndex * 73 + shard * 29) % 201) - 100LL;
}

struct CachedYear {
    Year year;
    YearStructure structure;
};

YearStructure buildFastStructure(NormativeOracle& oracle,
                                 const Big& calculationDay,
                                 const Year& year) {
    const Big firstDay = year.openGateDay + 1;
    const pastafari::reference::SauceResult sauce =
        pastafari::reference::sauce(calculationDay, firstDay);

    const int cutletCount = oracle.chooseCutletCount(sauce, year);
    const auto cutletPartition =
        oracle.chooseCutletPartition(calculationDay, sauce, year, cutletCount);
    const auto cutletNames = oracle.chooseCutletNameIndices(sauce, cutletCount);
    const auto cutlets = oracle.materializeCutlets(year, cutletPartition, cutletNames);

    const int monthCount = oracle.chooseMonthCount(sauce, year);
    const auto monthLengths = oracle.chooseMonthLengths(sauce, year, monthCount);
    const auto monthNames = oracle.chooseMonthNameIndices(sauce, monthCount);

    pastafari::stage55audit::TexturaCelerReference family(monthLengths);
    const Big totalWeavings = family.numerusOmnium();
    const Big rank = pastafari::reference::chooseRank(
        pastafari::reference::askBowl(
            sauce, 4, pastafari::reference::SEAL_MONTH_WEAVING),
        totalWeavings);
    const auto monthWeaving = family.aperiGradum(rank);

    return YearStructure{
        cutletCount,
        cutletPartition,
        cutletNames,
        cutlets,
        monthCount,
        monthLengths,
        monthWeaving,
        monthNames
    };
}

const CachedYear& yearForTarget(NormativeOracle& oracle,
                                const Big& calculationDay,
                                const Big& targetDay,
                                std::vector<CachedYear>& cache) {
    for (const auto& cached : cache) {
        if (cached.year.openGateDay < targetDay &&
            targetDay <= cached.year.closeGateDay) {
            return cached;
        }
    }
    const Year year = oracle.findTargetYear(calculationDay, targetDay);
    cache.push_back(CachedYear{
        year, buildFastStructure(oracle, calculationDay, year)
    });
    return cache.back();
}

CalendarDate project(const Big& targetDay, const CachedYear& cached) {
    const Year& year = cached.year;
    const YearStructure& structure = cached.structure;

    int cutletId = -1;
    for (std::size_t i = 0; i < structure.cutlets.size(); ++i) {
        if (structure.cutlets[i].firstDay <= targetDay &&
            targetDay <= structure.cutlets[i].lastDay) {
            cutletId = static_cast<int>(i);
            break;
        }
    }
    if (cutletId < 0) throw std::runtime_error("canonical cutlet not found");

    const Big dayInCutlet =
        targetDay - structure.cutlets[static_cast<std::size_t>(cutletId)].firstDay + 1;
    const Big offsetBig = targetDay - (year.openGateDay + 1);
    if (offsetBig < 0 || offsetBig >= Big{structure.monthWeaving.size()}) {
        throw std::runtime_error("canonical month offset out of range");
    }
    const std::size_t offset = offsetBig.convert_to<std::size_t>();
    const int monthId = structure.monthWeaving.at(offset);
    Big dayInMonth = 0;
    for (std::size_t p = 0; p <= offset; ++p) {
        if (structure.monthWeaving[p] == monthId) ++dayInMonth;
    }

    return CalendarDate{
        year.number,
        std::string(pastafari::cutletSourceName(
            static_cast<std::size_t>(
                structure.cutletNameIndices.at(static_cast<std::size_t>(cutletId))))),
        dayInCutlet,
        std::string(pastafari::monthSourceName(
            static_cast<std::size_t>(
                structure.monthNameIndices.at(static_cast<std::size_t>(monthId - 1))))),
        dayInMonth
    };
}

void writeResult(std::ostream& out,
                 int globalIndex,
                 const Big& c,
                 const Big& t,
                 const CalendarDate& d) {
    out << globalIndex << '\t'
        << c << '\t'
        << t << '\t'
        << d.yearNumber << '\t'
        << std::quoted(d.cutletName) << '\t'
        << d.dayInCutlet << '\t'
        << std::quoted(d.monthName) << '\t'
        << d.dayInMonth << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc != 5) {
            throw std::runtime_error(
                "usus: canonical_saved_sum_vector_runner shard count result.tsv timing.tsv");
        }
        const int shard = std::stoi(argv[1]);
        const int count = std::stoi(argv[2]);
        if (shard < 0 || shard >= 100 || count <= 0 || count > 1000) {
            throw std::runtime_error("shard/count extra fines comparationis sunt");
        }

        std::ofstream results(argv[3], std::ios::trunc);
        std::ofstream timing(argv[4], std::ios::trunc);
        if (!results || !timing) {
            throw std::runtime_error("artifactum canonicae comparationis aperiri non potest");
        }

        const Big c{calculationDayForShard(shard)};
        NormativeOracle oracle(false); // false = canonical saved-sum, never the raw-sum mutant.
        std::vector<CachedYear> cache;

        const auto wholeStart = Clock::now();
        long long firstMs = -1;
        long long restMs = 0;

        for (int i = 0; i < count; ++i) {
            const Big t = c + targetOffsetForPair(shard, i);
            const auto begin = Clock::now();
            const CachedYear& cached = yearForTarget(oracle, c, t, cache);
            const CalendarDate d = project(t, cached);
            const auto end = Clock::now();
            const auto elapsed =
                std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();
            if (i == 0) firstMs = elapsed;
            else restMs += elapsed;
            writeResult(results, shard * count + i, c, t, d);
        }

        const auto wholeEnd = Clock::now();
        const auto totalMs =
            std::chrono::duration_cast<std::chrono::milliseconds>(wholeEnd - wholeStart).count();
        timing << "shard=" << shard << '\n'
               << "pairs=" << count << '\n'
               << "first_ms=" << firstMs << '\n'
               << "rest_ms=" << restMs << '\n'
               << "total_ms=" << totalMs << '\n'
               << "semantic_oracle=CANONICAL_SAVED_SUM\n";
        std::cout << "CANONICAL_SAVED_SUM_VECTOR=PASS shard=" << shard
                  << " pairs=" << count
                  << " years_cached=" << cache.size()
                  << " total_ms=" << totalMs << "\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "CANONICAL_SAVED_SUM_VECTOR=FAIL " << error.what() << '\n';
        return 1;
    }
}
