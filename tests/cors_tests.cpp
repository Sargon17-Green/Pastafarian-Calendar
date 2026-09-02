#include "pastafari/http_api/cors.hpp"
#include <cassert>
#include <cstdlib>
#include <iostream>
using namespace pastafari::http_api;

int main() {
    auto parsed = parseCorsOrigins(" https://one.example,https://two.example, https://one.example ");
    assert(parsed.size() == 2);
    assert(parsed[0] == "https://one.example");
    assert(parsed[1] == "https://two.example");

    CorsPolicy explicitPolicy({"https://allowed.example"});
    assert(explicitPolicy.allows("https://allowed.example"));
    assert(!explicitPolicy.allows("https://evil.example"));
    assert(!explicitPolicy.allows("https://allowed.example/"));

    unsetenv("PASTAFARI_CORS_ORIGINS");
    auto defaults = CorsPolicy::fromEnvironment();
    assert(defaults.allows(DEFAULT_BROWSER_ORIGIN));

    setenv("PASTAFARI_CORS_ORIGINS", "https://a.example, https://b.example", 1);
    auto configured = CorsPolicy::fromEnvironment();
    assert(configured.allows("https://a.example"));
    assert(configured.allows("https://b.example"));
    assert(!configured.allows(DEFAULT_BROWSER_ORIGIN));
    unsetenv("PASTAFARI_CORS_ORIGINS");

    std::cout << "CORS_TESTS=PASS\n";
}
