#include "pastafari/http_api/venus_boundary.hpp"
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <mutex>
#include <sstream>
#include <tuple>

namespace pastafari::http_api {
namespace {
constexpr double J2000_JD=2451545.0, DAYS_PER_CENTURY=36525.0, UNIX_EPOCH_JD=2440587.5;
constexpr double MS_PER_DAY=86400000.0, AU_KM=149597870.7, EARTH_R_KM=6378.14;
constexpr double PI=3.141592653589793238462643383279502884, DEG=PI/180.0, ARCSEC=DEG/3600.0;
constexpr double LIGHT_SECONDS_AU=499.004783836;
struct Pair{double base,rate;};
struct Elements{Pair a,e,I,L,peri,node;};
constexpr Elements VENUS{{0.72332102,-0.00000026},{0.00676399,-0.00005107},{3.39777545,0.00043494},{181.97970850,58517.81560260},{131.76755713,0.05679648},{76.67261496,-0.27274174}};
constexpr Elements EMB{{1.00000018,-0.00000003},{0.01673163,-0.00003661},{-0.00054346,-0.01337178},{100.46691572,35999.37306329},{102.93005885,0.31795260},{-5.11260389,-0.24123856}};
struct Vec{double x,y,z;}; struct Eq{double ra,dec,distance;};

double wrap180(double v){ v=std::fmod(v+180.0,360.0); if(v<0)v+=360.0; return v-180.0; }
double wrapPi(double v){ v=std::fmod(v+PI,2*PI); if(v<0)v+=2*PI; return v-PI; }
double wrap2pi(double v){v=std::fmod(v,2*PI);if(v<0)v+=2*PI;return v;}
double at(Pair p,double T){return p.base+p.rate*T;}
Vec helio(const Elements& e,double jd){
    double T=(jd-J2000_JD)/DAYS_PER_CENTURY, year=2000.0+100.0*T;
    if(year < -3000.0 || year > 3000.0) throw AstronomyError("modelum termini diei Veneris solum inter annos 3000 a.C.n. et 3000 p.C.n. definitum est");
    double a=at(e.a,T), ecc=at(e.e,T), inc=at(e.I,T)*DEG;
    double meanL=at(e.L,T), peri=at(e.peri,T), nodeD=at(e.node,T), node=nodeD*DEG;
    double arg=(peri-nodeD)*DEG, M=wrap180(meanL-peri), eccDeg=(180.0/PI)*ecc;
    double Edeg=M+eccDeg*std::sin(M*DEG);
    for(int i=0;i<12;i++){
        double E=Edeg*DEG, dm=M-(Edeg-eccDeg*std::sin(E)), de=dm/(1-ecc*std::cos(E));
        Edeg+=de; if(std::abs(de)<=1e-9) break;
    }
    double E=Edeg*DEG,xp=a*(std::cos(E)-ecc),yp=a*std::sqrt(1-ecc*ecc)*std::sin(E);
    double cw=std::cos(arg),sw=std::sin(arg),co=std::cos(node),so=std::sin(node),ci=std::cos(inc),si=std::sin(inc);
    return {(cw*co-sw*so*ci)*xp+(-sw*co-cw*so*ci)*yp,
            (cw*so+sw*co*ci)*xp+(-sw*so+cw*co*ci)*yp,
            sw*si*xp+cw*si*yp};
}
Vec sub(Vec a,Vec b){return{a.x-b.x,a.y-b.y,a.z-b.z};}
double len(Vec v){return std::hypot(v.x,v.y,v.z);}
std::pair<double,double> precess(double ra,double dec,double jd){
    double T=(jd-J2000_JD)/DAYS_PER_CENTURY;
    double zeta=(2306.2181*T+0.30188*T*T+0.017998*T*T*T)*ARCSEC;
    double z=(2306.2181*T+1.09468*T*T+0.018203*T*T*T)*ARCSEC;
    double th=(2004.3109*T-0.42665*T*T-0.041833*T*T*T)*ARCSEC;
    double A=std::cos(dec)*std::sin(ra+zeta);
    double B=std::cos(th)*std::cos(dec)*std::cos(ra+zeta)-std::sin(th)*std::sin(dec);
    double C=std::sin(th)*std::cos(dec)*std::cos(ra+zeta)+std::cos(th)*std::sin(dec);
    return {wrap2pi(std::atan2(A,B)+z),std::asin(std::clamp(C,-1.0,1.0))};
}
Eq venusEq(double jd){
    Vec earth=helio(EMB,jd), venus=helio(VENUS,jd);
    for(int i=0;i<2;i++){Vec rel=sub(venus,earth);double lightDays=len(rel)*LIGHT_SECONDS_AU/86400.0;venus=helio(VENUS,jd-lightDays);}
    Vec rel=sub(venus,earth);double dist=len(rel),obl=23.43928*DEG;
    double x=rel.x,y=std::cos(obl)*rel.y-std::sin(obl)*rel.z,z=std::sin(obl)*rel.y+std::cos(obl)*rel.z;
    double ra=wrap2pi(std::atan2(y,x)),dec=std::atan2(z,std::hypot(x,y)); auto [ra2,dec2]=precess(ra,dec,jd);return{ra2,dec2,dist};
}
double gmst(double jd){double T=(jd-J2000_JD)/DAYS_PER_CENTURY;double d=280.46061837+360.98564736629*(jd-J2000_JD)+0.000387933*T*T-T*T*T/38710000.0;d=std::fmod(d,360.0);if(d<0)d+=360;return d*DEG;}
double hourAngle(double jd,Observer o){
    Eq q=venusEq(jd);double local=gmst(jd)+o.longitude*DEG,H=wrap2pi(local-q.ra),phi=o.latitude*DEG;
    double hp=std::asin(EARTH_R_KM/(q.distance*AU_KM)),u=std::atan(0.99664719*std::tan(phi)),hr=o.elevationM/(EARTH_R_KM*1000.0);
    double rhoSin=0.99664719*std::sin(u)+hr*std::sin(phi),rhoCos=std::cos(u)+hr*std::cos(phi);
    (void)rhoSin; // servatur ad fidelitatem et documentum; delta-alpha rhoCos adhibet.
    double dra=std::atan2(-rhoCos*std::sin(hp)*std::sin(H),std::cos(q.dec)-rhoCos*std::sin(hp)*std::cos(H));
    return wrap2pi(H-dra);
}
double phase(double jd,Observer o){return wrapPi(hourAngle(jd,o)-PI);}
std::string key(const Integer& j,Observer o){std::ostringstream s;s<<j<<'|'<<o.latitude<<'|'<<o.longitude<<'|'<<o.elevationM;return s.str();}
std::map<std::string,VenusBoundary> cache; std::mutex cacheMutex;
}

VenusBoundary boundaryForDayJdn(const Integer& dayJdn,Observer observer){
    std::string k=key(dayJdn,observer); {std::lock_guard<std::mutex> l(cacheMutex);auto it=cache.find(k);if(it!=cache.end())return it->second;}
    double d;
    try{d=dayJdn.convert_to<double>();}catch(...){throw AstronomyError("JDN diei extra spatium numericum est");}
    if(!std::isfinite(d)||std::abs(d)>9007199254740991.0) throw AstronomyError("JDN diei extra spatium numericum tutum est");
    double seed=d-0.5-observer.longitude/360.0, half=0.45,step=15.0/1440.0;
    struct Bracket{double l,r,lp,rp;}; std::vector<std::pair<double,double>> points; std::vector<Bracket> bs;
    for(double jd=seed-half;jd<=seed+half+1e-12;jd+=step)points.push_back({jd,phase(jd,observer)});
    for(std::size_t i=1;i<points.size();++i){auto [lj,lp]=points[i-1];auto [rj,rp]=points[i];bool smooth=lp==0||rp==0||(lp*rp<0&&std::abs(lp-rp)<PI);if(smooth)bs.push_back({lj,rj,lp,rp});}
    if(bs.empty())throw AstronomyError("transitus inferior Veneris includi non potuit");
    std::sort(bs.begin(),bs.end(),[&](auto&a,auto&b){return std::abs((a.l+a.r)/2-seed)<std::abs((b.l+b.r)/2-seed);});
    auto b=bs.front();
    for(int i=0;i<60&&(b.r-b.l)*86400.0>0.05;++i){double mid=(b.l+b.r)/2,mp=phase(mid,observer);if(b.lp==0||b.lp*mp<=0){b.r=mid;b.rp=mp;}else{b.l=mid;b.lp=mp;}}
    VenusBoundary result{dayJdn,(b.l+b.r)/2,observer,VENUS_BOUNDARY_MODEL_VERSION};
    {std::lock_guard<std::mutex> l(cacheMutex); if(cache.size()>=96)cache.erase(cache.begin());cache[k]=result;}
    return result;
}
CalculationDayResolution currentDayAtUnixMilliseconds(std::int64_t ms,Observer observer){
    double jd=static_cast<double>(ms)/MS_PER_DAY+UNIX_EPOCH_JD;
    Integer day=static_cast<long long>(std::floor(jd+0.5+observer.longitude/360.0));
    auto prev=boundaryForDayJdn(day,observer);if(jd<prev.jd){--day;prev=boundaryForDayJdn(day,observer);}auto next=boundaryForDayJdn(day+1,observer);if(jd>=next.jd){++day;prev=next;next=boundaryForDayJdn(day+1,observer);}
    return{day,jdnToEngineDay(day),prev,next,observer,VENUS_BOUNDARY_MODEL_VERSION};
}
CalculationDayResolution currentDayAt(std::chrono::system_clock::time_point tp,Observer observer){
    auto ms=std::chrono::duration_cast<std::chrono::milliseconds>(tp.time_since_epoch()).count();return currentDayAtUnixMilliseconds(ms,observer);
}
} // namespace pastafari::http_api
