#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {
void require(bool condicio, const std::string& nuntius) {
    if (!condicio) throw std::runtime_error(nuntius);
}
std::string lege(const std::string& via) {
    std::ifstream in(via, std::ios::binary);
    require(static_cast<bool>(in), "fons audit aperiri non potest");
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}
}

int main() {
    try {
        const std::string productio=lege("src/monster.cpp");
        const auto initium=productio.find("void FinalIntegrationHandler::handle");
        require(initium!=std::string::npos,"FinalIntegrationHandler deest");
        const std::string finalis=productio.substr(initium);

        require(finalis.find("ctx.logs")==std::string::npos,
                "A: logs in semanticam finalem legi non debent");
        require(finalis.find("ctx.metrics.find")==std::string::npos &&
                finalis.find("ctx.metrics[")==std::string::npos,
                "B/I: metrics vel ordo insertionis eorum in semanticam legi non debent");
        require(finalis.find("ctx.mode = \"AUTHORITATIVE_SPAGHETTI\"")!=std::string::npos,
                "J: modus auctoritas fixus esse debet");
        require(finalis.find("random_device")==std::string::npos &&
                finalis.find("mt19937")==std::string::npos &&
                finalis.find("system_clock")==std::string::npos &&
                finalis.find("steady_clock")==std::string::npos &&
                finalis.find("rand(")==std::string::npos,
                "K: ramus semanticus nondeterminismum continet");
        require(finalis.find("NormativeOracle")==std::string::npos &&
                finalis.find("normative_reference")==std::string::npos,
                "O: fallback ad oracle prohibetur");

        const auto validation=finalis.find("validator.requireFinalIntegrationReady(ctx)");
        const auto cacheCommit=finalis.find("structureCache[targetYear.number] = pendingCacheEntry");
        require(validation!=std::string::npos && cacheCommit!=std::string::npos && validation<cacheCommit,
                "F/M: validationem ante cache commit fieri oportet");
        require(finalis.find("pendingCacheWrite")!=std::string::npos &&
                finalis.find("pendingCacheEntry")!=std::string::npos,
                "L/M: status cache pendens explicitus requiritur");
        require(finalis.find("BaseRecoverableError")!=std::string::npos &&
                finalis.find("FAILED_RETRY_EXHAUSTED")!=std::string::npos,
                "D/E/N: via recovery explicita deest");

        std::cout << "AUDIT_MONSTRI_TUTI_STATICUS_TRANSIIT: A,B,F,I,J,K,O et ordinem validationis/commit probavit; C,G,H runtime-workers et D,E,L,M,N recovery-audit probant\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "AUDIT_MONSTRI_TUTI_STATICUS_DEFECIT: " << error.what() << '\n';
        return 1;
    }
}
