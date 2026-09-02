(ns pastafari.source-language-catalog)

(def catalog-version "1.0.0-stage01")

(def cutlet-catalog
  [{:canonical-index 1 :source "brons"}
   {:canonical-index 2 :source "vos"}
   {:canonical-index 3 :source "nier"}
   {:canonical-index 4 :source "lariks"}
   {:canonical-index 5 :source "gedachte"}
   {:canonical-index 6 :source "vier negenden"}
   {:canonical-index 7 :source "Palgoerasj"}
   {:canonical-index 8 :source "papyrusriet"}
   {:canonical-index 9 :source "tros"}
   {:canonical-index 10 :source "schorpioen"}
   {:canonical-index 11 :source "as"}
   {:canonical-index 12 :source "tarwe"}
   {:canonical-index 13 :source "rivier"}
   {:canonical-index 14 :source "gelach"}
   {:canonical-index 15 :source "Akkad"}
   {:canonical-index 16 :source "hoorn"}
   {:canonical-index 17 :source "de lege kruik"}])

(def month-catalog
  [{:canonical-index 1 :source "klei"}
   {:canonical-index 2 :source "granaatappel"}
   {:canonical-index 3 :source "elleboog"}
   {:canonical-index 4 :source "afgunst"}
   {:canonical-index 5 :source "Eridu"}
   {:canonical-index 6 :source "tandpasta"}
   {:canonical-index 7 :source "drie vijfden"}
   {:canonical-index 8 :source "Karsjoemab"}
   {:canonical-index 9 :source "luipaard"}
   {:canonical-index 10 :source "tin"}
   {:canonical-index 11 :source "mist"}
   {:canonical-index 12 :source "wierookhars"}
   {:canonical-index 13 :source "spindel"}
   {:canonical-index 14 :source "rib"}
   {:canonical-index 15 :source "johannesbrood"}
   {:canonical-index 16 :source "Uruk"}
   {:canonical-index 17 :source "schaamte"}
   {:canonical-index 18 :source "kameel"}
   {:canonical-index 19 :source "koper"}
   {:canonical-index 20 :source "waterput"}
   {:canonical-index 21 :source "eidooier"}
   {:canonical-index 22 :source "ster"}
   {:canonical-index 23 :source "honing"}
   {:canonical-index 24 :source "milt"}
   {:canonical-index 25 :source "kalksteen"}
   {:canonical-index 26 :source "vreugde"}
   {:canonical-index 27 :source "vijg"}
   {:canonical-index 28 :source "Nineve"}
   {:canonical-index 29 :source "kikker"}
   {:canonical-index 30 :source "teer"}
   {:canonical-index 31 :source "kaars"}
   {:canonical-index 32 :source "de gesloten deur"}
   {:canonical-index 33 :source "sesam"}
   {:canonical-index 34 :source "nek"}
   {:canonical-index 35 :source "zilver"}
   {:canonical-index 36 :source "lelie"}
   {:canonical-index 37 :source "storm"}
   {:canonical-index 38 :source "ezel"}
   {:canonical-index 39 :source "meel"}
   {:canonical-index 40 :source "spijt"}
   {:canonical-index 41 :source "Babylon"}
   {:canonical-index 42 :source "tong"}
   {:canonical-index 43 :source "vlas"}
   {:canonical-index 44 :source "zout"}
   {:canonical-index 45 :source "peer"}
   {:canonical-index 46 :source "boog"}
   {:canonical-index 47 :source "zand"}])

(defn- resolve-entry [catalog canonical-index]
  (when (and (integer? canonical-index)
             (<= 1 canonical-index (count catalog)))
    (nth catalog (dec canonical-index))))

(defn cutlet-source [canonical-index]
  (:source (resolve-entry cutlet-catalog canonical-index)))

(defn month-source [canonical-index]
  (:source (resolve-entry month-catalog canonical-index)))
