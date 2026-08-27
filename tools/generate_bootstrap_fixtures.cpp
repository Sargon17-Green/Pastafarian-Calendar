#include "tests/reference/normative_reference.hpp"

#include <fstream>
#include <iostream>
#include <string>

using pastafari::reference::Big;

namespace {

void emit(std::ostream& out, const std::string& key, const Big& value) {
    out << key << '\t' << pastafari::reference::toDecimal(value) << '\n';
}

void emit(std::ostream& out, const std::string& key, int value) {
    out << key << '\t' << value << '\n';
}

} // namespace

int main(int argc, char** argv) {
    using namespace pastafari::reference;
    if (argc != 2) {
        std::cerr << "via fasciculi destinati requiritur\n";
        return 2;
    }
    std::ofstream out(argv[1], std::ios::binary | std::ios::trunc);
    if (!out) {
        std::cerr << "fasciculus destinatus aperiri non potest\n";
        return 3;
    }

    emit(out, "save_1", SAVE(1));
    emit(out, "save_M_minus_1", SAVE(M - 1));
    emit(out, "save_M", SAVE(M));
    emit(out, "save_M_plus_1", SAVE(M + 1));
    emit(out, "save_2M", SAVE(2 * M));

    emit(out, "day_foundation_minus_1", dayCount(FOUNDATION_DAY - 1));
    emit(out, "day_foundation", dayCount(FOUNDATION_DAY));
    emit(out, "day_foundation_plus_1", dayCount(FOUNDATION_DAY + 1));

    const auto counts = workCounts(FOUNDATION_DAY - 2, FOUNDATION_DAY + 3);
    emit(out, "counts_action", counts.action);
    emit(out, "counts_target", counts.target);
    emit(out, "counts_distance", counts.distance);
    emit(out, "counts_connection", counts.connection);
    emit(out, "counts_direction", counts.direction);

    const auto stones = buildStones();
    for (int kind = 0; kind < 5; ++kind) {
        emit(out, "stone_2_" + std::to_string(kind + 1), stones[2][kind]);
        emit(out, "stone_46_" + std::to_string(kind + 1), stones[46][kind]);
    }

    const auto s = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
    for (int i = 0; i < 6; ++i) {
        emit(out, "sauce_foundation_bowl_" + std::to_string(i + 1), s.bowls[i]);
        emit(out, "sauce_foundation_order_" + std::to_string(i + 1), s.orderAtDrop46[i]);
    }
    const auto stream = askBowl(s, 1, SEAL_GATE_GAP);
    emit(out, "sauce_foundation_ask_first", stream.first);
    emit(out, "sauce_foundation_ask_step", stream.directionStep);

    BoundedCompositionFamily family(9, 2, 4, 5);
    emit(out, "bounded_9_2_4_5_count", family.count());
    const auto first = family.unrank1(1);
    const auto second = family.unrank1(2);
    emit(out, "bounded_9_2_4_5_r1_a", first[0]);
    emit(out, "bounded_9_2_4_5_r1_b", first[1]);
    emit(out, "bounded_9_2_4_5_r2_a", second[0]);
    emit(out, "bounded_9_2_4_5_r2_b", second[1]);

    return 0;
}
