#include "pastafari/monster.hpp"

#include <chrono>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {
using pastafari::Integer;
using pastafari::SpaghettiDateFive;
using Clock = std::chrono::steady_clock;

constexpr long long BASE_CALCULATION_DAY = -15048173LL;
constexpr long long FOUNDATION_DAY = -15055671LL;

long long calculationDayForShard(int shard) {
    // Centum contextus in matrice comparationis manent. Shard 0 diem
    // Fundationis fossiliter servat.
    //
    // PATCH 40 tribunal: vetus shard 83 calculationDay=-15043652 aperuit
    // rejectionem latam cui via baseline plus quam 10^9173 gradus singulos
    // postulat. Ille testis NON deletur: patch40_wide_funeral_probe.cpp eum
    // separatim exercet in candidato. Comparatio inter ramos autem debet
    // utrumque ramum physice perficere, ergo shard 83 alteram regionem
    // iam probatam accipit.
    if (shard == 0 || shard == 83) return FOUNDATION_DAY;
    return BASE_CALCULATION_DAY + static_cast<long long>(shard - 50) * 137LL;
}

long long targetOffsetForPair(int shard, int localIndex) {
    if (shard == 83) {
        // Centum paria nova et a shard 0 disiuncta: shard 0 tantum offsets
        // [-100,100] petit; hic [101,200] utitur. Ita 10 000 paria totius
        // matricis adhuc distincta sunt.
        return 101LL + static_cast<long long>(localIndex);
    }
    // 73 est coprimum cum 201: intra centum primos indices offsets non repetuntur.
    // Sic singulus shard centum dies vicinos sed non monotonicos interrogat.
    return static_cast<long long>((localIndex * 73 + shard * 29) % 201) - 100LL;
}

void writeResult(std::ostream& out,
                 int globalIndex,
                 const Integer& c,
                 const Integer& t,
                 const SpaghettiDateFive& d) {
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
                "usus: branch_vector_runner shard count result.tsv timing.tsv");
        }
        const int shard = std::stoi(argv[1]);
        const int count = std::stoi(argv[2]);
        if (shard < 0 || shard >= 100 || count <= 0 || count > 1000) {
            throw std::runtime_error("shard/count extra fines comparationis sunt");
        }

        std::ofstream results(argv[3], std::ios::trunc);
        std::ofstream timing(argv[4], std::ios::trunc);
        if (!results || !timing) {
            throw std::runtime_error("artifactum comparationis aperiri non potest");
        }

        const Integer c{calculationDayForShard(shard)};
        const auto wholeStart = Clock::now();
        long long firstMs = -1;
        long long restMs = 0;

        for (int i = 0; i < count; ++i) {
            const Integer t = c + targetOffsetForPair(shard, i);
            const auto begin = Clock::now();
            const auto d = pastafari::calendarDateSpaghetti(c, t);
            const auto end = Clock::now();
            const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();
            if (i == 0) firstMs = elapsed;
            else restMs += elapsed;
            writeResult(results, shard * count + i, c, t, d);
        }

        const auto wholeEnd = Clock::now();
        const auto totalMs = std::chrono::duration_cast<std::chrono::milliseconds>(wholeEnd - wholeStart).count();
        timing << "shard=" << shard << '\n'
               << "pairs=" << count << '\n'
               << "first_ms=" << firstMs << '\n'
               << "rest_ms=" << restMs << '\n'
               << "total_ms=" << totalMs << '\n';
        std::cout << "COMPARATIO_VECTORIS=PASS shard=" << shard
                  << " pairs=" << count
                  << " total_ms=" << totalMs << "\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "COMPARATIO_VECTORIS=FAIL " << error.what() << '\n';
        return 1;
    }
}
