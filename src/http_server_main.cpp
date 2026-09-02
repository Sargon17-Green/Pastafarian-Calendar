#define BOOST_ERROR_CODE_HEADER_ONLY
#include "pastafari/http_api/engine_port.hpp"
#include "pastafari/http_api/http_protocol.hpp"
#include "pastafari/http_api/pair_tomb.hpp"
#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <string>

namespace asio=boost::asio;
namespace beast=boost::beast;
namespace http=beast::http;
using tcp=asio::ip::tcp;
using namespace pastafari::http_api;

namespace {
constexpr std::uint64_t BODY_LIMIT=1024*1024;
std::int64_t nowMillis(){return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();}
http::status statusFrom(int n){return static_cast<http::status>(n);}
void serveConnection(tcp::socket socket,HttpProtocol& protocol){
    beast::flat_buffer buffer;
    for(;;){
        http::request_parser<http::string_body> parser;parser.body_limit(BODY_LIMIT);
        beast::error_code ec;http::read(socket,buffer,parser,ec);
        if(ec==http::error::end_of_stream)break;
        if(ec){
            if(ec==http::error::body_limit){http::response<http::string_body> r{http::status::payload_too_large,11};r.set(http::field::content_type,"application/json; charset=utf-8");r.body()=R"({"error":{"code":"BODY_TOO_LARGE","message":"corpus petitionis 1 MiB excedit"}})";r.prepare_payload();http::write(socket,r);}
            break;
        }
        auto req=parser.release(); // Petitio HTTP integra iam recepta est.
        const std::int64_t sampled=nowMillis();
        std::string contentType;auto c=req.find(http::field::content_type);if(c!=req.end())contentType=std::string(c->value());
        auto out=protocol.handle(std::string(req.method_string()),std::string(req.target()),contentType,req.body(),sampled);
        http::response<http::string_body> res{statusFrom(out.status),req.version()};
        for(auto&[k,v]:out.headers)res.set(k,v);
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
        CeleritasEnginePort engine;PairTombEnginePort pairTomb(engine);CalendarService service(pairTomb);HttpProtocol protocol(service);
        std::cerr<<"Pastafarian Celeritas HTTP v1 listening on "<<bind<<':'<<port<<"\n";
        for(;;){tcp::socket socket{ioc};acceptor.accept(socket);serveConnection(std::move(socket),protocol);}
    }catch(const std::exception&e){std::cerr<<"fatal: "<<e.what()<<'\n';return EXIT_FAILURE;}
}
