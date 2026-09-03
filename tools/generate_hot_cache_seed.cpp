#include "pastafari/http_api/engine_port.hpp"
#include "pastafari/http_api/pair_tomb.hpp"
#include "pastafari/monster.hpp"
#include "pastafari/source_language_catalog.hpp"
#include <algorithm>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

using namespace pastafari::http_api;

namespace {
constexpr std::int64_t HOT_CORRIDOR_BEHIND_DAYS = 10000;
constexpr std::int64_t HOT_CORRIDOR_AHEAD_DAYS = 30000;

std::int64_t parseDay(const char* text) {
    Integer value{std::string{text}};
    static const Integer lo = std::numeric_limits<std::int64_t>::min();
    static const Integer hi = std::numeric_limits<std::int64_t>::max();
    if (value < lo || value > hi) throw std::runtime_error("dies extra int64 est");
    return value.convert_to<std::int64_t>();
}

std::int64_t narrowPastafari(const pastafari::Integer& value,const char* what){
    static const pastafari::Integer lo=std::numeric_limits<std::int64_t>::min();
    static const pastafari::Integer hi=std::numeric_limits<std::int64_t>::max();
    if(value<lo||value>hi)throw std::runtime_error(std::string(what)+" extra int64 est");
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
                } else out.push_back(static_cast<char>(c));
        }
    }
    out.push_back('"');
    return out;
}

void emitPair(std::ostream& out,std::int64_t c,std::int64_t t,const CanonicalPastafariDate& value) {
    out << "{true," << c << "LL," << t << "LL,"
        << cppString(value.year.str()) << ',' << value.cutletIndex << ','
        << cppString(value.cutletName) << ',' << cppString(value.dayInCutlet.str()) << ','
        << value.monthIndex << ',' << cppString(value.monthName) << ','
        << cppString(value.dayInMonth.str()) << "},\n";
}

CanonicalPastafariDate canonicalFromFive(const pastafari::SpaghettiDateFive& r){
    std::size_t ci=0,mi=0;
    for(const auto&e:pastafari::CUTLET_SOURCE_CATALOG)if(e.text==r.cutletName){ci=e.canonicalIndex;break;}
    for(const auto&e:pastafari::MONTH_SOURCE_CATALOG)if(e.text==r.monthName){mi=e.canonicalIndex;break;}
    if(ci==0||mi==0)throw std::runtime_error("nomen structure ad catalogum non pertinet");
    return{r.yearNumber,ci,r.cutletName,r.dayInCutlet,mi,r.monthName,r.dayInMonth};
}

bool same(const CanonicalPastafariDate&a,const CanonicalPastafariDate&b){
    return a.year==b.year&&a.cutletIndex==b.cutletIndex&&a.cutletName==b.cutletName&&
           a.dayInCutlet==b.dayInCutlet&&a.monthIndex==b.monthIndex&&a.monthName==b.monthName&&a.dayInMonth==b.dayInMonth;
}

void emitIntVector(std::ostream&out,const std::vector<int>&v){
    out<<"std::vector<int>{";
    for(std::size_t i=0;i<v.size();++i){if(i)out<<',';out<<v[i];}
    out<<'}';
}
void emitSizeVector(std::ostream&out,const std::vector<int>&v){
    out<<"std::vector<std::size_t>{";
    for(std::size_t i=0;i<v.size();++i){if(i)out<<',';out<<v[i];}
    out<<'}';
}

void emitAlmanac(std::ostream&out,int ordinal,std::int64_t c,const pastafari::Stage54IntegrationReport& report){
    if(!report.ready||!report.exactFiveFieldReturn)throw std::runtime_error("report almanaci non paratus est");
    const auto open=narrowPastafari(report.targetYear.openGateDay,"porta aperiens");
    const auto close=narrowPastafari(report.targetYear.closeGateDay,"porta claudens");
    if(close<=open)throw std::runtime_error("fines almanaci inversi sunt");
    const auto length=static_cast<std::size_t>(close-open);
    if(report.structure.monthWeaving.size()!=length)throw std::runtime_error("textura mensium longitudinem anni non aequat");
    out<<"// PASTAFARI_HOT_ALMANAC_"<<ordinal<<"_CALCULATION_DAY="<<c<<"\n";
    out<<"// PASTAFARI_HOT_ALMANAC_"<<ordinal<<"_YEAR="<<report.targetYear.number<<"\n";
    out<<"// PASTAFARI_HOT_ALMANAC_"<<ordinal<<"_OPEN="<<open<<"\n";
    out<<"// PASTAFARI_HOT_ALMANAC_"<<ordinal<<"_CLOSE="<<close<<"\n";
    out<<"(void)buryHotAlmanacDiagnostic(decimalInteger("<<cppString(std::to_string(c))<<"),decimalInteger("<<cppString(report.targetYear.number.str())<<"),decimalInteger("<<cppString(std::to_string(open))<<"),decimalInteger("<<cppString(std::to_string(close))<<"),\n";
    out<<"    std::vector<AlmanacCutlet>{";
    for(std::size_t i=0;i<report.structure.cutlets.size();++i){
        const auto&cut=report.structure.cutlets[i];
        if(i)out<<',';
        out<<'{'<<cut.canonicalIndex<<','<<narrowPastafari(cut.firstDay,"primus dies cutlet")<<"LL,"<<narrowPastafari(cut.lastDay,"ultimus dies cutlet")<<"LL}";
    }
    out<<"},\n    ";emitIntVector(out,report.structure.monthWeaving);out<<",\n    ";emitSizeVector(out,report.structure.monthNameIndices);out<<");\n";
}

std::vector<pastafari::Stage54IntegrationReport> buildCorridor(std::int64_t calculationDay){
    if(calculationDay<std::numeric_limits<std::int64_t>::min()+HOT_CORRIDOR_BEHIND_DAYS ||
       calculationDay>std::numeric_limits<std::int64_t>::max()-HOT_CORRIDOR_AHEAD_DAYS)
        throw std::runtime_error("calculationDay nimis prope terminum corridoris est");

    const pastafari::Integer c{calculationDay};
    const pastafari::Integer low{calculationDay-HOT_CORRIDOR_BEHIND_DAYS};
    const pastafari::Integer high{calculationDay+HOT_CORRIDOR_AHEAD_DAYS};

    pastafari::BaseMonsterManager manager;
    auto center=manager.executeFinalIntegrationStage56(c,c);
    if(!center.ready||!center.exactFiveFieldReturn)throw std::runtime_error("centrum corridoris non paratum est");

    std::vector<pastafari::Stage54IntegrationReport> before;
    auto cursorOpen=center.targetYear.openGateDay;
    while(cursorOpen>low){
        auto prior=manager.executeFinalIntegrationStage56(c,cursorOpen);
        if(!prior.ready||!prior.exactFiveFieldReturn)throw std::runtime_error("annus prior corridoris non paratus est");
        if(prior.targetYear.closeGateDay!=cursorOpen)throw std::runtime_error("continuitas prior corridoris fracta est");
        if(prior.targetYear.openGateDay>=cursorOpen)throw std::runtime_error("corridor prior non progreditur");
        cursorOpen=prior.targetYear.openGateDay;
        before.push_back(std::move(prior));
        if(before.size()+1>PairTombEnginePort::HOT_ALMANAC_LIMIT)throw std::runtime_error("nimis multi anni priores pro sepulcro corridoris");
    }
    std::reverse(before.begin(),before.end());

    const auto centerClose=center.targetYear.closeGateDay;
    std::vector<pastafari::Stage54IntegrationReport> after;
    auto cursorClose=centerClose;
    while(cursorClose<high){
        const pastafari::Integer nextTarget=cursorClose+1;
        auto next=manager.executeFinalIntegrationStage56(c,nextTarget);
        if(!next.ready||!next.exactFiveFieldReturn)throw std::runtime_error("annus posterior corridoris non paratus est");
        if(next.targetYear.openGateDay!=cursorClose)throw std::runtime_error("continuitas posterior corridoris fracta est");
        if(next.targetYear.closeGateDay<=cursorClose)throw std::runtime_error("corridor posterior non progreditur");
        cursorClose=next.targetYear.closeGateDay;
        after.push_back(std::move(next));
        if(before.size()+1+after.size()>PairTombEnginePort::HOT_ALMANAC_LIMIT)throw std::runtime_error("nimis multi anni pro sepulcro corridoris");
    }

    std::vector<pastafari::Stage54IntegrationReport> all;
    all.reserve(before.size()+1+after.size());
    for(auto&report:before)all.push_back(std::move(report));
    all.push_back(std::move(center));
    for(auto&report:after)all.push_back(std::move(report));
    return all;
}
}

int main(int argc,char**argv){
    try{
        if(argc!=4){std::cerr<<"usus: generate_hot_cache_seed CALCULATION_DAY PAIR_OUTPUT ALMANAC_OUTPUT\n";return 2;}
        const std::int64_t base=parseDay(argv[1]);
        if(base>std::numeric_limits<std::int64_t>::max()-2)throw std::runtime_error("dies nimis prope terminum int64 est");
        CeleritasEnginePort engine;
        const std::vector<std::pair<std::int64_t,std::int64_t>> pairs{{base,base},{base,base+1},{base+1,base+1},{base+1,base+2}};
        std::vector<CanonicalPastafariDate> values;values.reserve(pairs.size());
        for(const auto&[c,t]:pairs)values.push_back(engine.calculate(Integer{c},Integer{t}));

        std::ofstream pairOut(argv[2]);if(!pairOut)throw std::runtime_error("pair output aperiri non potest");
        pairOut<<"// PASTAFARI_HOT_SEED_BASE_DAY="<<base<<"\n// PASTAFARI_HOT_SEED_GENERATION=2\n// Quattuor sepulcra exacta; corridor annorum infra separatim vivit.\n";
        for(std::size_t i=0;i<pairs.size();++i)emitPair(pairOut,pairs[i].first,pairs[i].second,values[i]);
        pairOut.close();

        auto corridor0=buildCorridor(base);
        auto corridor1=buildCorridor(base+1);
        const std::size_t total=corridor0.size()+corridor1.size();
        if(total>PairTombEnginePort::HOT_ALMANAC_LIMIT)throw std::runtime_error("corridor duorum dierum capacitatem Pair Tomb excedit");

        const auto center0=std::find_if(corridor0.begin(),corridor0.end(),[&](const auto&r){return r.targetYear.openGateDay<pastafari::Integer{base}&&pastafari::Integer{base}<=r.targetYear.closeGateDay;});
        const auto center1=std::find_if(corridor1.begin(),corridor1.end(),[&](const auto&r){return r.targetYear.openGateDay<pastafari::Integer{base+1}&&pastafari::Integer{base+1}<=r.targetYear.closeGateDay;});
        if(center0==corridor0.end()||center1==corridor1.end())throw std::runtime_error("centrum corridoris post collectionem amissum est");
        if(!same(canonicalFromFive(center0->result),values[0]))throw std::runtime_error("corridor c cum calendario productionis discrepat");
        if(!same(canonicalFromFive(center1->result),values[2]))throw std::runtime_error("corridor c+1 cum calendario productionis discrepat");

        std::ofstream almOut(argv[3]);if(!almOut)throw std::runtime_error("almanac output aperiri non potest");
        almOut<<"// PASTAFARI_HOT_ALMANAC_BASE_DAY="<<base<<"\n"
              <<"// PASTAFARI_HOT_ALMANAC_GENERATION=2\n"
              <<"// PASTAFARI_HOT_ALMANAC_CORRIDOR_BEHIND_DAYS="<<HOT_CORRIDOR_BEHIND_DAYS<<"\n"
              <<"// PASTAFARI_HOT_ALMANAC_CORRIDOR_AHEAD_DAYS="<<HOT_CORRIDOR_AHEAD_DAYS<<"\n"
              <<"// PASTAFARI_HOT_ALMANAC_COUNT="<<total<<"\n"
              <<"// Duo calculationDays, c et c+1; omnes anni qui corridor [-10000,+30000] tangunt.\n";
        int ordinal=0;
        for(const auto&report:corridor0)emitAlmanac(almOut,ordinal++,base,report);
        for(const auto&report:corridor1)emitAlmanac(almOut,ordinal++,base+1,report);
        almOut.close();
        std::cerr<<"HOT_CACHE_SEED_GENERATED BASE="<<base<<" ALMANACS="<<total<<" BEHIND="<<HOT_CORRIDOR_BEHIND_DAYS<<" AHEAD="<<HOT_CORRIDOR_AHEAD_DAYS<<"\n";
        return 0;
    }catch(const std::exception&e){std::cerr<<"fatal: "<<e.what()<<'\n';return 1;}
}
