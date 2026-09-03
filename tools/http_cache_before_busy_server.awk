# Cicatrix HTTP cache-before-busy.
# src/http_server_main.cpp in repository intactum manet.
# Via semantica prius sepulcra generatorum immutabilia probat; solum missus
# verus ad semanticOwner veterem descendit.
BEGIN { replacing=0; replaced=0 }
{
    if (!replacing && index($0, "}else if(isSemanticTarget(target)){") != 0) {
        print "        }else if(isSemanticTarget(target)){"
        print "            try{"
        print "                PairTombGeneratedProbeScope probe;"
        print "                out=protocol.handle(method,target,contentType,req.body(),sampled);"
        print "            }catch(const GeneratedCacheMiss&){"
        print "                if(semanticOwner.test_and_set(std::memory_order_acquire))out=engineBusyResponse();"
        print "                else{"
        print "                    struct Release {std::atomic_flag& owner;~Release(){owner.clear(std::memory_order_release);}} release{semanticOwner};"
        print "                    out=protocol.handle(method,target,contentType,req.body(),sampled);"
        print "                }"
        print "            }"
        replacing=1
        replaced++
        next
    }
    if (replacing) {
        if ($0 == "        }else{") {
            print $0
            replacing=0
        }
        next
    }
    print
}
END {
    if (replacing || replaced != 1) {
        print "http_cache_before_busy_server.awk: locus semanticus inventus non est exacte semel" > "/dev/stderr"
        exit 42
    }
}
