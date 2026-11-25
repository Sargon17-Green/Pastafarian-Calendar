#include <gmpxx.h>
#include <algorithm>
#include <chrono>
#include <cctype>
#include <fstream>
#include <iostream>
#include <map>
#include <numeric>
#include <stdexcept>
#include <string>
#include <vector>
#include <functional>

using Big = mpz_class;
using Clock = std::chrono::steady_clock;

static std::string read_file(const std::string& path) {
    std::ifstream in(path, std::ios::binary);
    if (!in) throw std::runtime_error("cannot open " + path);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

static std::vector<long> parse_integer_array(const std::string& text, std::size_t start) {
    std::size_t left = text.find('[', start);
    if (left == std::string::npos) throw std::runtime_error("JSON array not found");
    std::vector<long> values;
    std::size_t i = left + 1;
    while (i < text.size()) {
        while (i < text.size() && (std::isspace(static_cast<unsigned char>(text[i])) || text[i] == ',')) ++i;
        if (i >= text.size()) throw std::runtime_error("unterminated JSON array");
        if (text[i] == ']') return values;
        if (!std::isdigit(static_cast<unsigned char>(text[i]))) throw std::runtime_error("nonpositive/noninteger JSON array item");
        long value = 0;
        while (i < text.size() && std::isdigit(static_cast<unsigned char>(text[i]))) {
            value = value * 10 + (text[i] - '0');
            ++i;
        }
        values.push_back(value);
    }
    throw std::runtime_error("unterminated JSON array");
}

static Big binomial(long n, long k) {
    if (n < 0 || k < 0 || k > n) return Big(0);
    Big out;
    mpz_bin_uiui(out.get_mpz_t(), static_cast<unsigned long>(n), static_cast<unsigned long>(k));
    return out;
}

static Big exact_div(const Big& numerator, const Big& denominator, const char* where) {
    if (denominator <= 0 || mpz_divisible_p(numerator.get_mpz_t(), denominator.get_mpz_t()) == 0)
        throw std::runtime_error(std::string("nonintegral exact division: ") + where);
    Big out;
    mpz_divexact(out.get_mpz_t(), numerator.get_mpz_t(), denominator.get_mpz_t());
    return out;
}

static std::vector<Big> exact_coefficients(long old_n, long multiplicity) {
    if (multiplicity < 2) throw std::runtime_error("coefficient multiplicity < 2");
    const long new_n = old_n + multiplicity;
    const long max_first = old_n + 1;
    std::vector<Big> coeff(static_cast<std::size_t>(max_first + 1));
    Big value(1);
    for (long p = max_first; p >= 1; --p) {
        coeff[static_cast<std::size_t>(p)] = value;
        if (p > 1) {
            Big numerator = value * (new_n - p);
            const long denominator = old_n - p + 2;
            value = exact_div(numerator, Big(denominator), "binomial coefficient recurrence");
        }
    }
    return coeff;
}

static std::vector<Big> all_open_blocks(const std::vector<long>& remaining, long closed) {
    const long k = static_cast<long>(remaining.size());
    if (closed < 0 || closed > k) throw std::runtime_error("all-open closure frontier invalid");
    std::vector<Big> blocks(static_cast<std::size_t>(k), Big(0));
    std::vector<long> r;
    for (long i = closed; i < k; ++i) {
        if (remaining[static_cast<std::size_t>(i)] <= 0) throw std::runtime_error("all-open suffix has zero multiplicity");
        r.push_back(remaining[static_cast<std::size_t>(i)]);
    }
    const long m = static_cast<long>(r.size());
    if (m == 0) return blocks;
    if (m == 1) {
        blocks[static_cast<std::size_t>(closed)] = 1;
        return blocks;
    }

    std::vector<long> cumulative(static_cast<std::size_t>(m));
    long running = 0;
    for (long i = 0; i < m; ++i) {
        running += r[static_cast<std::size_t>(i)];
        cumulative[static_cast<std::size_t>(i)] = running;
    }

    Big total(1), denominator(1);
    for (long i = 1; i < m; ++i) {
        total *= binomial(cumulative[static_cast<std::size_t>(i)] - 1,
                          r[static_cast<std::size_t>(i)] - 1);
        denominator *= (cumulative[static_cast<std::size_t>(i)] - 1);
    }
    Big gcd;
    mpz_gcd(gcd.get_mpz_t(), total.get_mpz_t(), denominator.get_mpz_t());
    Big total_reduced = exact_div(total, gcd, "all-open total gcd");
    Big denominator_reduced = exact_div(denominator, gcd, "all-open denominator gcd");

    Big first_numerator(1);
    for (long j = 1; j < m; ++j) first_numerator *= cumulative[static_cast<std::size_t>(j - 1)];
    blocks[static_cast<std::size_t>(closed)] =
        total_reduced * exact_div(first_numerator, denominator_reduced, "first all-open child");

    std::vector<Big> prefix_denominator(static_cast<std::size_t>(m + 1), Big(1));
    for (long i = 2; i <= m; ++i) {
        prefix_denominator[static_cast<std::size_t>(i)] =
            prefix_denominator[static_cast<std::size_t>(i - 1)] *
            (cumulative[static_cast<std::size_t>(i - 1)] - 1);
    }
    std::vector<Big> suffix_numerator(static_cast<std::size_t>(m + 1), Big(1));
    for (long i = m - 1; i >= 1; --i) {
        suffix_numerator[static_cast<std::size_t>(i)] =
            suffix_numerator[static_cast<std::size_t>(i + 1)] *
            cumulative[static_cast<std::size_t>(i - 1)];
    }

    for (long i = 1; i < m; ++i) {
        if (r[static_cast<std::size_t>(i)] == 1) continue; // cannot close out of order
        Big numerator = (r[static_cast<std::size_t>(i)] - 1) *
                        prefix_denominator[static_cast<std::size_t>(i)] *
                        suffix_numerator[static_cast<std::size_t>(i + 1)];
        Big quotient = exact_div(numerator, denominator_reduced, "all-open child numerator");
        blocks[static_cast<std::size_t>(closed + i)] = total_reduced * quotient;
    }

    Big sum(0);
    for (const auto& block : blocks) sum += block;
    if (sum != total) throw std::runtime_error("all-open child blocks do not partition parent");
    return blocks;
}

struct CoeffPair { Big a{0}; Big b{0}; };

static std::vector<Big> first_letter_blocks(const std::vector<long>& remaining,
                                            long opened, long closed) {
    const long k = static_cast<long>(remaining.size());
    if (!(0 <= closed && closed <= opened && opened <= k))
        throw std::runtime_error("open/closed frontier invalid");
    for (long i = 0; i < closed; ++i)
        if (remaining[static_cast<std::size_t>(i)] != 0) throw std::runtime_error("closed label has remaining occurrences");
    for (long i = closed; i < k; ++i)
        if (remaining[static_cast<std::size_t>(i)] <= 0) throw std::runtime_error("active/unopened label has no remaining occurrences");

    if (opened >= k - 1) return all_open_blocks(remaining, closed);

    const long next_unopened = opened; // zero-based
    std::vector<CoeffPair> coefficients(static_cast<std::size_t>(k));
    std::vector<Big> b0, b1;
    Big sum0(0), sum1(0);
    long current_n = 0;

    if (next_unopened == closed) {
        current_n = remaining[static_cast<std::size_t>(next_unopened)];
        b0.assign(static_cast<std::size_t>(current_n + 1), Big(0));
        b0[1] = 1;
        b1.assign(static_cast<std::size_t>(current_n + 1), Big(0));
        coefficients[static_cast<std::size_t>(next_unopened)].a = 1;
        sum0 = 1;
    } else {
        std::vector<long> previous_remaining;
        for (long i = closed; i < next_unopened; ++i)
            previous_remaining.push_back(remaining[static_cast<std::size_t>(i)]);
        std::vector<Big> previous_blocks = all_open_blocks(previous_remaining, 0);
        Big previous_total(0);
        long previous_n = 0;
        for (long i = 0; i < static_cast<long>(previous_remaining.size()); ++i) {
            const Big& value = previous_blocks[static_cast<std::size_t>(i)];
            coefficients[static_cast<std::size_t>(closed + i)].a = value;
            previous_total += value;
            previous_n += previous_remaining[static_cast<std::size_t>(i)];
        }
        const long multiplicity = remaining[static_cast<std::size_t>(next_unopened)];
        current_n = previous_n + multiplicity;
        b0.assign(static_cast<std::size_t>(current_n + 1), Big(0));
        b1.assign(static_cast<std::size_t>(current_n + 1), Big(0));
        if (multiplicity == 1) {
            b0[static_cast<std::size_t>(current_n)] = 1;
            sum0 = 1;
        } else {
            std::vector<Big> coeff = exact_coefficients(previous_n, multiplicity);
            for (long p = 2; p <= previous_n + 1; ++p)
                b0[static_cast<std::size_t>(p)] = coeff[static_cast<std::size_t>(p)];
            b1[1] = coeff[1];
            coefficients[static_cast<std::size_t>(next_unopened)].b = previous_total;
            for (const auto& value : b0) sum0 += value;
            for (const auto& value : b1) sum1 += value;
        }
    }

    for (long label = next_unopened + 1; label < k; ++label) {
        const long multiplicity = remaining[static_cast<std::size_t>(label)];
        const long old_n = current_n;
        current_n += multiplicity;
        std::vector<Big> new_b0(static_cast<std::size_t>(current_n + 1), Big(0));
        std::vector<Big> new_b1(static_cast<std::size_t>(current_n + 1), Big(0));
        if (multiplicity == 1) {
            for (long q = 0; q < k; ++q) {
                Big value = coefficients[static_cast<std::size_t>(q)].a * sum0 +
                            coefficients[static_cast<std::size_t>(q)].b * sum1;
                coefficients[static_cast<std::size_t>(q)].a = value;
                coefficients[static_cast<std::size_t>(q)].b = 0;
            }
            new_b0[static_cast<std::size_t>(current_n)] = 1;
            sum0 = 1;
            sum1 = 0;
        } else {
            std::vector<Big> coeff = exact_coefficients(old_n, multiplicity);
            Big prefix0(0), prefix1(0);
            for (long p = 1; p <= old_n + 1; ++p) {
                if (p - 1 < static_cast<long>(b0.size())) prefix0 += b0[static_cast<std::size_t>(p - 1)];
                if (p - 1 < static_cast<long>(b1.size())) prefix1 += b1[static_cast<std::size_t>(p - 1)];
                new_b0[static_cast<std::size_t>(p)] = prefix0 * coeff[static_cast<std::size_t>(p)];
                new_b1[static_cast<std::size_t>(p)] = prefix1 * coeff[static_cast<std::size_t>(p)];
            }
            sum0 = 0;
            sum1 = 0;
            for (const auto& value : new_b0) sum0 += value;
            for (const auto& value : new_b1) sum1 += value;
        }
        b0.swap(new_b0);
        b1.swap(new_b1);
    }

    std::vector<Big> blocks(static_cast<std::size_t>(k), Big(0));
    Big total(0);
    for (long q = 0; q < k; ++q) {
        const auto& coefficient = coefficients[static_cast<std::size_t>(q)];
        Big value = coefficient.a * sum0 + coefficient.b * sum1;
        if (value > 0) {
            blocks[static_cast<std::size_t>(q)] = value;
            total += value;
        }
    }
    if (total <= 0) throw std::runtime_error("nonterminal suffix has no first-letter blocks");
    return blocks;
}

static std::vector<std::vector<long>> enumerate_tiny(const std::vector<long>& lengths) {
    const long k = static_cast<long>(lengths.size());
    std::vector<long> remaining = lengths;
    std::vector<long> prefix;
    std::vector<std::vector<long>> words;
    std::function<void(long,long)> visit = [&](long opened, long closed) {
        bool done = true;
        for (long x : remaining) if (x) { done = false; break; }
        if (done) { words.push_back(prefix); return; }
        for (long label = closed; label < std::min(opened + 1, k); ++label) {
            long& left = remaining[static_cast<std::size_t>(label)];
            if (left <= 0 || (left == 1 && label != closed)) continue;
            long before = left;
            --left;
            prefix.push_back(label);
            visit(opened + (label == opened ? 1 : 0),
                  closed + (label == closed && before == 1 ? 1 : 0));
            prefix.pop_back();
            ++left;
        }
    };
    visit(0,0);
    return words;
}

static std::string prefix_key(const std::vector<long>& word, long length) {
    std::string out;
    for (long i = 0; i < length; ++i) {
        if (i) out.push_back(',');
        out += std::to_string(word[static_cast<std::size_t>(i)]);
    }
    return out;
}

static void run_tiny_self_test() {
    const std::vector<std::vector<long>> families = {
        {2,2}, {2,2,2}, {2,3,2}, {3,2,3}, {2,2,2,2}, {3,2,2},
        {2,3,3,2}, {2,2,2,2,3}, {2,2,3,3}, {3,3}, {3,2},
        {2,2,3,3,2}, {3,3,2,2}, {3,2,3,2}, {3,2,2,3}, {2,3,2,2}
    };
    long total_words = 0, total_prefixes = 0;
    for (const auto& lengths : families) {
        auto words = enumerate_tiny(lengths);
        if (words.empty()) throw std::runtime_error("tiny family unexpectedly empty");
        if (!std::is_sorted(words.begin(), words.end())) throw std::runtime_error("tiny words not lexicographically sorted");
        std::map<std::string, std::map<long,long>> expected;
        std::map<std::string, std::vector<long>> prefix_values;
        for (const auto& word : words) {
            for (long pos = 0; pos < static_cast<long>(word.size()); ++pos) {
                std::string key = prefix_key(word, pos);
                expected[key][word[static_cast<std::size_t>(pos)]]++;
                prefix_values[key] = std::vector<long>(word.begin(), word.begin() + pos);
            }
        }
        std::map<std::string, std::vector<Big>> cache;
        for (const auto& item : expected) {
            const auto& prefix = prefix_values[item.first];
            std::vector<long> remaining = lengths;
            long opened = 0, closed = 0;
            for (long label : prefix) {
                long before = remaining[static_cast<std::size_t>(label)];
                --remaining[static_cast<std::size_t>(label)];
                if (before == lengths[static_cast<std::size_t>(label)]) ++opened;
                if (remaining[static_cast<std::size_t>(label)] == 0) ++closed;
            }
            std::vector<Big> blocks = first_letter_blocks(remaining, opened, closed);
            for (long q = 0; q < static_cast<long>(lengths.size()); ++q) {
                long wanted = 0;
                auto it = item.second.find(q);
                if (it != item.second.end()) wanted = it->second;
                if (blocks[static_cast<std::size_t>(q)] != wanted)
                    throw std::runtime_error("tiny exhaustive first-letter partition mismatch");
            }
            Big parent(0);
            for (const auto& value : blocks) parent += value;
            long expected_parent = 0;
            for (const auto& child : item.second) expected_parent += child.second;
            if (parent != expected_parent) throw std::runtime_error("tiny parent partition mismatch");
            ++total_prefixes;
        }
        total_words += static_cast<long>(words.size());
    }
    std::cout << "TINY_EXHAUSTIVE_PARTITIONS_PASS FAMILIES=" << families.size()
              << " WORDS=" << total_words << " PREFIXES=" << total_prefixes << "\n";
}

static Big parse_big_decimal(const std::string& text, const char* where) {
    if (text.empty()) throw std::runtime_error(std::string("empty big integer: ") + where);
    Big value;
    if (mpz_set_str(value.get_mpz_t(), text.c_str(), 10) != 0)
        throw std::runtime_error(std::string("invalid big integer: ") + where);
    return value;
}

static std::vector<std::string> split_csv(const std::string& line) {
    std::vector<std::string> fields;
    std::size_t start = 0;
    while (true) {
        std::size_t comma = line.find(',', start);
        if (comma == std::string::npos) { fields.push_back(line.substr(start)); break; }
        fields.push_back(line.substr(start, comma - start));
        start = comma + 1;
    }
    return fields;
}

static std::string after_equals(const std::string& line, const char* prefix) {
    const std::string p(prefix);
    if (line.rfind(p, 0) != 0) throw std::runtime_error(std::string("reference trace header missing ") + prefix);
    return line.substr(p.size());
}

static void run_full(const std::string& word_path, const std::string& fixture_path,
                     const std::string& trace_path, const std::string& summary_path,
                     double time_limit_seconds, const std::string& reference_path) {
    const std::string word_json = read_file(word_path);
    const std::string fixture_json = read_file(fixture_path);
    const std::size_t key = fixture_json.find("\"month_lengths\"");
    if (key == std::string::npos) throw std::runtime_error("month_lengths key missing");
    std::vector<long> lengths = parse_integer_array(fixture_json, key);
    std::vector<long> word = parse_integer_array(word_json, 0);
    if (lengths.size() != 45 || word.size() != 4244) throw std::runtime_error("canonical input dimensions mismatch");
    long day_sum = std::accumulate(lengths.begin(), lengths.end(), 0L);
    if (day_sum != 4244 || *std::min_element(lengths.begin(), lengths.end()) != 25 ||
        *std::max_element(lengths.begin(), lengths.end()) != 122)
        throw std::runtime_error("canonical length vector violates 45/4244/4..123 contract");

    std::vector<long> counts(lengths.size(), 0), first(lengths.size(), -1), last(lengths.size(), -1);
    for (long pos = 0; pos < static_cast<long>(word.size()); ++pos) {
        long label = word[static_cast<std::size_t>(pos)] - 1;
        if (label < 0 || label >= static_cast<long>(lengths.size())) throw std::runtime_error("word label out of range");
        ++counts[static_cast<std::size_t>(label)];
        if (first[static_cast<std::size_t>(label)] < 0) first[static_cast<std::size_t>(label)] = pos;
        last[static_cast<std::size_t>(label)] = pos;
    }
    if (counts != lengths) throw std::runtime_error("word multiplicities do not match fixture");
    for (long i = 1; i < static_cast<long>(lengths.size()); ++i) {
        if (first[static_cast<std::size_t>(i - 1)] >= first[static_cast<std::size_t>(i)] ||
            last[static_cast<std::size_t>(i - 1)] >= last[static_cast<std::size_t>(i)])
            throw std::runtime_error("word violates first/last order");
    }

    std::ifstream reference;
    Big reference_root(0), reference_rank(0);
    bool have_reference = !reference_path.empty();
    if (have_reference) {
        reference.open(reference_path, std::ios::binary);
        if (!reference) throw std::runtime_error("cannot open reference trace");
        std::string root_line, rank_line;
        if (!std::getline(reference, root_line) || !std::getline(reference, rank_line))
            throw std::runtime_error("reference trace header truncated");
        reference_root = parse_big_decimal(after_equals(root_line, "root="), "reference root");
        reference_rank = parse_big_decimal(after_equals(rank_line, "rank="), "reference rank");
    }
    long reference_matches = 0;

    std::ofstream trace(trace_path, std::ios::binary);
    if (!trace) throw std::runtime_error("cannot create trace file");
    trace << "prefix_length\tsymbol\trank_low\trank_high\tlegal_next_count\tmethod\n";

    std::vector<long> remaining = lengths;
    long opened = 0, closed = 0;
    Big low(1), high(0), root_count(0);
    long endpoint_order_only_at = -1;
    long all_labels_opened_at = -1;
    const auto start = Clock::now();

    for (long position = 1; position <= static_cast<long>(word.size()); ++position) {
        const double elapsed = std::chrono::duration<double>(Clock::now() - start).count();
        if (elapsed > time_limit_seconds) throw std::runtime_error("time limit exceeded at prefix " + std::to_string(position));
        const long symbol = word[static_cast<std::size_t>(position - 1)];
        const long selected = symbol - 1;
        std::vector<Big> blocks = first_letter_blocks(remaining, opened, closed);
        Big parent(0);
        long legal_count = 0;
        for (const auto& block : blocks) if (block > 0) { parent += block; ++legal_count; }
        if (parent <= 0) throw std::runtime_error("empty parent completion set");
        if (position == 1) {
            root_count = parent;
            if (have_reference && reference_root != root_count)
                throw std::runtime_error("reference trace root differs from independent root count");
        } else if (high - low + 1 != parent) {
            throw std::runtime_error("parent interval width differs from independently counted suffix");
        }
        if (blocks[static_cast<std::size_t>(selected)] <= 0) throw std::runtime_error("word symbol is not a legal next symbol");
        Big partition_sum(0);
        Big offset(0);
        for (long q = 0; q < static_cast<long>(blocks.size()); ++q) {
            partition_sum += blocks[static_cast<std::size_t>(q)];
            if (q < selected) offset += blocks[static_cast<std::size_t>(q)];
        }
        if (partition_sum != parent) throw std::runtime_error("child blocks do not sum to parent");
        const Big selected_block = blocks[static_cast<std::size_t>(selected)];
        Big new_low = low + offset;
        Big new_high = new_low + selected_block - 1;
        if (new_high - new_low + 1 != selected_block) throw std::runtime_error("selected child interval width mismatch");
        if (have_reference) {
            std::string reference_line;
            if (!std::getline(reference, reference_line)) throw std::runtime_error("reference trace ended before all prefixes");
            const auto fields = split_csv(reference_line);
            if (fields.size() != 5) throw std::runtime_error("reference trace row field count mismatch");
            const long ref_position = std::stol(fields[0]);
            const long ref_symbol = std::stol(fields[1]);
            const long ref_opened = std::stol(fields[2]);
            const Big ref_count = parse_big_decimal(fields[3], "reference selected block");
            const Big ref_skip = parse_big_decimal(fields[4], "reference skipped count");
            const long expected_opened = opened + (remaining[static_cast<std::size_t>(selected)] == lengths[static_cast<std::size_t>(selected)] ? 1 : 0);
            if (ref_position != position || ref_symbol != symbol || ref_opened != expected_opened ||
                ref_count != selected_block || ref_skip + 1 != new_low || ref_skip + ref_count != new_high)
                throw std::runtime_error("independent inverse interval differs from archived unrank trace at prefix " + std::to_string(position));
            ++reference_matches;
        }
        const char* method = (opened < static_cast<long>(lengths.size()) - 1)
                                 ? "two-basis-first-letter-DP" : "all-open-common-denominator";
        trace << position << '\t' << symbol << '\t' << new_low.get_str() << '\t'
              << new_high.get_str() << '\t' << legal_count << '\t' << method << '\n';
        if (!trace) throw std::runtime_error("failed while writing full prefix trace");
        low = new_low;
        high = new_high;

        const long before = remaining[static_cast<std::size_t>(selected)];
        --remaining[static_cast<std::size_t>(selected)];
        if (before == lengths[static_cast<std::size_t>(selected)]) {
            if (selected != opened) throw std::runtime_error("first occurrence order violation");
            ++opened;
        }
        if (remaining[static_cast<std::size_t>(selected)] == 0) {
            if (selected != closed) throw std::runtime_error("last occurrence order violation");
            ++closed;
        }
        if (endpoint_order_only_at < 0 && opened >= static_cast<long>(lengths.size()) - 1) endpoint_order_only_at = position;
        if (all_labels_opened_at < 0 && opened == static_cast<long>(lengths.size())) all_labels_opened_at = position;
        if (position % 20 == 0 || position == static_cast<long>(word.size())) {
            const double seconds = std::chrono::duration<double>(Clock::now() - start).count();
            std::cout << "PROGRESS PREFIX=" << position << "/" << word.size()
                      << " OPENED=" << opened << " CLOSED=" << closed
                      << " SECONDS=" << seconds << "\n" << std::flush;
        }
    }
    trace.close();
    if (std::any_of(remaining.begin(), remaining.end(), [](long x){ return x != 0; }) ||
        opened != static_cast<long>(lengths.size()) || closed != static_cast<long>(lengths.size()))
        throw std::runtime_error("terminal frontier did not close every label");
    if (low != high) throw std::runtime_error("complete word interval is not a singleton");
    if (have_reference) {
        std::string final_line, extra_line;
        if (reference_rank != low) throw std::runtime_error("reference trace rank differs from independent inverse rank");
        if (!std::getline(reference, final_line) || final_line != "inverse_rank=" + low.get_str())
            throw std::runtime_error("reference trace final inverse_rank marker mismatch");
        if (std::getline(reference, extra_line)) throw std::runtime_error("reference trace has trailing data");
        if (reference_matches != static_cast<long>(word.size())) throw std::runtime_error("reference trace did not match every prefix");
        std::cout << "REFERENCE_TRACE_DIFFERENTIAL_PASS MATCHED=" << reference_matches << "/" << word.size() << "\n";
    }

    const double seconds = std::chrono::duration<double>(Clock::now() - start).count();
    std::ofstream summary(summary_path, std::ios::binary);
    if (!summary) throw std::runtime_error("cannot create summary file");
    summary << "ROOT_COUNT=" << root_count.get_str() << "\n";
    summary << "FINAL_RANK=" << low.get_str() << "\n";
    summary << "PREFIX_INTERVALS=" << word.size() << "\n";
    summary << "ENDPOINT_ORDER_ONLY_AT_PREFIX=" << endpoint_order_only_at << "\n";
    summary << "ALL_LABELS_OPENED_AT_PREFIX=" << all_labels_opened_at << "\n";
    summary << "REFERENCE_TRACE_MATCHED=" << reference_matches << "\n";
    summary << "ELAPSED_SECONDS=" << seconds << "\n";
    summary.close();
    std::cout << "CORE_PASS ROOT_DIGITS=" << root_count.get_str().size()
              << " FINAL_RANK_DIGITS=" << low.get_str().size()
              << " PREFIX_INTERVALS=" << word.size()
              << " ENDPOINT_ORDER_ONLY_AT_PREFIX=" << endpoint_order_only_at
              << " ALL_LABELS_OPENED_AT_PREFIX=" << all_labels_opened_at
              << " ELAPSED_SECONDS=" << seconds << "\n";
}

int main(int argc, char** argv) {
    try {
        std::string word_path, fixture_path, trace_path, summary_path, reference_path;
        double time_limit_seconds = 270.0;
        for (int i = 1; i < argc; ++i) {
            std::string arg = argv[i];
            if (arg == "--word" && i + 1 < argc) word_path = argv[++i];
            else if (arg == "--fixture" && i + 1 < argc) fixture_path = argv[++i];
            else if (arg == "--trace" && i + 1 < argc) trace_path = argv[++i];
            else if (arg == "--summary" && i + 1 < argc) summary_path = argv[++i];
            else if (arg == "--reference-trace" && i + 1 < argc) reference_path = argv[++i];
            else if (arg == "--time-limit-seconds" && i + 1 < argc) time_limit_seconds = std::stod(argv[++i]);
            else throw std::runtime_error("unknown or incomplete argument: " + arg);
        }
        if (word_path.empty() || fixture_path.empty() || trace_path.empty() || summary_path.empty())
            throw std::runtime_error("required args: --word --fixture --trace --summary");
        std::cout << "STAGE55_FULL_PREFIX_INVERSE_RANK_BEGIN\n";
        run_tiny_self_test();
        run_full(word_path, fixture_path, trace_path, summary_path, time_limit_seconds, reference_path);
        std::cout << "STAGE55_FULL_PREFIX_INVERSE_RANK_CORE_PASS\n";
        return 0;
    } catch (const std::exception& ex) {
        std::cerr << "STAGE55_FULL_PREFIX_INVERSE_RANK_FAIL " << ex.what() << "\n";
        return 1;
    }
}
