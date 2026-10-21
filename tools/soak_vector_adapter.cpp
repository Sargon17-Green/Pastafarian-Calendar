#include "pastafari/monster.hpp"
#include <chrono>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>
using pastafari::Integer;
using Clock = std::chrono::steady_clock;
namespace {
bool decimal(const std::string& x) {
    if (x.empty()) return false;
    std::size_t i = x[0] == '-' ? 1 : 0;
    if (i == x.size()) return false;
    for (; i < x.size(); ++i) if (x[i] < '0' || x[i] > '9') return false;
    return true;
}
Integer parse(const std::string& x) {
    if (!decimal(x)) throw std::runtime_error("invalid decimal integer");
    return Integer{x};
}
bool validId(const std::string& x) {
    if (x.empty()) return false;
    for (char ch : x) {
        if (!((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
              (ch >= '0' && ch <= '9') || ch == '_' || ch == '-' ||
              ch == '.' || ch == ':')) return false;
    }
    return true;
}
void calculate(const std::string& line, bool timing) {
    const auto a = line.find('\t');
    const auto b = a == std::string::npos ? a : line.find('\t', a + 1);
    if (a == std::string::npos || b == std::string::npos ||
        line.find('\t', b + 1) != std::string::npos)
        throw std::runtime_error("expected three TSV columns");
    const auto id = line.substr(0, a);
    if (!validId(id)) throw std::runtime_error("invalid request ID");
    const Integer c = parse(line.substr(a + 1, b - a - 1));
    const Integer t = parse(line.substr(b + 1));
    const auto start = Clock::now();
    const auto result = pastafari::calendarDateSpaghetti(c, t);
    const auto end = Clock::now();
    if (result.cutletName.find_first_of("\r\n\t") != std::string::npos ||
        result.monthName.find_first_of("\r\n\t") != std::string::npos)
        throw std::runtime_error("invalid catalog name");
    std::cout << id << '\t' << c << '\t' << t << '\t'
              << result.yearNumber << '\t' << std::quoted(result.cutletName)
              << '\t' << result.dayInCutlet << '\t'
              << std::quoted(result.monthName) << '\t'
              << result.dayInMonth << '\n' << std::flush;
    if (!std::cout) throw std::runtime_error("output stream failed");
    if (timing) {
        const auto ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
            end - start).count();
        std::cerr << "SOAK_TIMING_NS\t" << id << '\t' << ns << '\n';
    }
}
}
int main(int argc, char** argv) {
    try {
        if (argc == 2 && std::string(argv[1]) == "--schema") {
            std::cout << "PASTAFARI_SOAK_TSV_V1\tid,c,t,year,cutlet,day_cutlet,month,day_month\n";
            return 0;
        }
        const bool timing = argc == 2 && std::string(argv[1]) == "--timing-ns";
        if (argc != 1 && !timing)
            throw std::runtime_error("usage: soak_vector_adapter [--schema|--timing-ns]");
        std::ios::sync_with_stdio(false);
        std::cin.tie(nullptr);
        std::string line;
        std::size_t n = 0;
        while (std::getline(std::cin, line)) {
            ++n;
            try { calculate(line, timing); }
            catch (const std::exception& e) {
                throw std::runtime_error("line " + std::to_string(n) + ": " + e.what());
            }
        }
        if (!std::cin.eof()) throw std::runtime_error("stdin error");
        if (!n) throw std::runtime_error("empty input");
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "SOAK_ADAPTER_ERROR\t" << e.what() << '\n';
        return 1;
    }
}
