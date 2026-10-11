#include "pastafari/monster.hpp"

#include <array>
#include <atomic>
#include <exception>
#include <iostream>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

namespace {
using pastafari::BowlState;
using pastafari::Integer;
using pastafari::PermutationOrder;
using pastafari::Stage56PostStirDetourWitness;

constexpr int N_WORKERS = 24;
constexpr int N_ROUNDS = 16;

void exige(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}

// Referentia invocationis non communicat statum cum dispatch atomico.
BowlState calculusIndependentis(const BowlState& original, int stir,
                               Integer& summaCruda, Integer& numerusServatus,
                               PermutationOrder& ordo) {
    summaCruda = 0;
    for (const Integer& b : original) summaCruda += b;
    numerusServatus = pastafari::savePatch(summaCruda + 149 * stir);
    const int numerus =
        (pastafari::regularMod(numerusServatus - 1, Integer{720}) + 1)
            .convert_to<int>();
    ordo = pastafari::oldPermutationUnrank0(numerus - 1);

    BowlState output = original;
    for (int position = 1; position <= 6; ++position) {
        const int b = ordo[static_cast<std::size_t>(position - 1)] - 1;
        const int p = ordo[static_cast<std::size_t>((position + 4) % 6)] - 1;
        const int n = ordo[static_cast<std::size_t>(position % 6)] - 1;
        const Integer u = original[static_cast<std::size_t>(b)]
            + 3 * original[static_cast<std::size_t>(p)]
            + 5 * original[static_cast<std::size_t>(n)]
            + numerusServatus + stir + position * position;
        output[static_cast<std::size_t>(b)] = pastafari::savePatch(
            u * u + 7 * original[static_cast<std::size_t>(p)]
                    * original[static_cast<std::size_t>(n)]);
    }
    return output;
}

BowlState facCrateres(int worker, int round) {
    BowlState bowls{};
    const Integer magnitudo = Integer{1} << (129 + worker % 5);
    for (int i = 0; i < 6; ++i) {
        const Integer delta = Integer{worker * 151 + round * 37 + i * 11 + 1};
        if (worker % 3 == 0) {
            bowls[static_cast<std::size_t>(i)] = -magnitudo + delta;
        } else {
            bowls[static_cast<std::size_t>(i)] = magnitudo + delta;
        }
    }
    return bowls;
}

void examina(const BowlState& old, int stir) {
    Integer raw{};
    Integer saved{};
    PermutationOrder order{};
    const BowlState expected =
        calculusIndependentis(old, stir, raw, saved, order);
    const Stage56PostStirDetourWitness actual =
        pastafari::stage56RawBowlSumPostStirDetour(old, stir);

    exige(actual.applied, "detour non applicatus est");
    exige(actual.stirIndex == stir, "index commotionis corruptus est");
    exige(actual.rawBowlSum == raw, "summa cruda corrupta est");
    exige(actual.savedOrderNumber == saved, "numerus servatus corruptus est");
    exige(actual.legacyOrder == order && actual.correctedOrder == order,
          "ordo permutationis corruptus est");
    exige(actual.oldResult == expected && actual.correctedResult == expected,
          "exitus canonici concurrentes discrepant");
}
} // namespace

int main() {
    try {
        std::atomic<int> parati{0};
        std::atomic<bool> initium{false};
        std::array<std::exception_ptr, N_WORKERS> errores{};
        std::vector<std::thread> turma;
        turma.reserve(N_WORKERS);

        // Prima vocatio in XXIV filis simul fit: slot nondum correctum est.
        for (int worker = 0; worker < N_WORKERS; ++worker) {
            turma.emplace_back([&, worker] {
                try {
                    parati.fetch_add(1, std::memory_order_release);
                    while (!initium.load(std::memory_order_acquire)) {
                        std::this_thread::yield();
                    }
                    for (int round = 0; round < N_ROUNDS; ++round) {
                        const BowlState bowls = facCrateres(worker, round);
                        for (int stir = 1; stir <= 12; ++stir) {
                            examina(bowls, stir);
                        }
                    }
                } catch (...) {
                    errores[static_cast<std::size_t>(worker)] =
                        std::current_exception();
                }
            });
        }

        while (parati.load(std::memory_order_acquire) != N_WORKERS) {
            std::this_thread::yield();
        }
        initium.store(true, std::memory_order_release);
        for (auto& filum : turma) filum.join();

        for (int i = 0; i < N_WORKERS; ++i) {
            if (errores[static_cast<std::size_t>(i)]) {
                try {
                    std::rethrow_exception(errores[static_cast<std::size_t>(i)]);
                } catch (const std::exception& e) {
                    throw std::runtime_error(
                        "filum " + std::to_string(i) + ": " + e.what());
                }
            }
        }

        // Iter solitarium post concursum probat statum iam stabilitum.
        const BowlState discriminator{
            Integer{1}, Integer{2}, Integer{3},
            Integer{4}, Integer{5}, Integer{6}
        };
        examina(discriminator, 1);
        std::cout << "GRADUS56_CONCURRENTIA_TRANSIIT FILA=" << N_WORKERS
                  << " CIRCUITUS=" << N_ROUNDS
                  << " COMMOTIONES=" << N_WORKERS * N_ROUNDS * 12 + 1
                  << "\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "GRADUS56_CONCURRENTIA_DEFECIT: " << e.what() << "\n";
        return 1;
    }
}
