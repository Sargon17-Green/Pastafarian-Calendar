// Independent forward count: enumerate interleavings by month openings, continuations, closings.
// This does not include or invoke the Perl producer.
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <array>
#include <stdexcept>
// The fixed 12x52 target count fits in 128 bits. Checked additions keep the
// independent oracle exact without Boost's template-heavy compile footprint.
using u128 = unsigned __int128;
static u128 checked_add(u128 a, u128 b) {
    const u128 max = ~static_cast<u128>(0);
    if (max - a < b) throw std::overflow_error("uint128 oracle count overflow");
    return a + b;
}
static std::string decimal(u128 value) {
    if (value == 0) return "0";
    std::string out;
    while (value != 0) {
        const unsigned digit = static_cast<unsigned>(value % 10);
        out.push_back(static_cast<char>('0' + digit));
        value /= 10;
    }
    std::reverse(out.begin(), out.end());
    return out;
}
int main(int argc, char** argv) {
    const std::vector<int> L={3,4,4,5,5,5,5,5,5,4,4,3};
    const int m=(int)L.size();
    const int days=52;
    struct R {int opened,closed; uint32_t offset,size; std::vector<uint32_t> weight;};
    std::vector<R> ranges;
    std::vector<std::vector<int>> range_id(m+1,std::vector<int>(m+1,-1));
    uint32_t cap=0;
    for(int o=0;o<=m;++o)for(int c=0;c<=o;++c){
        R r{o,c,cap,1,std::vector<uint32_t>(m+1,0)};
        for(int j=c+1;j<=o;++j){r.weight[j]=r.size;r.size*=(L[j-1]-1);}
        range_id[o][c]=ranges.size(); ranges.push_back(r);cap+=r.size;
    }
    std::vector<uint16_t> rid(cap);
    std::vector<std::vector<uint32_t>> layer(days+1);
    for(uint16_t k=0;k<ranges.size();++k){
        const auto &r=ranges[k];
        int completed=0;for(int j=0;j<r.closed;++j)completed+=L[j];
        for(uint32_t code=0;code<r.size;++code){
            int used=completed;
            for(int j=r.closed+1;j<=r.opened;++j)
                used += 1+(code/r.weight[j])%(L[j-1]-1);
            if(used<0||used>days) throw std::runtime_error("invalid state depth");
            uint32_t idx=r.offset+code;rid[idx]=k;layer[used].push_back(idx);
        }
    }
    std::vector<u128> count(cap);
    count[0]=1;
    uint64_t live=0,edges=0;
    for(int d=0;d<days;++d){
        for(uint32_t i:layer[d]){
            if(count[i]==0) continue;
            ++live;
            const auto&r=ranges[rid[i]];
            uint32_t code=i-r.offset;
            if(r.opened<m){
                if(L[r.opened]>1){
                    const auto&target=ranges[range_id[r.opened+1][r.closed]];
                    count[target.offset+code]=checked_add(count[target.offset+code],count[i]);++edges;
                } else if(r.opened==r.closed){
                    const auto&target=ranges[range_id[r.opened+1][r.closed+1]];
                    count[target.offset]=checked_add(count[target.offset],count[i]);++edges;
                }
            }
            for(int j=r.closed+1;j<=r.opened;++j){
                int radix=L[j-1]-1;
                int digit=(code/r.weight[j])%radix;
                if(digit+1<radix){
                    count[i+r.weight[j]]=checked_add(count[i+r.weight[j]],count[i]);++edges;
                }else if(j==r.closed+1){
                    const auto&target=ranges[range_id[r.opened][r.closed+1]];
                    count[target.offset+code/radix]=checked_add(count[target.offset+code/radix],count[i]);++edges;
                }
            }
        }
    }
    const auto& terminal=ranges[range_id[m][m]];
    const u128 total=count[terminal.offset];
    std::cout<<decimal(total)<<"\n";
    count.clear(); count.shrink_to_fit();
    std::cerr<<"profile_months="<<m<<" days="<<days<<" capacity="<<cap<<" live_states="<<live<<" forward_edges="<<edges<<"\n";
    if(argc>1){
        std::vector<u128> suffix(cap);
        suffix[terminal.offset]=1;
        for(int d=days-1;d>=0;--d){
            for(uint32_t i:layer[d]){
                const auto &r=ranges[rid[i]];uint32_t code=i-r.offset;
                u128 sum=0;
                if(r.opened<m){
                    if(L[r.opened]>1)sum=checked_add(sum,suffix[ranges[range_id[r.opened+1][r.closed]].offset+code]);
                    else if(r.opened==r.closed)sum=checked_add(sum,suffix[ranges[range_id[r.opened+1][r.closed+1]].offset]);
                }
                for(int j=r.closed+1;j<=r.opened;++j){
                    int radix=L[j-1]-1, digit=(code/r.weight[j])%radix;
                    if(digit+1<radix)sum=checked_add(sum,suffix[i+r.weight[j]]);
                    else if(j==r.closed+1)sum=checked_add(sum,suffix[ranges[range_id[r.opened][r.closed+1]].offset+code/radix]);
                }
                suffix[i]=sum;
            }
        }
        if(suffix[0]!=total)throw std::runtime_error("forward/reverse count disagreement");
        std::ifstream file(argv[1]);std::string line;std::getline(file,line);
        if(!file)throw std::runtime_error("word file unavailable");
        std::stringstream words(line);std::string token;std::vector<int> word;
        while(std::getline(words,token,','))word.push_back(std::stoi(token));
        if((int)word.size()!=days)throw std::runtime_error("word length differs from 52");
        u128 ordinal=1;int opened=0,closed=0;uint32_t code=0;
        for(int value:word){
            const auto&r=ranges[range_id[opened][closed]];
            bool selected=false;
            for(int j=closed+1;j<=opened+1&&j<=m;++j){
                int no=opened,nc=closed;uint32_t nextCode=code;
                if(j==opened+1){
                    if(L[j-1]==1&&closed!=opened)continue;
                    ++no;
                    if(L[j-1]==1){++nc;nextCode=0;}
                }else{
                    int radix=L[j-1]-1;
                    int digit=(code/r.weight[j])%radix;
                    if(digit+1<radix)nextCode=code+r.weight[j];
                    else if(j==closed+1){++nc;nextCode=code/radix;}
                    else continue;
                }
                auto nextIndex=ranges[range_id[no][nc]].offset+nextCode;
                if(j<value){ordinal=checked_add(ordinal,suffix[nextIndex]);continue;}
                if(j==value){opened=no;closed=nc;code=nextCode;selected=true;break;}
                break;
            }
            if(!selected)throw std::runtime_error("lexically invalid word");
        }
        if(opened!=m||closed!=m)throw std::runtime_error("incomplete word");
        std::cout<<"lexical_ordinal="<<decimal(ordinal)<<"\n";
    }
    return 0;
}
