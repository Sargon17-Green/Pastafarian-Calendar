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
 auto e=tomb.calculate(111,112);assert(base.calls==4&&e.year==5000&&e.dayInCutlet==442&&e.dayInMonth==27);assert(tomb.metrics().hits==1&&tomb.metrics().misses==0);
 std::cout<<"PAIR_TOMB_TESTS=PASS\n";}
