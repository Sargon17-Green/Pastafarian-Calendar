#include "pastafari/http_api/http_protocol.hpp"
#include <cassert>
#include <iostream>
using namespace pastafari::http_api;
struct Fake:EnginePort{CanonicalPastafariDate calculate(const Integer&,const Integer&)override{return{5000,7,"Palguras",3,28,"Ninive",4};}};
int main(){Fake f;CalendarService s(f);HttpProtocol p(s);
 auto g=p.handle("GET","/v1/date?date=2026-09-02&calculation_day=42&language=la","","",0);assert(g.status==200);assert(g.body.find("\"engineDay\":\"42\"")!=std::string::npos);assert(g.body.find("Palguras")!=std::string::npos);assert(g.body.find("\"language\":\"la\"")!=std::string::npos);
 auto a=p.handle("GET","/v1/date?date=03%2F04%2F2026&calculation_day=42","","",0);assert(a.status==422);assert(a.body.find("AMBIGUOUS_DATE")!=std::string::npos);
 auto post=p.handle("POST","/v1/date","application/json",R"({"target":{"calendar":"julian","value":"1917-10-25"},"calculation":{"mode":"engine-day","value":"42"}})",0);assert(post.status==200);
 auto type=p.handle("POST","/v1/date","application/json",R"({"target":123})",0);assert(type.status==400);
 auto num=p.handle("POST","/v1/date","application/json",R"({"target":"2026-09-02","calculation":{"mode":"engine-day","value":42}})",0);assert(num.status==400);
 auto meta=p.handle("GET","/v1/meta","","",0);assert(meta.status==200);assert(meta.body.find("venus-lower-transit-jpl-approx-1")!=std::string::npos);assert(meta.body.find("\"defaultLanguage\":\"la\"")!=std::string::npos);assert(meta.body.find("\"languages\":[\"la\"]")!=std::string::npos);
 auto unsupported=p.handle("GET","/v1/date?date=2026-09-02&calculation_day=42&language=he","","",0);assert(unsupported.status==422);assert(unsupported.body.find("LANGUAGE_NOT_SUPPORTED")!=std::string::npos);
 auto batch=p.handle("POST","/v1/dates","application/json",R"({"targets":["2026-09-02","2026-09-03"],"language":"la","calculation":{"mode":"engine-day","value":"42"}})",0);assert(batch.status==200);assert(batch.body.find("\"language\":\"la\"")!=std::string::npos);
 std::cout<<"HTTP_PROTOCOL_TESTS=PASS\n";}
