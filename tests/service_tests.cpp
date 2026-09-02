#include "pastafari/http_api/service.hpp"
#include <cassert>
#include <iostream>
using namespace pastafari::http_api;
struct Fake:EnginePort{CanonicalPastafariDate calculate(const Integer&c,const Integer&t)override{return{c+t,1,"aes",1,1,"lutum",1};}};
int main(){
 Fake f;CalendarService s(f);CalculationSpec explicitDay{CalculationMode::EngineDay,"42"};
 auto r=s.calculate(TargetSpec{"2026-09-02","gregorian","auto"},explicitDay,0);assert(r.calculation.engineDay==42);assert(r.target.engineDay==739861);assert(r.date.year==739903);
 auto ms=parseRfc3339Milliseconds("1970-01-01T03:30:00+03:30");assert(ms==0);assert(formatRfc3339Milliseconds(0)=="1970-01-01T00:00:00.000Z");
 auto implicit=s.calculate(TargetSpec{"1970-01-01"},CalculationSpec{},0);assert(implicit.calculation.source=="request-instant");assert(implicit.calculation.engineDay==719163);assert(implicit.language=="la");
 auto latin=s.calculate(TargetSpec{"2026-09-02"},explicitDay,0,"la");assert(latin.language=="la");assert(latin.date.cutletName=="aes");
 bool unsupported=false;try{(void)s.calculate(TargetSpec{"2026-09-02"},explicitDay,0,"he");}catch(const DateError&e){unsupported=e.code=="LANGUAGE_NOT_SUPPORTED";}assert(unsupported);
 std::cout<<"SERVICE_TESTS=PASS\n";
}
