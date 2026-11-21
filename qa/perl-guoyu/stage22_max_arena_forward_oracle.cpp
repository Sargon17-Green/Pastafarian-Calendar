// Independent forward count: enumerate interleavings by month openings, continuations, closings.
// This does not include or invoke the Perl producer.
#include <boost/multiprecision/cpp_int.hpp>
#include <cstdint>
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <array>
#include <stdexcept>
using boost::multiprecision::uint256_t;
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
    std::vector<uint256_t> count(cap);
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
                    count[target.offset+code]+=count[i];++edges;
                } else if(r.opened==r.closed){
                    const auto&target=ranges[range_id[r.opened+1][r.closed+1]];
                    count[target.offset]+=count[i];++edges;
                }
            }
            for(int j=r.closed+1;j<=r.opened;++j){
                int radix=L[j-1]-1;
                int digit=(code/r.weight[j])%radix;
                if(digit+1<radix){
                    count[i+r.weight[j]]+=count[i];++edges;
                }else if(j==r.closed+1){
                    const auto&target=ranges[range_id[r.opened][r.closed+1]];
                    count[target.offset+code/radix]+=count[i];++edges;
                }
            }
        }
    }
    const auto& terminal=ranges[range_id[m][m]];
    const uint256_t total=count[terminal.offset];
    std::cout<<total<<"\n";
    count.clear(); count.shrink_to_fit();
    std::cerr<<"profile_months="<<m<<" days="<<days<<" capacity="<<cap<<" live_states="<<live<<" forward_edges="<<edges<<"\n";
    if(argc>1){
        std::vector<uint256_t> suffix(cap);
        suffix[terminal.offset]=1;
        for(int d=days-1;d>=0;--d){
            for(uint32_t i:layer[d]){
                const auto &r=ranges[rid[i]];uint32_t code=i-r.offset;
                uint256_t sum=0;
                if(r.opened<m){
                    if(L[r.opened]>1)sum+=suffix[ranges[range_id[r.opened+1][r.closed]].offset+code];
                    else if(r.opened==r.closed)sum+=suffix[ranges[range_id[r.opened+1][r.closed+1]].offset];
                }
                for(int j=r.closed+1;j<=r.opened;++j){
                    int radix=L[j-1]-1, digit=(code/r.weight[j])%radix;
                    if(digit+1<radix)sum+=suffix[i+r.weight[j]];
                    else if(j==r.closed+1)sum+=suffix[ranges[range_id[r.opened][r.closed+1]].offset+code/radix];
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
        uint256_t ordinal=1;int opened=0,closed=0;uint32_t code=0;
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
                if(j<value){ordinal+=suffix[nextIndex];continue;}
                if(j==value){opened=no;closed=nc;code=nextCode;selected=true;break;}
                break;
            }
            if(!selected)throw std::runtime_error("lexically invalid word");
        }
        if(opened!=m||closed!=m)throw std::runtime_error("incomplete word");
        std::cout<<"lexical_ordinal="<<ordinal<<"\n";
    }
    return 0;
}
