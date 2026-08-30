#pragma once

#include "pastafari/source_language_catalog.hpp"
#include "reference/normative_reference.hpp"

#include <algorithm>
#include <map>
#include <numeric>
#include <stdexcept>
#include <tuple>
#include <utility>
#include <vector>

namespace pastafari::stage55audit {

using reference::Big;

struct TexturaStatus {
    std::vector<int> reliqua{};
    int apertaUsque = 0;
    int clausaUsque = 0;
};

class TexturaCelerReference {
public:
    explicit TexturaCelerReference(std::vector<int> longitudines)
        : longitudines_(std::move(longitudines)), numerus_(static_cast<int>(longitudines_.size())) {
        if (longitudines_.empty()) throw std::runtime_error("textura reference saltem unum mensem requirit");
        maximaActiva_.assign(static_cast<std::size_t>(numerus_ + 1), 0);
        for (int a = 1; a <= numerus_; ++a) {
            const int n = longitudines_.at(static_cast<std::size_t>(a - 1));
            if (n < 1) throw std::runtime_error("longitudo mensis reference positiva esse debet");
            maximaActiva_[static_cast<std::size_t>(a)] = maximaActiva_[static_cast<std::size_t>(a - 1)] + n - 1;
        }
        suffixa_.resize(static_cast<std::size_t>(numerus_ + 1));
        suffixa_[static_cast<std::size_t>(numerus_)].assign(
            static_cast<std::size_t>(maximaActiva_.back() + 1), Big{1});
        for (int a = numerus_ - 1; a >= 0; --a) {
            const int n = longitudines_.at(static_cast<std::size_t>(a));
            const int maxS = maximaActiva_.at(static_cast<std::size_t>(a));
            auto& linea = suffixa_.at(static_cast<std::size_t>(a));
            linea.resize(static_cast<std::size_t>(maxS + 1));
            Big modosInsertionis = 1;
            for (int s = 0; s <= maxS; ++s) {
                if (s > 0) {
                    modosInsertionis *= (s + n - 2);
                    modosInsertionis /= s;
                }
                Big valor = modosInsertionis *
                    suffixa_.at(static_cast<std::size_t>(a + 1)).at(static_cast<std::size_t>(s + n - 1));
                if (s > 0) valor += linea.at(static_cast<std::size_t>(s - 1));
                linea[static_cast<std::size_t>(s)] = valor;
            }
        }
    }

    Big numerusOmnium() {
        return numera(TexturaStatus{longitudines_, 0, 0});
    }

    std::vector<int> aperiGradum(Big gradus) {
        TexturaStatus status{longitudines_, 0, 0};
        const Big summa = numera(status);
        if (gradus < 1 || gradus > summa) throw std::runtime_error("gradus texturae reference extra fines est");
        const int totalis = std::accumulate(longitudines_.begin(), longitudines_.end(), 0);
        std::vector<int> exitus;
        exitus.reserve(static_cast<std::size_t>(totalis));
        while (static_cast<int>(exitus.size()) < totalis) {
            bool electus = false;
            for (int mensis = 1; mensis <= numerus_; ++mensis) {
                if (!licitus(status, mensis)) continue;
                const TexturaStatus proximus = move(status, mensis);
                const Big bloc = numera(proximus);
                if (gradus > bloc) {
                    gradus -= bloc;
                    continue;
                }
                exitus.push_back(mensis);
                status = proximus;
                electus = true;
                break;
            }
            if (!electus) throw std::runtime_error("gradus texturae reference aperiri non potuit");
        }
        return exitus;
    }

private:
    std::vector<int> longitudines_{};
    int numerus_ = 0;
    std::vector<int> maximaActiva_{};
    std::vector<std::vector<Big>> suffixa_{};
    std::map<std::pair<int,int>, Big> binomia_{};

    Big binomium(int n, int k) {
        if (k < 0 || k > n) return 0;
        k = std::min(k, n - k);
        const std::pair<int,int> clavis{n,k};
        const auto inventum = binomia_.find(clavis);
        if (inventum != binomia_.end()) return inventum->second;
        Big v = 1;
        for (int i = 1; i <= k; ++i) {
            v *= (n - k + i);
            v /= i;
        }
        binomia_.emplace(clavis, v);
        return v;
    }

    bool licitus(const TexturaStatus& status, int mensis) const {
        const std::size_t i = static_cast<std::size_t>(mensis - 1);
        if (status.reliqua[i] == 0) return false;
        const bool iamApertus = status.reliqua[i] < longitudines_[i];
        if (!iamApertus && mensis != status.apertaUsque + 1) return false;
        const bool nuncClauditur = status.reliqua[i] == 1;
        return !nuncClauditur || mensis == status.clausaUsque + 1;
    }

    TexturaStatus move(const TexturaStatus& status, int mensis) const {
        TexturaStatus proximus = status;
        const std::size_t i = static_cast<std::size_t>(mensis - 1);
        if (proximus.reliqua[i] == longitudines_[i]) proximus.apertaUsque = mensis;
        --proximus.reliqua[i];
        if (proximus.reliqua[i] == 0) proximus.clausaUsque = mensis;
        return proximus;
    }

    Big numera(const TexturaStatus& status) {
        if (status.apertaUsque == numerus_ && status.clausaUsque == numerus_) return 1;
        int activa = 0;
        int praefixum = 0;
        Big extensiones = 1;
        for (int mensis = status.clausaUsque + 1; mensis <= status.apertaUsque; ++mensis) {
            const int r = status.reliqua.at(static_cast<std::size_t>(mensis - 1));
            if (r <= 0) throw std::runtime_error("status texturae reference corruptus est");
            extensiones *= binomium(praefixum + r - 1, r - 1);
            praefixum += r;
            activa += r;
        }
        const int a = status.apertaUsque;
        if (activa < 0 || activa > maximaActiva_.at(static_cast<std::size_t>(a)))
            throw std::runtime_error("longitudo activa reference extra fines est");
        return extensiones * suffixa_.at(static_cast<std::size_t>(a)).at(static_cast<std::size_t>(activa));
    }
};

struct NaivaClavis {
    std::vector<int> reliqua{};
    int aperta = 0;
    int clausa = 0;
    bool operator<(const NaivaClavis& alia) const {
        return std::tie(reliqua, aperta, clausa) < std::tie(alia.reliqua, alia.aperta, alia.clausa);
    }
};

class TexturaNaivaReference {
public:
    explicit TexturaNaivaReference(std::vector<int> longitudines) : longitudines_(std::move(longitudines)) {}
    Big numerusOmnium() { return numera(NaivaClavis{longitudines_,0,0}); }
    std::vector<int> aperiGradum(Big gradus) {
        NaivaClavis status{longitudines_,0,0};
        const Big totalis = numera(status);
        if (gradus < 1 || gradus > totalis) throw std::runtime_error("gradus naivus extra fines est");
        std::vector<int> exitus;
        const int totalLength = std::accumulate(longitudines_.begin(), longitudines_.end(), 0);
        while (static_cast<int>(exitus.size()) < totalLength) {
            bool electus = false;
            for (int mensis = 1; mensis <= static_cast<int>(longitudines_.size()); ++mensis) {
                if (!licitus(status,mensis)) continue;
                const auto proximus = move(status,mensis);
                const Big bloc = numera(proximus);
                if (gradus > bloc) { gradus -= bloc; continue; }
                exitus.push_back(mensis); status = proximus; electus = true; break;
            }
            if (!electus) throw std::runtime_error("unrank naivus defecit");
        }
        return exitus;
    }
private:
    std::vector<int> longitudines_{};
    std::map<NaivaClavis,Big> memo_{};
    bool licitus(const NaivaClavis& s,int mensis) const {
        const std::size_t i=static_cast<std::size_t>(mensis-1);
        if(s.reliqua[i]==0)return false;
        const bool apertus=s.reliqua[i]<longitudines_[i];
        if(!apertus&&mensis!=s.aperta+1)return false;
        const bool claudit=s.reliqua[i]==1;
        return !claudit||mensis==s.clausa+1;
    }
    NaivaClavis move(const NaivaClavis&s,int mensis) const {
        auto n=s; const std::size_t i=static_cast<std::size_t>(mensis-1);
        if(n.reliqua[i]==longitudines_[i])n.aperta=mensis;
        --n.reliqua[i]; if(n.reliqua[i]==0)n.clausa=mensis; return n;
    }
    Big numera(const NaivaClavis&s){
        if(std::all_of(s.reliqua.begin(),s.reliqua.end(),[](int x){return x==0;}))return 1;
        const auto h=memo_.find(s); if(h!=memo_.end())return h->second;
        Big total=0; for(int m=1;m<=static_cast<int>(longitudines_.size());++m)if(licitus(s,m))total+=numera(move(s,m));
        memo_.emplace(s,total); return total;
    }
};

inline void probaReferenceCelerem() {
    const std::vector<std::vector<int>> familiae{{4,4,4},{5,4,6},{9,8,9}};
    for (const auto& f : familiae) {
        TexturaNaivaReference naiva(f);
        TexturaCelerReference celer(f);
        const Big n = naiva.numerusOmnium();
        if (celer.numerusOmnium() != n) throw std::runtime_error("reference celer numerum contra naive discrepavit");
        const std::vector<Big> gradus{Big{1},(n+1)/2,n};
        for (const auto& r : gradus)
            if (celer.aperiGradum(r) != naiva.aperiGradum(r))
                throw std::runtime_error("reference celer unrank contra naive discrepavit");
    }
}

inline reference::CalendarDate calendariumCelerInAnno(
    reference::NormativeOracle& oracle,
    const Big& calculationDay,
    const Big& targetDay,
    const reference::Year& annus) {
    const reference::SauceResult condimentum = reference::sauce(calculationDay, annus.openGateDay + 1);
    const int numerusSegmentorum = oracle.chooseCutletCount(condimentum, annus);
    const auto partitio = oracle.chooseCutletPartition(calculationDay, condimentum, annus, numerusSegmentorum);
    const auto nominaSegmentorum = oracle.chooseCutletNameIndices(condimentum, numerusSegmentorum);
    const auto segmenta = oracle.materializeCutlets(annus, partitio, nominaSegmentorum);
    const int numerusMensium = oracle.chooseMonthCount(condimentum, annus);
    const auto longitudines = oracle.chooseMonthLengths(condimentum, annus, numerusMensium);
    const auto nominaMensium = oracle.chooseMonthNameIndices(condimentum, numerusMensium);

    TexturaCelerReference familia(longitudines);
    const Big numerusTexturarum = familia.numerusOmnium();
    const Big gradus = reference::chooseRank(
        reference::askBowl(condimentum, 4, reference::SEAL_MONTH_WEAVING),
        numerusTexturarum);
    const auto textura = familia.aperiGradum(gradus);

    int segmentum = -1;
    for (std::size_t i=0;i<segmenta.size();++i) {
        if (segmenta[i].firstDay <= targetDay && targetDay <= segmenta[i].lastDay) {
            segmentum = static_cast<int>(i); break;
        }
    }
    if (segmentum < 0) throw std::runtime_error("reference celer segmentum target non invenit");
    const Big diesSegmenti = targetDay - segmenta[static_cast<std::size_t>(segmentum)].firstDay + 1;
    const Big offsetBig = targetDay - (annus.openGateDay + 1);
    if (offsetBig < 0 || offsetBig >= Big{textura.size()})
        throw std::runtime_error("reference celer positionem target extra texturam invenit");
    const std::size_t offset = offsetBig.convert_to<std::size_t>();
    const int mensisId = textura.at(offset);
    Big diesMensis = 0;
    for (std::size_t p=0;p<=offset;++p) if(textura[p]==mensisId) ++diesMensis;

    return reference::CalendarDate{
        annus.number,
        std::string(cutletSourceName(static_cast<std::size_t>(nominaSegmentorum.at(static_cast<std::size_t>(segmentum))))),
        diesSegmenti,
        std::string(monthSourceName(static_cast<std::size_t>(nominaMensium.at(static_cast<std::size_t>(mensisId-1))))),
        diesMensis
    };
}

inline reference::CalendarDate calendariumCeler(
    reference::NormativeOracle& oracle,
    const Big& calculationDay,
    const Big& targetDay) {
    const reference::Year annus = oracle.findTargetYear(calculationDay, targetDay);
    return calendariumCelerInAnno(oracle, calculationDay, targetDay, annus);
}

} // namespace pastafari::stage55audit
