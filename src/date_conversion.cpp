#include "pastafari/http_api/date_conversion.hpp"
#include <algorithm>
#include <array>
#include <cctype>
#include <iomanip>
#include <set>
#include <sstream>

namespace pastafari::http_api {
namespace {
bool gregLeap(const Integer& y) { return mod(y,4)==0 && (mod(y,100)!=0 || mod(y,400)==0); }
bool julLeap(const Integer& y) { return mod(y,4)==0; }
int civilMonthDays(const Integer& y, int m, bool greg) {
    if (m < 1 || m > 12) throw DateError("INVALID_DATE","mensis debet esse inter 1 et 12");
    if (m == 2) return (greg ? gregLeap(y) : julLeap(y)) ? 29 : 28;
    return (m==4||m==6||m==9||m==11) ? 30 : 31;
}
void validateCivil(const CivilDate& d, bool greg) {
    if (d.day < 1 || d.day > civilMonthDays(d.year,d.month,greg)) throw DateError("INVALID_DATE","dies extra mensem electum est");
}

bool digitsOnly(std::string_view s) {
    if (s.empty()) return false;
    for (char c : s) if (!std::isdigit(static_cast<unsigned char>(c))) return false;
    return true;
}

bool signedDigits(std::string_view s, std::size_t minDigits) {
    if (s.empty()) return false;
    std::size_t i = (s.front()=='+' || s.front()=='-') ? 1 : 0;
    if (s.size() - i < minDigits) return false;
    return digitsOnly(s.substr(i));
}

Integer parseLooseYear(std::string_view s) {
    if (!signedDigits(s,1)) throw DateError("INVALID_DATE","annus invalidus est");
    const std::size_t digits = s.size() - ((s.front()=='+'||s.front()=='-')?1:0);
    if (digits <= 2) throw DateError("AMBIGUOUS_YEAR","anni duarum notarum consilium saeculi explicitum requirunt");
    return Integer{std::string(s)};
}
int toSmall(std::string_view s) {
    if (!digitsOnly(s)) throw DateError("INVALID_DATE","campus numericus diei invalidus est");
    try { return std::stoi(std::string(s)); }
    catch (...) { throw DateError("INVALID_DATE","campus numericus diei invalidus est"); }
}

bool hebrewLeap(const Integer& y) { return mod(7*y+1,19)<7; }
Integer hebrewDelay1(const Integer& year) {
    Integer months=floorDiv(235*year-234,19), parts=12084+13753*months;
    Integer day=29*months+floorDiv(parts,25920);
    if (mod(3*(day+1),7)<3) ++day;
    return day;
}
Integer hebrewDelay2(const Integer& y) {
    Integer last=hebrewDelay1(y-1), present=hebrewDelay1(y), next=hebrewDelay1(y+1);
    if(next-present==356) return 2;
    if(present-last==382) return 1;
    return 0;
}
Integer hebrewNewYear(const Integer& y) { return Integer{347996}+hebrewDelay1(y)+hebrewDelay2(y)+2; }
int hebrewYearDays(const Integer& y) { return (hebrewNewYear(y+1)-hebrewNewYear(y)).convert_to<int>(); }
int hebrewMonthDays(const Integer& y,int m) {
    if(m<1||m>13) return 0;
    if(m==2||m==4||m==6||m==10||m==13) return 29;
    if(m==12 && !hebrewLeap(y)) return 29;
    int len=hebrewYearDays(y);
    if(m==8 && len%10!=5) return 29;
    if(m==9 && len%10==3) return 29;
    return 30;
}

std::string lowerAscii(std::string x){ for(char&c:x)c=static_cast<char>(std::tolower(static_cast<unsigned char>(c))); return x; }
int englishMonth(std::string name){
    name=lowerAscii(name); if(name.size()>3) name=name.substr(0,3);
    static const std::array<std::string,12> n{"jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"};
    for(int i=0;i<12;++i) { if(name==n[i]) return i+1; }
    return 0;
}
bool asciiLetters(std::string_view s) {
    if (s.empty()) return false;
    for (char c : s) if (!std::isalpha(static_cast<unsigned char>(c))) return false;
    return true;
}

int weekdayMonday1(const Integer& jdn){ return (mod(jdn,7)+1).convert_to<int>(); }
int isoWeeksInYear(const Integer& year){ int w=weekdayMonday1(gregorianToJdn({year,1,1})); return (w==4 || (w==3 && gregLeap(year))) ? 53 : 52; }
CivilDate gregorianOrdinal(const Integer& y,int ordinal){
    int max=gregLeap(y)?366:365; if(ordinal<1||ordinal>max)throw DateError("INVALID_DATE","dies ordinalis extra annum electum est");
    return jdnToGregorian(gregorianToJdn({y,1,1})+ordinal-1);
}
CivilDate gregorianIsoWeek(const Integer& y,int week,int weekday){
    if(weekday<1||weekday>7||week<1||week>isoWeeksInYear(y))throw DateError("INVALID_DATE","dies hebdomadalis ISO extra annum electum est");
    Integer jan4=gregorianToJdn({y,1,4}); Integer monday=jan4-(weekdayMonday1(jan4)-1);
    return jdnToGregorian(monday+7*(week-1)+(weekday-1));
}

bool islamicLeap(const Integer& y){ return mod(11*y+14,30)<11; }
int islamicMonthDays(const Integer& y,int m){ if(m<1||m>12)return 0; if(m==12)return islamicLeap(y)?30:29; return m%2?30:29; }

bool isDateSeparator(char c) { return c=='-' || c=='/' || c=='.'; }

bool splitYmdSeparated(std::string_view s, std::string_view& y, std::string_view& m, std::string_view& d) {
    std::size_t start = (s.size() && (s[0]=='+' || s[0]=='-')) ? 1 : 0;
    std::size_t p1 = std::string_view::npos;
    for (std::size_t i=start;i<s.size();++i) if (isDateSeparator(s[i])) { p1=i; break; }
    if (p1==std::string_view::npos) return false;
    std::size_t p2 = std::string_view::npos;
    for (std::size_t i=p1+1;i<s.size();++i) if (isDateSeparator(s[i])) { p2=i; break; }
    if (p2==std::string_view::npos) return false;
    for (std::size_t i=p2+1;i<s.size();++i) if (isDateSeparator(s[i])) return false;
    y=s.substr(0,p1); m=s.substr(p1+1,p2-p1-1); d=s.substr(p2+1);
    return signedDigits(y,3) && digitsOnly(m) && m.size()<=2 && digitsOnly(d) && d.size()<=2;
}

bool splitDmyMdySeparated(std::string_view s, std::string_view& a, std::string_view& b, std::string_view& y) {
    std::size_t p1=std::string_view::npos;
    for(std::size_t i=0;i<s.size();++i) if(isDateSeparator(s[i])) { p1=i; break; }
    if(p1==std::string_view::npos) return false;
    std::size_t p2=std::string_view::npos;
    for(std::size_t i=p1+1;i<s.size();++i) if(isDateSeparator(s[i])) { p2=i; break; }
    if(p2==std::string_view::npos) return false;
    a=s.substr(0,p1); b=s.substr(p1+1,p2-p1-1); y=s.substr(p2+1);
    return digitsOnly(a) && a.size()<=2 && digitsOnly(b) && b.size()<=2 && signedDigits(y,3);
}

bool splitCompactYmd(std::string_view s, std::string_view& y, std::string_view& m, std::string_view& d) {
    const std::size_t sign = (s.size() && (s[0]=='+' || s[0]=='-')) ? 1 : 0;
    if (s.size() < sign + 8 || !digitsOnly(s.substr(sign))) return false;
    const std::size_t yEnd = s.size() - 4;
    if (yEnd - sign < 4) return false;
    y=s.substr(0,yEnd); m=s.substr(yEnd,2); d=s.substr(yEnd+2,2);
    return true;
}

std::vector<std::string> wordsFromMonthDate(std::string s) {
    for (char& c : s) if (c==',') c=' ';
    std::istringstream in(s);
    std::vector<std::string> words;
    std::string w;
    while (in >> w) words.push_back(w);
    return words;
}

std::vector<std::pair<std::string,CivilDate>> parseNumeric(std::string_view s, std::string_view format) {
    std::vector<std::pair<std::string,CivilDate>> out;
    auto allowed=[&](std::string_view f){ return format=="auto"||format==f; };
    auto push=[&](std::string f,std::string_view ys,std::string_view ms,std::string_view ds){
        out.push_back({std::move(f), CivilDate{parseLooseYear(ys),toSmall(ms),toSmall(ds)}});
    };

    std::string_view y,m,d;
    if (allowed("ymd") && splitYmdSeparated(s,y,m,d)) push("ymd",y,m,d);
    if (allowed("ymd") && splitCompactYmd(s,y,m,d)) push("ymd",y,m,d);

    std::string_view a,b;
    if (splitDmyMdySeparated(s,a,b,y)) {
        if (allowed("dmy")) push("dmy",y,b,a);
        if (allowed("mdy")) push("mdy",y,a,b);
    }
    return out;
}
} // namespace

Integer gregorianToJdn(const CivilDate& d) {
    validateCivil(d,true);
    Integer a=floorDiv(14-Integer{d.month},12), y=d.year+4800-a, m=Integer{d.month}+12*a-3;
    return d.day+floorDiv(153*m+2,5)+365*y+floorDiv(y,4)-floorDiv(y,100)+floorDiv(y,400)-32045;
}
Integer julianToJdn(const CivilDate& d) {
    validateCivil(d,false);
    Integer a=floorDiv(14-Integer{d.month},12), y=d.year+4800-a, m=Integer{d.month}+12*a-3;
    return d.day+floorDiv(153*m+2,5)+365*y+floorDiv(y,4)-32083;
}
Integer hebrewToJdn(const CivilDate& d) {
    int last=hebrewLeap(d.year)?13:12;
    if(d.month<1||d.month>last||d.day<1||d.day>hebrewMonthDays(d.year,d.month)) throw DateError("INVALID_DATE","dies Hebraicus extra mensem aut annum electum est");
    Integer r=hebrewNewYear(d.year)+(d.day-1);
    if(d.month<7){ for(int c=7;c<=last;++c)r+=hebrewMonthDays(d.year,c); for(int c=1;c<d.month;++c)r+=hebrewMonthDays(d.year,c); }
    else for(int c=7;c<d.month;++c)r+=hebrewMonthDays(d.year,c);
    return r;
}
Integer islamicCivilToJdn(const CivilDate& d) {
    if(d.month<1||d.month>12||d.day<1||d.day>islamicMonthDays(d.year,d.month)) throw DateError("INVALID_DATE","dies islamicus civilis extra mensem electum est");
    Integer preceding=floorDiv(59*Integer{d.month-1}+1,2);
    return Integer{1948439}+d.day+preceding+354*(d.year-1)+floorDiv(3+11*d.year,30);
}
CivilDate jdnToGregorian(const Integer& jdn) {
    Integer a=jdn+32044,b=floorDiv(4*a+3,146097),c=a-floorDiv(146097*b,4),d=floorDiv(4*c+3,1461),e=c-floorDiv(1461*d,4),m=floorDiv(5*e+2,153);
    return {100*b+d-4800+floorDiv(m,10),(m+3-12*floorDiv(m,10)).convert_to<int>(),(e-floorDiv(153*m+2,5)+1).convert_to<int>()};
}
std::string normalizeYmd(const CivilDate& d) {
    std::ostringstream os; os<<d.year<<'-'<<std::setw(2)<<std::setfill('0')<<d.month<<'-'<<std::setw(2)<<d.day; return os.str();
}
std::vector<std::string> supportedCalendars(){ return {"gregorian","julian","hebrew","islamic-civil","engine-day"}; }

ResolvedDate resolveDate(std::string_view valueSv,std::string_view calendar,std::string_view format) {
    std::string value(valueSv);
    if(calendar=="engine-day") {
        if(format!="auto"&&format!="canonical-decimal") throw DateError("UNSUPPORTED_FORMAT","engine-day solum canonical-decimal accipit");
        Integer day;
        try { day=parseCanonicalDecimal(value); } catch(const std::exception&) { throw DateError("INVALID_INTEGER","engine-day debet esse decimalis canonicus"); }
        return {value,"engine-day","canonical-decimal",decimal(day),engineDayToJdn(day),day};
    }
    if(calendar!="gregorian"&&calendar!="julian"&&calendar!="hebrew"&&calendar!="islamic-civil") {
        if(calendar=="islamic") throw DateError("CALENDAR_VARIANT_REQUIRED","varietatem calendarii islamici explicitam adhibe, ut islamic-civil");
        throw DateError("UNKNOWN_CALENDAR","calendarium ignotum est");
    }

    std::vector<ParseCandidate> special;
    if(calendar=="gregorian") {
        try {
            if(format=="auto"||format=="iso-week") {
                const std::string lower=lowerAscii(value);
                const std::size_t p=lower.rfind("-w");
                if(p!=std::string::npos && p>0 && signedDigits(std::string_view(value).substr(0,p),3)) {
                    const std::string_view tail=std::string_view(value).substr(p+2);
                    if(tail.size()==4 && digitsOnly(tail.substr(0,2)) && tail[2]=='-' && digitsOnly(tail.substr(3,1))) {
                        CivilDate d=gregorianIsoWeek(parseLooseYear(std::string_view(value).substr(0,p)),toSmall(tail.substr(0,2)),toSmall(tail.substr(3,1)));
                        Integer j=gregorianToJdn(d); special.push_back({"iso-week",d,j,jdnToEngineDay(j)});
                    }
                }
            }
            if(format=="auto"||format=="ordinal") {
                const std::size_t p=value.rfind('-');
                if(p!=std::string::npos && p>0) {
                    const std::string_view ys=std::string_view(value).substr(0,p);
                    const std::string_view ord=std::string_view(value).substr(p+1);
                    if(signedDigits(ys,3) && ord.size()==3 && digitsOnly(ord)) {
                        CivilDate d=gregorianOrdinal(parseLooseYear(ys),toSmall(ord)); Integer j=gregorianToJdn(d);
                        special.push_back({"ordinal",d,j,jdnToEngineDay(j)});
                    }
                }
            }
            if(format=="auto"||format=="d-month-y") {
                const auto w=wordsFromMonthDate(value);
                if(w.size()==3 && digitsOnly(w[0]) && w[0].size()<=2 && asciiLetters(w[1]) && signedDigits(w[2],3)) {
                    int mo=englishMonth(w[1]);
                    if(mo){ CivilDate d{parseLooseYear(w[2]),mo,toSmall(w[0])}; Integer j=gregorianToJdn(d); special.push_back({"d-month-y",d,j,jdnToEngineDay(j)}); }
                }
            }
            if(format=="auto"||format=="month-d-y") {
                const auto w=wordsFromMonthDate(value);
                if(w.size()==3 && asciiLetters(w[0]) && digitsOnly(w[1]) && w[1].size()<=2 && signedDigits(w[2],3)) {
                    int mo=englishMonth(w[0]);
                    if(mo){ CivilDate d{parseLooseYear(w[2]),mo,toSmall(w[1])}; Integer j=gregorianToJdn(d); special.push_back({"month-d-y",d,j,jdnToEngineDay(j)}); }
                }
            }
        } catch(const DateError&) {}
    }

    auto raw=parseNumeric(value,format);
    if(raw.empty() && special.empty()) throw DateError("UNRECOGNIZED_DATE","forma diei non agnita est");
    std::vector<ParseCandidate> valid=std::move(special);
    for(auto& [f,d]:raw) {
        try {
            Integer j;
            if(calendar=="gregorian") j=gregorianToJdn(d);
            else if(calendar=="julian") j=julianToJdn(d);
            else if(calendar=="hebrew") j=hebrewToJdn(d);
            else j=islamicCivilToJdn(d);
            valid.push_back({f,d,j,jdnToEngineDay(j)});
        } catch(const DateError&) {}
    }
    if(valid.empty()) throw DateError("INVALID_DATE","nulla interpretatio valida diei inventa est");
    std::set<std::string> distinct;
    for(auto& c:valid) distinct.insert(decimal(c.engineDay));
    if(distinct.size()>1) throw DateError("AMBIGUOUS_DATE","interpretationes validae ad dies canonicos diversos perveniunt");
    auto& c=valid.front();
    return {value,std::string(calendar),c.format,normalizeYmd(c.date),c.jdn,c.engineDay};
}
} // namespace pastafari::http_api
