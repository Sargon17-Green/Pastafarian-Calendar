#include "pastafari/http_api/engine_port.hpp"
#include <cstdint>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

using namespace pastafari::http_api;

namespace {
std::int64_t parseDay(const char* text) {
    Integer value{std::string{text}};
    static const Integer lo = std::numeric_limits<std::int64_t>::min();
    static const Integer hi = std::numeric_limits<std::int64_t>::max();
    if (value < lo || value > hi) throw std::runtime_error("dies extra int64 est");
    return value.convert_to<std::int64_t>();
}

std::string cppString(std::string_view s) {
    static constexpr char HEX[] = "0123456789ABCDEF";
    std::string out = "\"";
    for (unsigned char c : s) {
        switch (c) {
            case '\\': out += "\\\\"; break;
            case '"': out += "\\\""; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (c < 0x20) {
                    out += "\\x";
                    out.push_back(HEX[c >> 4]);
                    out.push_back(HEX[c & 15]);
                } else {
                    out.push_back(static_cast<char>(c));
                }
        }
    }
    out.push_back('"');
    return out;
}

void emit(std::int64_t c, std::int64_t t, const CanonicalPastafariDate& value) {
    std::cout << "{true," << c << "LL," << t << "LL,"
              << cppString(value.year.str()) << ',' << value.cutletIndex << ','
              << cppString(value.cutletName) << ',' << cppString(value.dayInCutlet.str()) << ','
              << value.monthIndex << ',' << cppString(value.monthName) << ','
              << cppString(value.dayInMonth.str()) << "},\n";
}
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) {
            std::cerr << "usus: generate_hot_two_day_seed CALCULATION_DAY\n";
            return 2;
        }
        const std::int64_t base = parseDay(argv[1]);
        if (base > std::numeric_limits<std::int64_t>::max() - 2) {
            throw std::runtime_error("dies nimis prope terminum int64 est");
        }

        CeleritasEnginePort engine;
        const std::vector<std::pair<std::int64_t, std::int64_t>> pairs{
            {base, base},
            {base, base + 1},
            {base + 1, base + 1},
            {base + 1, base + 2}
        };

        std::cout << "// PASTAFARI_HOT_SEED_BASE_DAY=" << base << "\n";
        std::cout << "// PASTAFARI_HOT_SEED_GENERATION=1\n";
        std::cout << "// Quattuor sepulcra: hodie/cras pro die Veneris currenti et proximo.\n";
        for (const auto& [c, t] : pairs) {
            emit(c, t, engine.calculate(Integer{c}, Integer{t}));
        }
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "fatal: " << e.what() << '\n';
        return 1;
    }
}
