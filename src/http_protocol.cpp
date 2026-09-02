#include "pastafari/http_api/http_protocol.hpp"
#include "pastafari/http_api/strict_json.hpp"
#include <algorithm>
#include <charconv>
#include <cctype>
#include <iomanip>
#include <sstream>
#include <stdexcept>
namespace pastafari::http_api {
namespace {
using json::Value; using json::Object; using json::Array;
HttpResponse response(int status,std::string body){return{status,{{"Content-Type","application/json; charset=utf-8"},{"X-Pastafari-Engine","celeritas-per-sepulcra"},{"X-Pastafari-Semantics","stage56"}},std::move(body)};}
HttpResponse error(int status,std::string code,std::string message,std::string field=""){
    Object e{{"code",Value{std::move(code)}},{"message",Value{std::move(message)}}}; if(!field.empty())e.emplace("field",Value{std::move(field)});
    return response(status,json::stringify(Value{Object{{"error",Value{std::move(e)}}}}));
}
bool safeJavascriptCallback(std::string_view callback){
    if(callback.empty()||callback.size()>64)return false;
    auto alpha=[](unsigned char c){return(c>='A'&&c<='Z')||(c>='a'&&c<='z');};
    auto digit=[](unsigned char c){return c>='0'&&c<='9';};
    auto first=[&](unsigned char c){return alpha(c)||c=='_'||c=='$';};
    auto rest=[&](unsigned char c){return alpha(c)||digit(c)||c=='_'||c=='$';};
    if(!first(static_cast<unsigned char>(callback.front())))return false;
    for(char c:callback.substr(1))if(!rest(static_cast<unsigned char>(c)))return false;
    return true;
}
HttpResponse javascriptResponse(std::string_view callback,std::string jsonBody){
    HttpResponse h{200,{{"Content-Type","application/javascript; charset=utf-8"},{"X-Content-Type-Options","nosniff"},{"Cross-Origin-Resource-Policy","cross-origin"},{"X-Pastafari-Engine","celeritas-per-sepulcra"},{"X-Pastafari-Semantics","stage56"}},std::string(callback)+"("+std::move(jsonBody)+");"};
    return h;
}
HttpResponse javascriptError(std::string_view callback,int applicationStatus,std::string code,std::string message,std::string field=""){
    auto j=error(applicationStatus,std::move(code),std::move(message),std::move(field));
    auto h=javascriptResponse(callback,std::move(j.body));
    h.headers["X-Pastafari-Application-Status"]=std::to_string(applicationStatus);
    h.headers["Cache-Control"]="no-store";
    return h;
}
std::string pct(std::string_view s){std::string o;for(std::size_t i=0;i<s.size();++i){char c=s[i];if(c=='+'){o.push_back(' ');continue;}if(c=='%'){if(i+2>=s.size())throw DateError("MALFORMED_QUERY","sequentia percent truncata est");auto hex=[](char h)->int{if(h>='0'&&h<='9')return h-'0';if(h>='A'&&h<='F')return h-'A'+10;if(h>='a'&&h<='f')return h-'a'+10;return-1;};int a=hex(s[i+1]),b=hex(s[i+2]);if(a<0||b<0)throw DateError("MALFORMED_QUERY","sequentia percent invalida est");o.push_back(char((a<<4)|b));i+=2;}else o.push_back(c);}return o;}
std::map<std::string,std::string> query(std::string_view target,std::string& path){auto q=target.find('?');path=std::string(target.substr(0,q));std::map<std::string,std::string> out;if(q==std::string_view::npos)return out;std::size_t p=q+1;while(p<=target.size()){auto amp=target.find('&',p);auto piece=target.substr(p,amp==std::string_view::npos?target.size()-p:amp-p);if(!piece.empty()){auto eq=piece.find('=');std::string k=pct(piece.substr(0,eq)),v=eq==std::string_view::npos?"":pct(piece.substr(eq+1));if(!out.emplace(k,v).second)throw DateError("MALFORMED_QUERY","parametrum query duplicatum est: "+k);}if(amp==std::string_view::npos)break;p=amp+1;}return out;}
std::string requireString(const Object&o,std::string_view k,bool required=true){auto*v=json::member(o,k);if(!v){if(required)throw DateError("MISSING_FIELD","campus deest: "+std::string(k));return{};}if(!v->isString())throw DateError("INVALID_TYPE",std::string(k)+" debet esse catena JSON");return v->string();}
TargetSpec targetFrom(const Value&v){if(v.isString())return{v.string(),"gregorian","auto"};if(!v.isObject())throw DateError("INVALID_TYPE","target debet esse catena aut objectum");auto&o=v.object();TargetSpec t; t.value=requireString(o,"value");auto c=requireString(o,"calendar",false);auto f=requireString(o,"format",false);if(!c.empty())t.calendar=c;if(!f.empty())t.format=f;return t;}
CalculationSpec calculationFrom(const Value* v){if(!v)return{};if(!v->isObject())throw DateError("INVALID_TYPE","calculation debet esse objectum");auto&o=v->object();std::string mode=requireString(o,"mode");std::string value=requireString(o,"value");if(mode=="engine-day")return{CalculationMode::EngineDay,value};if(mode=="instant")return{CalculationMode::Instant,value};throw DateError("INVALID_CALCULATION_MODE","calculation.mode debet esse instant aut engine-day");}
Value calcJson(const ResolvedCalculation&c){Object o{{"source",Value{c.source}},{"engineDay",Value{decimal(c.engineDay)}}};if(!c.instant.empty())o.emplace("instant",Value{c.instant});if(c.jdn)o.emplace("jdn",Value{decimal(*c.jdn)});if(!c.modelVersion.empty()){o.emplace("site",Value{std::string("kisurra")});o.emplace("dayBoundary",Value{std::string("venus-lower-culmination")});o.emplace("modelVersion",Value{c.modelVersion});}return Value{std::move(o)};}
Value targetJson(const ResolvedDate&t){return Value{Object{{"source",Value{t.source}},{"calendar",Value{t.calendar}},{"detectedFormat",Value{t.detectedFormat}},{"normalized",Value{t.normalized}},{"jdn",Value{decimal(t.jdn)}},{"engineDay",Value{decimal(t.engineDay)}}}};}
Value dateJson(const CanonicalPastafariDate&d,std::string_view language){return Value{Object{{"year",Value{decimal(d.year)}},{"language",Value{std::string(language)}},{"cutlet",Value{Object{{"index",Value{json::Number{std::to_string(d.cutletIndex)}}},{"name",Value{d.cutletName}}}}},{"dayInCutlet",Value{decimal(d.dayInCutlet)}},{"month",Value{Object{{"index",Value{json::Number{std::to_string(d.monthIndex)}}},{"name",Value{d.monthName}}}}},{"dayInMonth",Value{decimal(d.dayInMonth)}}}};}
Value singleJson(const SingleResult&r){return Value{Object{{"apiVersion",Value{std::string("1")}},{"engine",Value{Object{{"id",Value{std::string("celeritas-per-sepulcra")}},{"semanticStage",Value{json::Number{"56"}}}}}},{"resolvedInput",Value{Object{{"calculation",calcJson(r.calculation)},{"target",targetJson(r.target)}}}},{"date",dateJson(r.date,r.language)}}};}
int statusFor(const DateError&e){if(e.code=="BATCH_TOO_LARGE")return 413;if(e.code=="ASTRONOMY_UNAVAILABLE")return 503;if(e.code=="MALFORMED_QUERY"||e.code=="MISSING_FIELD"||e.code=="INVALID_TYPE")return 400;return 422;}
bool jsonContentType(std::string_view c){auto semi=c.find(';');auto base=c.substr(0,semi);while(!base.empty()&&std::isspace((unsigned char)base.back()))base.remove_suffix(1);return base=="application/json";}
}
HttpResponse HttpProtocol::handle(std::string_view method,std::string_view target,std::string_view contentType,std::string_view body,std::int64_t sampledMs){
 try{
  std::string path;auto q=query(target,path);
  if(path=="/v1/health"){
    if(method!="GET")return error(405,"METHOD_NOT_ALLOWED","health solum GET accipit");
    return response(200,R"({"apiVersion":"1","status":"ok"})");
  }
  if(path=="/v1/meta"){
    if(method!="GET")return error(405,"METHOD_NOT_ALLOWED","meta solum GET accipit");
    Array cs;for(auto&s:supportedCalendars())cs.push_back(Value{s});
    Array ls;for(auto&s:supportedNameLanguages())ls.push_back(Value{s});
    Object m{{"apiVersion",Value{std::string("1")}},{"engine",Value{std::string("celeritas-per-sepulcra")}},{"semanticStage",Value{json::Number{"56"}}},{"defaultCalendar",Value{std::string("gregorian")}},{"defaultLanguage",Value{std::string(DEFAULT_NAME_LANGUAGE)}},{"defaultCalculation",Value{std::string("request-instant-at-kisurra-venus-day")}},{"venusBoundaryModel",Value{std::string(VENUS_BOUNDARY_MODEL_VERSION)}},{"batchLimit",Value{json::Number{"1024"}}},{"calendars",Value{std::move(cs)}},{"languages",Value{std::move(ls)}}};
    return response(200,json::stringify(Value{std::move(m)}));
  }
  if(path=="/v1/date.js"){
    if(method!="GET")return error(405,"METHOD_NOT_ALLOWED","date.js solum GET accipit");
    auto cb=q.find("callback");if(cb==q.end())return error(400,"MISSING_FIELD","parametrum query deest: callback","callback");
    if(!safeJavascriptCallback(cb->second))return error(400,"INVALID_CALLBACK","callback debet esse simplex identificator JavaScript ASCII","callback");
    try{
      auto it=q.find("date");if(it==q.end())throw DateError("MISSING_FIELD","parametrum query deest: date");TargetSpec t{it->second,"gregorian","auto"};if(q.contains("calendar"))t.calendar=q.at("calendar");if(q.contains("format"))t.format=q.at("format");
      CalculationSpec c;if(q.contains("calculation_day")&&q.contains("calculation_instant"))throw DateError("AMBIGUOUS_CALCULATION","unam tantum emendationem calculationis adhibe");if(q.contains("calculation_day"))c={CalculationMode::EngineDay,q.at("calculation_day")};if(q.contains("calculation_instant"))c={CalculationMode::Instant,q.at("calculation_instant")};
      std::string language=std::string(DEFAULT_NAME_LANGUAGE);if(q.contains("language"))language=q.at("language");
      auto r=service_.calculate(t,c,sampledMs,language);auto h=javascriptResponse(cb->second,json::stringify(singleJson(r)));if(c.mode==CalculationMode::RequestInstant)h.headers["Cache-Control"]="no-store";return h;
    }catch(const AstronomyError&e){return javascriptError(cb->second,503,"ASTRONOMY_UNAVAILABLE",e.what());}
     catch(const DateError&e){return javascriptError(cb->second,statusFor(e),e.code,e.what());}
     catch(const std::exception&e){return javascriptError(cb->second,500,"INTERNAL_ERROR",e.what());}
  }
  if(path=="/v1/date"&&method=="GET"){
    auto it=q.find("date");if(it==q.end())throw DateError("MISSING_FIELD","parametrum query deest: date");TargetSpec t{it->second,"gregorian","auto"};if(q.contains("calendar"))t.calendar=q.at("calendar");if(q.contains("format"))t.format=q.at("format");
    CalculationSpec c;if(q.contains("calculation_day")&&q.contains("calculation_instant"))throw DateError("AMBIGUOUS_CALCULATION","unam tantum emendationem calculationis adhibe");if(q.contains("calculation_day"))c={CalculationMode::EngineDay,q.at("calculation_day")};if(q.contains("calculation_instant"))c={CalculationMode::Instant,q.at("calculation_instant")};
    std::string language=std::string(DEFAULT_NAME_LANGUAGE);if(q.contains("language"))language=q.at("language");
    auto r=service_.calculate(t,c,sampledMs,language);auto h=response(200,json::stringify(singleJson(r)));if(c.mode==CalculationMode::RequestInstant)h.headers["Cache-Control"]="no-store";return h;
  }
  if((path=="/v1/date"||path=="/v1/dates")&&method=="POST"){
    if(!jsonContentType(contentType)) return error(415,"UNSUPPORTED_MEDIA_TYPE","Content-Type debet esse application/json");
    Value root;
    try{root=json::parse(body);}catch(const json::Error&e){return error(400,"MALFORMED_JSON",std::string(e.what())+" ad offset "+std::to_string(e.offset));}if(!root.isObject())throw DateError("INVALID_TYPE","corpus petitionis debet esse objectum JSON");auto&o=root.object();auto c=calculationFrom(json::member(o,"calculation"));std::string language=requireString(o,"language",false);if(language.empty())language=std::string(DEFAULT_NAME_LANGUAGE);
    if(path=="/v1/date"){
      auto*tv=json::member(o,"target");if(!tv)throw DateError("MISSING_FIELD","campus deest: target");auto r=service_.calculate(targetFrom(*tv),c,sampledMs,language);auto h=response(200,json::stringify(singleJson(r)));if(c.mode==CalculationMode::RequestInstant)h.headers["Cache-Control"]="no-store";return h;
    }
    auto*ts=json::member(o,"targets");if(!ts)throw DateError("MISSING_FIELD","campus deest: targets");if(!ts->isArray())throw DateError("INVALID_TYPE","targets debet esse series JSON");if(ts->array().size()>1024)return error(413,"BATCH_TOO_LARGE","numerus maximus elementorum in batch est 1024");std::vector<TargetSpec> specs;for(auto&v:ts->array())specs.push_back(targetFrom(v));auto rs=service_.calculateBatch(specs,c,sampledMs,language);Array results;for(auto&r:rs)results.push_back(Value{Object{{"target",targetJson(r.target)},{"date",dateJson(r.date,r.language)}}});
    Object out{{"apiVersion",Value{std::string("1")}},{"engine",Value{Object{{"id",Value{std::string("celeritas-per-sepulcra")}},{"semanticStage",Value{json::Number{"56"}}}}}},{"resolvedCalculation",rs.empty()?calcJson(service_.resolveCalculation(c,sampledMs)):calcJson(rs.front().calculation)},{"results",Value{std::move(results)}}};auto h=response(200,json::stringify(Value{std::move(out)}));if(c.mode==CalculationMode::RequestInstant)h.headers["Cache-Control"]="no-store";return h;
  }
  if(path=="/v1/date"||path=="/v1/dates")return error(405,"METHOD_NOT_ALLOWED","methodus huic viae HTTP non sustentatur");
  return error(404,"NOT_FOUND","via HTTP ignota est");
 }catch(const AstronomyError&e){return error(503,"ASTRONOMY_UNAVAILABLE",e.what());}catch(const DateError&e){return error(statusFor(e),e.code,e.what());}catch(const std::exception&e){return error(500,"INTERNAL_ERROR",e.what());}
}
} // namespace pastafari::http_api
