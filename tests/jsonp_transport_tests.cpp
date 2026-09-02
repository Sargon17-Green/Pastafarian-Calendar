#include "pastafari/http_api/http_protocol.hpp"
#include <cassert>
#include <iostream>
#include <string>
using namespace pastafari::http_api;

struct FakeJsonpEngine : EnginePort {
    CanonicalPastafariDate calculate(const Integer&, const Integer&) override {
        return {5000, 7, "Palguras", 3, 28, "Ninive", 4};
    }
};

int main() {
    FakeJsonpEngine engine;
    CalendarService service(engine);
    HttpProtocol protocol(service);

    auto ok = protocol.handle(
        "GET",
        "/v1/date.js?date=2026-09-02&calculation_day=42&language=la&callback=pastafariDateCallback",
        "", "", 0);
    assert(ok.status == 200);
    assert(ok.headers.at("Content-Type") == "application/javascript; charset=utf-8");
    assert(ok.headers.at("X-Content-Type-Options") == "nosniff");
    assert(ok.headers.at("Cross-Origin-Resource-Policy") == "cross-origin");
    assert(ok.body.starts_with("pastafariDateCallback({"));
    assert(ok.body.ends_with(");"));
    assert(ok.body.find("\"engineDay\":\"42\"") != std::string::npos);
    assert(ok.body.find("\"language\":\"la\"") != std::string::npos);
    assert(ok.body.find("Palguras") != std::string::npos);

    auto missing = protocol.handle(
        "GET", "/v1/date.js?date=2026-09-02&calculation_day=42", "", "", 0);
    assert(missing.status == 400);
    assert(missing.body.find("MISSING_FIELD") != std::string::npos);

    auto injected = protocol.handle(
        "GET",
        "/v1/date.js?date=2026-09-02&calculation_day=42&callback=alert%281%29",
        "", "", 0);
    assert(injected.status == 400);
    assert(injected.body.find("INVALID_CALLBACK") != std::string::npos);

    auto dotted = protocol.handle(
        "GET",
        "/v1/date.js?date=2026-09-02&calculation_day=42&callback=window.cb",
        "", "", 0);
    assert(dotted.status == 400);
    assert(dotted.body.find("INVALID_CALLBACK") != std::string::npos);

    auto languageError = protocol.handle(
        "GET",
        "/v1/date.js?date=2026-09-02&calculation_day=42&language=he&callback=pastafariDateCallback",
        "", "", 0);
    assert(languageError.status == 200);
    assert(languageError.headers.at("Content-Type") == "application/javascript; charset=utf-8");
    assert(languageError.headers.at("X-Pastafari-Application-Status") == "422");
    assert(languageError.headers.at("Cache-Control") == "no-store");
    assert(languageError.body.starts_with("pastafariDateCallback({"));
    assert(languageError.body.find("LANGUAGE_NOT_SUPPORTED") != std::string::npos);

    auto post = protocol.handle(
        "POST",
        "/v1/date.js?callback=pastafariDateCallback",
        "application/json", "{}", 0);
    assert(post.status == 405);
    assert(post.body.find("METHOD_NOT_ALLOWED") != std::string::npos);

    std::cout << "JSONP_TRANSPORT_TESTS=PASS\n";
}
