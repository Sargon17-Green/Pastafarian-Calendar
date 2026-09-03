#define BOOST_ERROR_CODE_HEADER_ONLY
#include "pastafari/http_api/cors.hpp"
#include "pastafari/http_api/engine_port.hpp"
#include "pastafari/http_api/http_protocol.hpp"
#include "pastafari/http_api/pair_tomb.hpp"
#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <stdexcept>
#include <string>
#include <thread>
#include <unordered_map>

namespace asio=boost::asio;
namespace beast=boost::beast;
namespace http=beast::http;
using tcp=asio::ip::tcp;
using namespace pastafari::http_api;

namespace {
constexpr std::uint64_t BODY_LIMIT=1024*1024;
constexpr std::int64_t ASYNC_JOB_TTL_MS=30*60*1000;
constexpr std::size_t ASYNC_JOB_LIMIT=64;

std::int64_t nowMillis(){return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();}
http::status statusFrom(int n){return static_cast<http::status>(n);}
void addCorsHeaders(http::response<http::string_body>& res,std::string_view origin,const CorsPolicy& cors){
    if(origin.empty() || !cors.allows(origin))return;
    res.set("Access-Control-Allow-Origin",origin);
    res.set("Vary","Origin");
    res.set("Access-Control-Allow-Methods","GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers","Content-Type");
    res.set("Access-Control-Max-Age","600");
}
std::string requestOrigin(const http::request<http::string_body>& req){
    auto it=req.find("Origin");
    return it==req.end()?std::string{}:std::string(it->value());
}
std::string_view requestPath(std::string_view target){
    const auto q=target.find('?');
    return target.substr(0,q);
}
bool isSemanticTarget(std::string_view target){
    const auto path=requestPath(target);
    return path=="/v1/date" || path=="/v1/date.js" || path=="/v1/dates";
}
bool isAsyncJobTarget(std::string_view target){return requestPath(target)=="/v1/date-job.js";}

HttpResponse engineBusyResponse(){
    return {503,
            {{"Content-Type","application/json; charset=utf-8"},
             {"X-Pastafari-Engine","celeritas-per-sepulcra"},
             {"X-Pastafari-Semantics","stage56"},
             {"Retry-After","5"}},
            R"({"error":{"code":"ENGINE_BUSY","message":"machina semantica aliam petitionem iam computat"}})"};
}
std::string jsonString(std::string_view s);
HttpResponse plainJsonError(int status,std::string_view code,std::string_view message){
    return {status,
            {{"Content-Type","application/json; charset=utf-8"},
             {"X-Pastafari-Engine","celeritas-per-sepulcra"},
             {"X-Pastafari-Semantics","stage56"},
             {"Cache-Control","no-store"}},
            std::string("{\"error\":{\"code\":")+jsonString(code)+",\"message\":"+jsonString(message)+"}}"};
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
int hexValue(char c){
    if(c>='0'&&c<='9')return c-'0';
    if(c>='A'&&c<='F')return c-'A'+10;
    if(c>='a'&&c<='f')return c-'a'+10;
    return -1;
}
std::string percentDecode(std::string_view s){
    std::string out;
    out.reserve(s.size());
    for(std::size_t i=0;i<s.size();++i){
        if(s[i]=='+'){out.push_back(' ');continue;}
        if(s[i]!='%'){out.push_back(s[i]);continue;}
        if(i+2>=s.size())throw std::invalid_argument("sequentia percent truncata est");
        const int a=hexValue(s[i+1]),b=hexValue(s[i+2]);
        if(a<0||b<0)throw std::invalid_argument("sequentia percent invalida est");
        out.push_back(static_cast<char>((a<<4)|b));
        i+=2;
    }
    return out;
}
std::map<std::string,std::string> parseQuery(std::string_view target){
    std::map<std::string,std::string> out;
    const auto q=target.find('?');
    if(q==std::string_view::npos)return out;
    std::size_t p=q+1;
    while(p<=target.size()){
        const auto amp=target.find('&',p);
        const auto piece=target.substr(p,amp==std::string_view::npos?target.size()-p:amp-p);
        if(!piece.empty()){
            const auto eq=piece.find('=');
            const auto key=percentDecode(piece.substr(0,eq));
            const auto value=eq==std::string_view::npos?std::string{}:percentDecode(piece.substr(eq+1));
            if(!out.emplace(key,value).second)throw std::invalid_argument("parametrum query duplicatum est: "+key);
        }
        if(amp==std::string_view::npos)break;
        p=amp+1;
    }
    return out;
}
std::string percentEncode(std::string_view s){
    static constexpr char HEX[]="0123456789ABCDEF";
    std::string out;
    for(unsigned char c:s){
        const bool safe=(c>='A'&&c<='Z')||(c>='a'&&c<='z')||(c>='0'&&c<='9')||c=='-'||c=='_'||c=='.'||c=='~';
        if(safe)out.push_back(static_cast<char>(c));
        else{out.push_back('%');out.push_back(HEX[c>>4]);out.push_back(HEX[c&15]);}
    }
    return out;
}
std::string jsonString(std::string_view s){
    static constexpr char HEX[]="0123456789ABCDEF";
    std::string out="\"";
    for(unsigned char c:s){
        switch(c){
            case '\\':out+="\\\\";break;
            case '"':out+="\\\"";break;
            case '\b':out+="\\b";break;
            case '\f':out+="\\f";break;
            case '\n':out+="\\n";break;
            case '\r':out+="\\r";break;
            case '\t':out+="\\t";break;
            default:
                if(c<0x20){out+="\\u00";out.push_back(HEX[c>>4]);out.push_back(HEX[c&15]);}
                else out.push_back(static_cast<char>(c));
        }
    }
    out.push_back('"');
    return out;
}
HttpResponse javascriptResponse(std::string_view callback,std::string jsonBody){
    return {200,
            {{"Content-Type","application/javascript; charset=utf-8"},
             {"X-Content-Type-Options","nosniff"},
             {"Cross-Origin-Resource-Policy","cross-origin"},
             {"X-Pastafari-Engine","celeritas-per-sepulcra"},
             {"X-Pastafari-Semantics","stage56"},
             {"Cache-Control","no-store"}},
            std::string(callback)+"("+std::move(jsonBody)+");"};
}

struct AsyncJobRecord {
    enum class State { Running, Complete, Failed };
    State state=State::Running;
    int applicationStatus=0;
    std::string resultBody;
    std::int64_t createdMs=0;
    std::int64_t finishedMs=0;
};
struct AsyncJobStore {
    std::mutex mutex;
    std::unordered_map<std::string,AsyncJobRecord> jobs;
    std::atomic<std::uint64_t> sequence{0};
};
void purgeJobsLocked(AsyncJobStore& store,std::int64_t now){
    for(auto it=store.jobs.begin();it!=store.jobs.end();){
        const auto& job=it->second;
        if(job.state!=AsyncJobRecord::State::Running && job.finishedMs>0 && now-job.finishedMs>ASYNC_JOB_TTL_MS)it=store.jobs.erase(it);
        else ++it;
    }
    while(store.jobs.size()>ASYNC_JOB_LIMIT){
        auto victim=store.jobs.end();
        for(auto it=store.jobs.begin();it!=store.jobs.end();++it){
            if(it->second.state==AsyncJobRecord::State::Running)continue;
            if(victim==store.jobs.end()||it->second.finishedMs<victim->second.finishedMs)victim=it;
        }
        if(victim==store.jobs.end())break;
        store.jobs.erase(victim);
    }
}
std::string buildDateTarget(const std::map<std::string,std::string>& q){
    std::string target="/v1/date";
    bool first=true;
    for(const auto&[key,value]:q){
        if(key=="callback"||key=="job")continue;
        target+=first?'?':'&';first=false;
        target+=percentEncode(key);target+='=';target+=percentEncode(value);
    }
    return target;
}
std::string runningJobJson(std::string_view id){
    return std::string("{\"apiVersion\":\"1\",\"job\":{\"id\":")+jsonString(id)+",\"status\":\"running\",\"pollAfterMilliseconds\":2000}}";
}
std::string busyJobJson(){
    return R"({"apiVersion":"1","job":{"status":"busy","retryAfterMilliseconds":5000}})";
}
std::string missingJobJson(std::string_view id){
    return std::string("{\"apiVersion\":\"1\",\"error\":{\"code\":\"JOB_NOT_FOUND\",\"message\":\"opus async non inventum aut exspiratum est\",\"job\":")+jsonString(id)+"}}";
}
std::string completedJobJson(std::string_view id,const AsyncJobRecord& job){
    const char* state=job.state==AsyncJobRecord::State::Complete?"complete":"failed";
    return std::string("{\"apiVersion\":\"1\",\"job\":{\"id\":")+jsonString(id)+",\"status\":\""+state+"\",\"applicationStatus\":"+std::to_string(job.applicationStatus)+"},\"result\":"+job.resultBody+"}";
}

HttpResponse handleAsyncJob(std::string_view method,
                            std::string_view target,
                            std::int64_t sampled,
                            HttpProtocol& protocol,
                            std::atomic_flag& semanticOwner,
                            const std::shared_ptr<AsyncJobStore>& store){
    if(method!="GET")return plainJsonError(405,"METHOD_NOT_ALLOWED","date-job.js solum GET accipit");
    std::map<std::string,std::string> q;
    try{q=parseQuery(target);}catch(const std::exception&e){return plainJsonError(400,"MALFORMED_QUERY",e.what());}
    const auto cb=q.find("callback");
    if(cb==q.end())return plainJsonError(400,"MISSING_FIELD","parametrum query deest: callback");
    if(!safeJavascriptCallback(cb->second))return plainJsonError(400,"INVALID_CALLBACK","callback debet esse simplex identificator JavaScript ASCII");
    const std::string callback=cb->second;

    const auto jobIt=q.find("job");
    if(jobIt!=q.end()){
        std::lock_guard<std::mutex> lock(store->mutex);
        purgeJobsLocked(*store,sampled);
        const auto found=store->jobs.find(jobIt->second);
        if(found==store->jobs.end())return javascriptResponse(callback,missingJobJson(jobIt->second));
        if(found->second.state==AsyncJobRecord::State::Running)return javascriptResponse(callback,runningJobJson(jobIt->second));
        return javascriptResponse(callback,completedJobJson(jobIt->second,found->second));
    }

    if(q.find("date")==q.end()){
        return javascriptResponse(callback,R"({"apiVersion":"1","error":{"code":"MISSING_FIELD","message":"parametrum query deest: date"}})");
    }
    if(semanticOwner.test_and_set(std::memory_order_acquire)){
        auto response=javascriptResponse(callback,busyJobJson());
        response.headers["Retry-After"]="5";
        return response;
    }

    const auto sequence=store->sequence.fetch_add(1,std::memory_order_relaxed)+1;
    const std::string id="j"+std::to_string(sampled)+"-"+std::to_string(sequence);
    const std::string backendTarget=buildDateTarget(q);
    {
        std::lock_guard<std::mutex> lock(store->mutex);
        purgeJobsLocked(*store,sampled);
        store->jobs[id]=AsyncJobRecord{AsyncJobRecord::State::Running,0,"",sampled,0};
    }

    try{
        std::thread([store,&protocol,&semanticOwner,id,backendTarget,sampled]() mutable {
            struct Release {
                std::atomic_flag& owner;
                ~Release(){owner.clear(std::memory_order_release);}
            } release{semanticOwner};
            HttpResponse result;
            try{
                result=protocol.handle("GET",backendTarget,"","",sampled);
            }catch(const std::exception&e){
                result=plainJsonError(500,"INTERNAL_ERROR",e.what());
            }catch(...){
                result=plainJsonError(500,"INTERNAL_ERROR","error internus ignotus");
            }
            const auto finished=nowMillis();
            std::lock_guard<std::mutex> lock(store->mutex);
            auto found=store->jobs.find(id);
            if(found==store->jobs.end())return;
            found->second.applicationStatus=result.status;
            found->second.resultBody=std::move(result.body);
            found->second.finishedMs=finished;
            found->second.state=result.status>=200&&result.status<300?AsyncJobRecord::State::Complete:AsyncJobRecord::State::Failed;
        }).detach();
    }catch(const std::exception&e){
        semanticOwner.clear(std::memory_order_release);
        {
            std::lock_guard<std::mutex> lock(store->mutex);
            store->jobs.erase(id);
        }
        return javascriptResponse(callback,std::string("{\"apiVersion\":\"1\",\"error\":{\"code\":\"JOB_START_FAILED\",\"message\":")+jsonString(e.what())+"}}" );
    }
    return javascriptResponse(callback,runningJobJson(id));
}

void serveConnection(tcp::socket socket,HttpProtocol& protocol,const CorsPolicy& cors,std::atomic_flag& semanticOwner,const std::shared_ptr<AsyncJobStore>& asyncJobs){
    beast::flat_buffer buffer;
    for(;;){
        http::request_parser<http::string_body> parser;parser.body_limit(BODY_LIMIT);
        beast::error_code ec;http::read(socket,buffer,parser,ec);
        if(ec==http::error::end_of_stream)break;
        if(ec){
            if(ec==http::error::body_limit){http::response<http::string_body> r{http::status::payload_too_large,11};r.set(http::field::content_type,"application/json; charset=utf-8");r.body()=R"({"error":{"code":"BODY_TOO_LARGE","message":"corpus petitionis 1 MiB excedit"}})";r.prepare_payload();http::write(socket,r);}
            break;
        }
        auto req=parser.release();
        const std::string origin=requestOrigin(req);
        if(req.method()==http::verb::options){
            http::response<http::string_body> preflight{http::status::no_content,req.version()};
            if(origin.empty() || !cors.allows(origin)){
                preflight.result(http::status::forbidden);
                preflight.set(http::field::content_type,"application/json; charset=utf-8");
                preflight.body()=R"({"error":{"code":"CORS_ORIGIN_NOT_ALLOWED","message":"origo navigatoris huic ministro non permittitur"}})";
            }else addCorsHeaders(preflight,origin,cors);
            preflight.set(http::field::server,"Pastafarian-Celeritas-Sepulchral-HTTP/1");
            preflight.keep_alive(req.keep_alive());
            preflight.prepare_payload();
            http::write(socket,preflight,ec);
            if(ec||!preflight.keep_alive())break;
            continue;
        }
        const std::int64_t sampled=nowMillis();
        std::string contentType;auto c=req.find(http::field::content_type);if(c!=req.end())contentType=std::string(c->value());
        HttpResponse out;
        const std::string method(req.method_string());
        const std::string target(req.target());
        if(isAsyncJobTarget(target)){
            out=handleAsyncJob(method,target,sampled,protocol,semanticOwner,asyncJobs);
        }else if(isSemanticTarget(target)){
            if(semanticOwner.test_and_set(std::memory_order_acquire))out=engineBusyResponse();
            else{
                struct Release {std::atomic_flag& owner;~Release(){owner.clear(std::memory_order_release);}} release{semanticOwner};
                out=protocol.handle(method,target,contentType,req.body(),sampled);
            }
        }else{
            out=protocol.handle(method,target,contentType,req.body(),sampled);
        }
        http::response<http::string_body> res{statusFrom(out.status),req.version()};
        for(auto&[k,v]:out.headers)res.set(k,v);
        addCorsHeaders(res,origin,cors);
        res.set(http::field::server,"Pastafarian-Celeritas-Sepulchral-HTTP/1");
        res.keep_alive(req.keep_alive());res.body()=std::move(out.body);res.prepare_payload();
        http::write(socket,res,ec);if(ec||!res.keep_alive())break;
    }
    beast::error_code ignored;socket.shutdown(tcp::socket::shutdown_send,ignored);
}
}
int main(int argc,char**argv){
    try{
        std::string bind=argc>1?argv[1]:"127.0.0.1";unsigned short port=argc>2?static_cast<unsigned short>(std::stoul(argv[2])):8080;
        asio::io_context ioc{1};tcp::endpoint endpoint{asio::ip::make_address(bind),port};tcp::acceptor acceptor{ioc,endpoint};
        CeleritasEnginePort engine;PairTombEnginePort pairTomb(engine);CalendarService service(pairTomb);HttpProtocol protocol(service);CorsPolicy cors=CorsPolicy::fromEnvironment();
        std::atomic_flag semanticOwner=ATOMIC_FLAG_INIT;
        auto asyncJobs=std::make_shared<AsyncJobStore>();
        std::cerr<<"Pastafarian Celeritas HTTP v1 listening on "<<bind<<':'<<port<<"\n";
        for(;;){
            tcp::socket socket{ioc};
            acceptor.accept(socket);
            std::thread([socket=std::move(socket),&protocol,&cors,&semanticOwner,asyncJobs]() mutable {
                serveConnection(std::move(socket),protocol,cors,semanticOwner,asyncJobs);
            }).detach();
        }
    }catch(const std::exception&e){std::cerr<<"fatal: "<<e.what()<<'\n';return EXIT_FAILURE;}
}
