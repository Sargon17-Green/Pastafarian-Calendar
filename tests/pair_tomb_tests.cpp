#include "pastafari/http_api/pair_tomb.hpp"
#include <cassert>
#include <iostream>
using namespace pastafari::http_api;
struct Counting:EnginePort{int calls=0;CanonicalPastafariDate calculate(const Integer&c,const Integer&t)override{++calls;return{c+t,1,"aes",1,1,"lutum",1};}};
int main(){Counting base;PairTombEnginePort tomb(base);tomb.clear();
 auto a=tomb.calculate(10,20);assert(base.calls==1&&a.year==30);auto b=tomb.calculate(10,20);assert(base.calls==1&&b.year==30);assert(tomb.metrics().hits==1&&tomb.metrics().misses==1);
 tomb.setEnabled(false);auto c=tomb.calculate(10,20);assert(c.year==30&&base.calls==2&&tomb.metrics().bypasses==1);tomb.setEnabled(true);
 Integer huge=Integer{1}<<100;auto d=tomb.calculate(huge,20);assert(d.year==huge+20&&base.calls==3&&tomb.metrics().bypasses==2);
 tomb.clear();assert(tomb.metrics().hits==0);(void)tomb.calculate(10,20);assert(base.calls==4);
 tomb.clear();CanonicalPastafariDate hot{5000,1,"aes",442,37,"tempestas",27};assert(tomb.buryHotSeedDiagnostic(111,112,hot));assert(tomb.generatedSeededCount()==1);
 auto e=tomb.calculate(111,112);assert(base.calls==4&&e.year==5000&&e.dayInCutlet==442&&e.dayInMonth==27);assert(tomb.metrics().hits==1&&tomb.metrics().hotSeedHits==1&&tomb.metrics().misses==0);
 tomb.clear();
 std::vector<PairTombEnginePort::AlmanacCutlet> cutlets{{1,1001,1003},{5,1004,1006}};
 std::vector<int> weaving{1,2,1,2,2,1};
 std::vector<std::size_t> monthNames{47,8};
 assert(tomb.buryHotAlmanacDiagnostic(42,5000,1000,1006,cutlets,weaving,monthNames));
 assert(tomb.generatedAlmanacCount()==1);

 // Cicatrix corridoris: alius annus eodem calculationDay non priorem devorat.
 std::vector<PairTombEnginePort::AlmanacCutlet> priorCutlets{{1,995,1000}};
 std::vector<int> priorWeaving{1,1,1,1,1,1};
 std::vector<std::size_t> priorMonthNames{1};
 assert(tomb.buryHotAlmanacDiagnostic(42,4999,994,1000,priorCutlets,priorWeaving,priorMonthNames));
 assert(tomb.generatedAlmanacCount()==2);
 auto prior=tomb.calculate(42,999);assert(base.calls==4&&prior.year==4999);assert(tomb.metrics().almanacHits==1);

 auto f=tomb.calculate(42,1005);assert(base.calls==4);assert(f.year==5000&&f.cutletIndex==5&&f.cutletName=="cogitatio");assert(f.dayInCutlet==2);assert(f.monthIndex==8&&f.monthName=="Carsumav"&&f.dayInMonth==3);assert(tomb.metrics().almanacHits==2&&tomb.metrics().misses==0);
 auto g=tomb.calculate(42,1005);assert(base.calls==4&&g.dayInMonth==3);assert(tomb.metrics().directMappedHits==1); // prima resurrectio almanaci tomb exactum nutrit.
 auto h=tomb.calculate(43,1005);assert(base.calls==5&&h.year==1048);assert(tomb.metrics().misses==1);
 auto i=tomb.calculate(42,1000);assert(base.calls==5&&i.year==4999); // porta aperiens anni 5000 ad annum priorem nunc ex almanaco corridoris pertinet.
 std::cout<<"PAIR_TOMB_TESTS=PASS\n";}
