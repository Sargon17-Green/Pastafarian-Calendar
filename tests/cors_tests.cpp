#include "pastafari/http_api/cors.hpp"
#include <cassert>
#include <cstdlib>
#include <iostream>
#include <stdexcept>
using namespace pastafari::http_api;

int main() {
    auto parsed = parseCorsOrigins(" https://one.example,https://two.example, https://one.example, null ");
    assert(parsed.size() == 2);
    assert(parsed[0] == "https://one.example");
    assert(parsed[1] == "https://two.example");

    CorsPolicy explicitPolicy({"https://allowed.example"}, false);
    assert(explicitPolicy.allows("https://allowed.example"));
    assert(!explicitPolicy.allows("https://evil.example"));
    assert(!explicitPolicy.allows("https://allowed.example/"));
    assert(!explicitPolicy.allows("null"));

    CorsPolicy localFilePolicy({"https://allowed.example"}, true);
    assert(localFilePolicy.allows("null"));

    unsetenv("PASTAFARI_CORS_ORIGINS");
    unsetenv("PASTAFARI_CORS_ALLOW_NULL_ORIGIN");
    auto defaults = CorsPolicy::fromEnvironment();
    assert(defaults.allows(DEFAULT_BROWSER_ORIGIN));
    assert(defaults.allows("null"));

    setenv("PASTAFARI_CORS_ORIGINS", "https://a.example, https://b.example", 1);
    auto configured = CorsPolicy::fromEnvironment();
    assert(configured.allows("https://a.example"));
    assert(configured.allows("https://b.example"));
    assert(!configured.allows(DEFAULT_BROWSER_ORIGIN));
    assert(configured.allows("null"));

    setenv("PASTAFARI_CORS_ALLOW_NULL_ORIGIN", "0", 1);
    auto nullDisabled = CorsPolicy::fromEnvironment();
    assert(!nullDisabled.allows("null"));
    assert(nullDisabled.allows("https://a.example"));

    setenv("PASTAFARI_CORS_ALLOW_NULL_ORIGIN", "invalid", 1);
    bool invalidRejected = false;
    try {
        (void)CorsPolicy::fromEnvironment();
    } catch (const std::invalid_argument&) {
        invalidRejected = true;
    }
    assert(invalidRejected);

    unsetenv("PASTAFARI_CORS_ORIGINS");
    unsetenv("PASTAFARI_CORS_ALLOW_NULL_ORIGIN");

    std::cout << "CORS_TESTS=PASS\n";
}
