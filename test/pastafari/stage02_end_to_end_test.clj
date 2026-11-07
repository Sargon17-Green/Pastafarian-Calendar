(ns pastafari.stage02-end-to-end-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.doeljaar :as zoeken]
            [pastafari.datumprojectie :as projectie]
            [pastafari.maandrang :as rang]
            [pastafari.maandweving :as weving]
            [pastafari.maandlengtes :as lengtes]
            [pastafari.maandprofiel :as budgetprofiel]
            [pastafari.normative-oracle :as orakel]))

;; DISCOVERY24: geen with-redefs. Beide berekeningen doorlopen de echte
;; selectie; de normatieve oracle blijft uitsluitend in de testomgeving.
(def ^:private lijn (delay (poorten/bouw-poortlijn 128N)))
(def ^:private celbudget 100000N)

(defn- poging [lijn berekeningsdag doeldag budget]
  (try
    {:status :bewezen
     :resultaat (projectie/kies-bewezen-datum
                 lijn berekeningsdag doeldag 128N budget)}
    (catch clojure.lang.ExceptionInfo fout
      {:status :geweigerd :code (:code (ex-data fout))})))

(deftest echte-end-to-end-jaargrenzen-met-budgetpoort
  (testing "Geen stubs: jaar 4999/5000/5001, eerste/midden/laatste dag en twee rekendagen."
    (let [berekeningsdag dagen/stichtingsdag
          basis (zoeken/vind-doeljaar @lijn berekeningsdag berekeningsdag)
          vorig (zoeken/vind-doeljaar @lijn berekeningsdag (:open-gate-day basis))
          volgend (zoeken/vind-doeljaar @lijn berekeningsdag
                                           (inc (:close-gate-day basis)))
          midden (+' (:open-gate-day basis)
                     (quot (-' (:close-gate-day basis)
                               (:open-gate-day basis)) 2N))
          gevallen [[berekeningsdag (inc (:open-gate-day basis))]
                    [berekeningsdag midden]
                    [berekeningsdag (:close-gate-day basis)]
                    [berekeningsdag (:close-gate-day vorig)]
                    [berekeningsdag (inc (:open-gate-day volgend))]
                    [(+' berekeningsdag 17N) (+' berekeningsdag 17N)]
                    [(-' berekeningsdag 23N) (-' berekeningsdag 23N)]]
          getallen (atom {:bewezen 0 :geweigerd 0})]
      (is (= [4999N 5000N 5001N]
             (mapv :number [vorig basis volgend])))
      (doseq [[berekening doel] gevallen]
        (let [{:keys [status resultaat code]}
              (poging @lijn berekening doel celbudget)]
          (case status
            :bewezen
            (do
              (swap! getallen update :bewezen inc)
              (is (= 5 (count (:date-components resultaat))))
              (is (every? integer? (:date-components resultaat)))
              (is (<= (:month-weaving-cell-bound resultaat) celbudget))
              (is (= (orakel/calendar-date-canonical berekening doel)
                     (:date-components resultaat))))
            :geweigerd
            (do
              (swap! getallen update :geweigerd inc)
              (is (= :weaving-unrank-budget-unproven code))))))
      (println "DISCOVERY24 echte E2E:" @getallen "budget" celbudget)
      (is (= (count gevallen)
             (+ (:bewezen @getallen) (:geweigerd @getallen)))))))

(deftest budgetweigering-voor-de-dure-maandrang
  (testing "De productie weigert een onvoldoende budget op echte poortlijn."
    (let [berekening dagen/stichtingsdag
          uitkomst (poging @lijn berekening berekening 1N)]
      (is (= :geweigerd (:status uitkomst)))
      (is (= :weaving-unrank-budget-unproven (:code uitkomst))))))


;; DISCOVERY24 DIAG02: 100000N is analytisch onmogelijk als voldoende
;; bovengrens voor een geldige datum: N>=252, m>=3, dus
;; N*m*(1+(m+1)*(N+1)) >= 765828N. Geen willekeurige budgetverhoging.
(deftest ondergrens-sluit-oude-e2e-budget-uit
  (let [ondergrens (*' 252N 3N (+' 1N (*' 4N 253N)))]
    (is (= 765828N ondergrens))
    (is (> ondergrens celbudget))))

;; Deterministische, eindige echte profieldiagnose. De productie wordt
;; pas met het bestaande maximum 5000000N geroepen ALS haar formele
;; celbovengrens voor precies die maandlengtes <=5000000N is.
;; Zonder veilig profiel is groen CI slechts diagnostiek, GEEN E2E-PASS.
(deftest begrensde-echte-budgetprofiel-diagnose
  (testing "48 verschoven rekendagen, geen stubs, alleen bewezen veilige profielen"
    (let [maximum 5000000N
          metingen (atom {:onderzocht 0 :budgetveilig 0
                          :bewezen 0 :kleinste-grens nil})]
      (loop [k 0]
        (when (and (< k 48) (zero? (:bewezen @metingen)))
          (let [berekening (+' dagen/stichtingsdag (*' 97N (- k 24)))
                keuze (lengtes/kies-maandlengtes
                        @lijn berekening berekening 128N)
                jaar (:year keuze)
                duur (-' (:close-gate-day jaar)
                         (:open-gate-day jaar))
                bewijs (budgetprofiel/veilige-celgrens
                         (:month-lengths keuze) maximum)
                grens (:celbovengrens bewijs)]
            (is (= duur (:dagen bewijs)))
            (is (= (:month-count keuze) (:maanden bewijs)))
            (swap! metingen
                   (fn [m]
                     (-> m
                         (update :onderzocht inc)
                         (update :kleinste-grens
                                 #(if (nil? %) grens (min % grens))))))
            (when (:budgetveilig? bewijs)
              (swap! metingen update :budgetveilig inc)
              (println "DISCOVERY24 DIAG02 veilig echt profiel:"
                       {:k k :berekening berekening
                        :jaar (:number jaar) :maanden (:maanden bewijs)
                        :dagen (:dagen bewijs) :celbovengrens grens})
              (let [open (:open-gate-day jaar)
                    close (:close-gate-day jaar)
                    midden (+' (inc open) (quot (dec duur) 2N))]
                (doseq [doel (distinct [berekening (inc open) midden close])]
                  (let [{:keys [status resultaat code]}
                        (poging @lijn berekening doel maximum)]
                    (is (= :bewezen status)
                        (str "Echte E2E geweigerd ondanks bewezen budget: "
                             {:k k :doel doel :code code :grens grens}))
                    (when (= :bewezen status)
                      (is (= 5 (count (:date-components resultaat))))
                      (is (every? integer? (:date-components resultaat)))
                      (is (= grens (:month-weaving-cell-bound resultaat)))
                      (is (<= (:month-weaving-cell-bound resultaat) maximum))
                      (is (= (orakel/calendar-date-canonical berekening doel)
                             (:date-components resultaat)))
                      (swap! metingen update :bewezen inc))))))
            (recur (inc k)))))
      (println "DISCOVERY24 DIAG02 echte profielen:" @metingen
               "maximum" maximum)
      (is (<= (:bewezen @metingen)
              (* 4 (:budgetveilig @metingen)))))))


;; DIAG03: normatieve, onafhankelijke keuzen; geen volledige weving.
;; Haar eerste letter is in ieder geldig woord exact maand-ID 1.
(defn- normatieve-eerste-jaardag [berekening doel]
  (let [staat (orakel/new-gate-state)
        jaar (orakel/find-target-year staat berekening doel)
        eerste (inc (:open-gate-day jaar))]
    (when-not (= doel eerste)
      (throw (ex-info "Orakel verwacht eerste jaardag."
                      {:code :oracle-target-not-first-day})))
    (let [saus (orakel/sauce berekening eerste)
          kotelet-aantal (orakel/choose-cutlet-count saus jaar)
          verdeling (orakel/choose-cutlet-partition
                      staat berekening saus jaar kotelet-aantal)
          kotelet-namen (orakel/choose-cutlet-names saus kotelet-aantal)
          koteletten (orakel/materialize-cutlets
                       staat jaar verdeling kotelet-namen)
          maand-aantal (orakel/choose-month-count saus jaar)
          maand-lengtes (orakel/choose-month-lengths
                          saus jaar maand-aantal)
          maand-namen (orakel/choose-month-names saus maand-aantal)]
      (when-not (= (reduce +' 0N maand-lengtes)
                   (-' (:close-gate-day jaar) (:open-gate-day jaar)))
        (throw (ex-info "Normatieve maandlengtes onjuist."
                        {:code :oracle-month-lengths-invalid})))
      [(:number jaar) (:name-index (first koteletten))
       1N (first maand-namen) 1N])))

(deftest eerste-positie-van-lexicografische-weving
  (testing "Normatieve oracle op kleine families: eerste ID is altijd 1."
    (doseq [lengten [[4 4] [4 4 4]]
            :let [familie (orakel/weaving-family lengten)
                  aantal ((:count familie))]
            rang (distinct [1N 2N (quot (inc aantal) 2N) aantal])]
      (is (= 1 (first ((:unrank1 familie) rang)))
          (str "lengten=" lengten " rang=" rang)))))

(deftest echte-eerste-jaardag-zonder-volledige-weving
  (testing "Drie echte rekendagen, vijf velden en afwijzing van dag twee."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            eerste (inc (:open-gate-day jaar))
            uitkomst (projectie/kies-eerste-dag-zonder-weving
                       @lijn berekening eerste 128N)
            verwacht (normatieve-eerste-jaardag berekening eerste)]
        (is (= verwacht (:date-components uitkomst)))
        (is (= 5 (count (:date-components uitkomst))))
        (is (every? integer? (:date-components uitkomst)))
        (is (= :first-day-only (:date-proof-scope uitkomst)))
        (is (false? (:month-weaving-computed? uitkomst)))
        (is (not (contains? uitkomst :month-weaving)))
        (println "DISCOVERY24 DIAG03 echte eerste-jaardag:"
                 {:berekening berekening :doel eerste
                  :jaar (:number jaar)
                  :gelijk? (= verwacht (:date-components uitkomst))})
        (let [fout (try
                     (projectie/kies-eerste-dag-zonder-weving
                      @lijn berekening (inc eerste) 128N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-first-day-of-year fout)))))))


;; DIAG04: onafhankelijk normatief pad voor een jaareind, zonder de
;; productieprojectie of volledige maandweving aan te roepen.
(defn- normatieve-laatste-jaardag [berekening doel]
  (let [staat (orakel/new-gate-state)
        jaar (orakel/find-target-year staat berekening doel)
        eerste (inc (:open-gate-day jaar))]
    (when-not (= doel (:close-gate-day jaar))
      (throw (ex-info "Orakel verwacht laatste jaardag."
                      {:code :oracle-target-not-last-day})))
    (let [saus (orakel/sauce berekening eerste)
          aantal-koteletten (orakel/choose-cutlet-count saus jaar)
          verdeling (orakel/choose-cutlet-partition
                      staat berekening saus jaar aantal-koteletten)
          kotelet-namen (orakel/choose-cutlet-names saus aantal-koteletten)
          koteletten (orakel/materialize-cutlets
                       staat jaar verdeling kotelet-namen)
          maand-aantal (orakel/choose-month-count saus jaar)
          maand-lengtes (orakel/choose-month-lengths saus jaar maand-aantal)
          maand-namen (orakel/choose-month-names saus maand-aantal)
          laatste-kotelet (peek koteletten)]
      (when-not (= (reduce +' 0N maand-lengtes)
                   (-' (:close-gate-day jaar) (:open-gate-day jaar)))
        (throw (ex-info "Normatieve maandlengtes onjuist."
                        {:code :oracle-month-lengths-invalid})))
      [(:number jaar) (:name-index laatste-kotelet)
       (inc (-' doel (:first-day laatste-kotelet)))
       (peek maand-namen) (peek maand-lengtes)])))

(deftest laatste-positie-van-lexicografische-weving
  (testing "Normatieve weving sluit altijd de hoogste maand-ID als laatste."
    (doseq [lengten [[4 4] [4 4 4] [4 5 4]]
            :let [familie (orakel/weaving-family lengten)
                  aantal ((:count familie))]
            rang (distinct [1N 2N (quot (inc aantal) 2N) aantal])]
      (let [woord ((:unrank1 familie) rang)]
        (is (= (count lengten) (peek woord))
            (str "lengten=" lengten " rang=" rang))
        (is (= (peek lengten)
               (count (filter #(= (count lengten) %) woord))))))))

(deftest echte-laatste-jaardag-zonder-volledige-weving
  (testing "Vijf werkelijke jaargrenzen, onafhankelijke normatieve vergelijking."
    (let [basis (zoeken/vind-doeljaar
                 @lijn dagen/stichtingsdag dagen/stichtingsdag)
          vorig (zoeken/vind-doeljaar
                  @lijn dagen/stichtingsdag (:open-gate-day basis))
          volgend (zoeken/vind-doeljaar
                    @lijn dagen/stichtingsdag (inc (:close-gate-day basis)))
          gevallen [[dagen/stichtingsdag (:close-gate-day vorig)]
                    [dagen/stichtingsdag (:close-gate-day basis)]
                    [dagen/stichtingsdag (:close-gate-day volgend)]
                    [(+' dagen/stichtingsdag 17N) nil]
                    [(-' dagen/stichtingsdag 23N) nil]]]
      (doseq [[berekening doel0] gevallen]
        (let [doel (or doel0
                       (:close-gate-day
                         (zoeken/vind-doeljaar @lijn berekening berekening)))
              uitkomst (projectie/kies-laatste-dag-zonder-weving
                         @lijn berekening doel 128N)
              verwacht (normatieve-laatste-jaardag berekening doel)]
          (is (= verwacht (:date-components uitkomst)))
          (is (= 5 (count (:date-components uitkomst))))
          (is (every? integer? (:date-components uitkomst)))
          (is (= :last-day-only (:date-proof-scope uitkomst)))
          (is (false? (:month-weaving-computed? uitkomst)))
          (is (not (contains? uitkomst :month-weaving)))
          (println "DISCOVERY24 DIAG04 werkelijk jaar-einde:"
                   {:berekening berekening :doel doel
                    :jaar (first verwacht)
                    :gelijk? (= verwacht (:date-components uitkomst))})
          (let [fout (try
                       (projectie/kies-laatste-dag-zonder-weving
                        @lijn berekening (dec doel) 128N)
                       nil
                       (catch clojure.lang.ExceptionInfo e
                         (:code (ex-data e))))]
            (is (= :target-not-last-day-of-year fout))))))))


;; DIAG05: de onafhankelijk normatieve oracle rangschikt volledige KLEINE
;; woorden. De productie telt slechts een lexicografisch prefixblok.
(deftest tweede-positie-onafhankelijke-kleine-families
  (testing "Vier kleine families, zowel grens- als eindrangen."
    (doseq [lengten [[4 4] [4 4 4] [4 5 4] [5 4 4]]
            :let [familie (orakel/weaving-family lengten)
                  totaal ((:count familie))
                  tweede-ids (mapv #(second ((:unrank1 familie) %))
                                   (range 1 (inc totaal)))
                  grens (count (take-while #(= 1 %) tweede-ids))
                  rangen (distinct [1N 2N (bigint grens)
                                    (inc (bigint grens))
                                    (quot (inc totaal) 2N) totaal])]
            rang rangen]
      (let [bewijs (rang/tweede-maand-op-rang-groot lengten rang 5000000N)
            woord ((:unrank1 familie) rang)]
        (is (= (mapv bigint (take 2 woord)) (:month-prefix bewijs)))
        (is (= (bigint grens) (:prefix-block11-count bewijs)))
        (is (= (bigint (second woord)) (:month-id bewijs)))
        (is (= (if (= 1 (second woord)) 2N 1N)
               (:day-in-month bewijs)))
        (is (<= (:prefix-cell-upper-bound bewijs) 5000000N))
        (is (false? (:month-weaving-computed? bewijs)))))))

(deftest tweede-dag-prefix-veilig-weigeren
  (let [code (try
               (rang/tweede-maand-op-rang-groot [4 4 4] 1N 1N)
               nil
               (catch clojure.lang.ExceptionInfo e
                 (:code (ex-data e))))]
    (is (= :second-day-prefix-budget-unproven code))))

(deftest echte-tweede-jaardag-alleen-bewezen-prefix
  (testing "Drie echte rekendagen: vijf velden, budget en dagdrie-weigering."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            tweede (+' (:open-gate-day jaar) 2N)
            uitkomst (projectie/kies-tweede-dag-zonder-weving
                      @lijn berekening tweede 128N 5000000N)
            vijf (:date-components uitkomst)
            prefix (:month-prefix uitkomst)]
        (is (= 5 (count vijf)))
        (is (every? integer? vijf))
        (is (= (:number jaar) (first vijf)))
        (is (= 1N (first prefix)))
        (is (contains? #{1N 2N} (second prefix)))
        (is (= (if (= 1N (second prefix)) 2N 1N) (peek vijf)))
        (is (= :second-day-prefix-only (:date-proof-scope uitkomst)))
        (is (false? (:month-weaving-computed? uitkomst)))
        (is (not (contains? uitkomst :month-weaving)))
        (is (<= (:month-prefix-cell-upper-bound uitkomst) 5000000N))
        (println "DISCOVERY24 DIAG05 werkelijk tweede dag:"
                 {:berekening berekening :doel tweede
                  :prefix prefix
                  :kosten (:month-prefix-cell-upper-bound uitkomst)})
        (let [code (try
                     (projectie/kies-tweede-dag-zonder-weving
                      @lijn berekening (inc tweede) 128N 5000000N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-second-day-of-year code)))))))



;; DIAG07: zelfstandige insertion-oracle voor exact de eerste drie
;; maandsymbolen. De productie telt resttoestanden; hier tellen we
;; juist combinatorisch de manieren om elke nog ongeopende maand in
;; bestaande, correct sluitende suffixen in te voegen.
(def ^:private derde-prefix-opties
  [[1N 1N 1N] [1N 1N 2N] [1N 2N 1N]
   [1N 2N 2N] [1N 2N 3N]])

(defn- insertion-binomial [n k]
  (let [klein (min k (- n k))]
    (loop [j 1N antwoord 1N]
      (if (> j klein)
        antwoord
        (recur (inc j)
               (quot (*' antwoord (+' (-' n klein) j)) j))))))

(defn- onafhankelijke-prefix-telling [lengten letters]
  (let [origineel (mapv bigint lengten)
        start {:rest origineel :geopend 0 :gesloten 0}
        na-prefix
        (reduce
         (fn [staat maand]
           (let [{:keys [rest geopend gesloten]} staat
                 index (dec (int maand))]
             (if (and (<= 0 index) (< index (count rest))
                      (<= maand (inc geopend))
                      (pos? (nth rest index))
                      (or (< (nth rest index) (nth origineel index))
                          (= maand (inc geopend)))
                      ;; Last appearances must close in the original order.
                      (or (> (nth rest index) 1)
                          (= maand (inc gesloten))))
               {:rest (update rest index dec)
                :geopend (max geopend (int maand))
                :gesloten (if (= 1 (nth rest index))
                            (inc gesloten) gesloten)}
               (reduced nil))))
         start letters)]
    (if (nil? na-prefix)
      0N
      (let [{:keys [rest geopend]} na-prefix
            ;; Elke maand telt minstens vier dagen: in drie symbolen
            ;; kan nog geen maand gesloten zijn.
            actief (subvec rest 0 geopend)
            basis
            (reduce (fn [{:keys [dagen telling]} a]
                      (let [nieuw (+' dagen a)]
                        {:dagen nieuw
                         :telling (if (zero? dagen)
                                    telling
                                    (*' telling
                                        (insertion-binomial (dec nieuw)
                                                            (dec a))))}))
                    {:dagen 0N :telling 1N}
                    actief)
            dagen (int (:dagen basis))
            initiële-histogram
            (assoc (vec (repeat (inc dagen) 0N))
                   0 (:telling basis))]
        (loop [histogram initiële-histogram
               volgende-maanden (seq (subvec rest geopend))]
          (if (nil? volgende-maanden)
            (reduce +' 0N histogram)
            (let [b (first volgende-maanden)
                  n (dec (count histogram))
                  ;; C(b+t-2,t) telt verdelingen van de b nieuwe
                  ;; letters, met minstens één letter in de slotgleuf.
                  coëfficiënten
                  (loop [t 0N w 1N uit [1N]]
                    (if (= t n)
                      uit
                      (let [nieuw (quot (*' w (+' b t -1N))
                                        (inc t))]
                        (recur (inc t) nieuw (conj uit nieuw)))))
                  ;; Bewaar de b-1 lege staartcellen: de suffixlengte wordt n+b.
                  nieuw-histogram
                  (loop [j 0 cumul 0N uit [0N]]
                    (if (> j n)
                      (into uit (repeat (dec (int b)) 0N))
                      (let [som (+' cumul (nth histogram j))]
                        (recur (inc j) som
                               (conj uit
                                     (*' som
                                         (nth coëfficiënten (- n j))))))))]
              (recur nieuw-histogram
                     (next volgende-maanden)))))))))

(deftest derde-prefix-insertion-oracle-kleine-families
  (testing "Brute lexicografische woorden versus andere invoeg-formule."
    (doseq [[lengten totaal]
            [[[4 4] 20N] [[4 4 4] 1301N]
             [[4 5 4] 3499N] [[5 4 4] 3101N]]
            :let [familie (orakel/weaving-family lengten)
                  woorden (map #((:unrank1 familie) %)
                              (range 1 (inc totaal)))
                  aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                                  derde-prefix-opties)]]
      (is (= totaal ((:count familie))))
      (is (= totaal (reduce +' 0N aantallen)))
      (doseq [[letters aantal] (map vector derde-prefix-opties aantallen)]
        (is (= aantal
               (count (filter #(= letters (mapv bigint (take 3 %)))
                              woorden)))
            (str "insertion-oracle mismatch " lengten " " letters))))
    ;; Vaste onafhankelijke Python-enumeratie van 177260 grote woorden.
    ;; Geen tijdrovende 177260 maal volledige Clojure-unranking.
    (let [aantallen (mapv #(onafhankelijke-prefix-telling [4 4 4 4] %)
                          derde-prefix-opties)]
      (is (= [10604N 39396N 39396N 26264N 61600N] aantallen))
      (is (= 177260N (reduce +' 0N aantallen))))))

;; DIAG06: de onafhankelijke normatieve oracle bouwt volledige KLEINE
;; wevingen. De productie telt slechts de eerste drie rangposities.

;; DIAG06 QA-PATCH01: de onafhankelijke normatieve oracle somt de complete
;; kleine woorden op. Test BEIDE zijden van ALLE drieletter-prefixovergangen.
;; De vaste aantallen komen uit een afzonderlijke brute permutatie-enumeratie,
;; niet uit de productieteller of de normatieve rangfunctie.
(deftest derde-positie-onafhankelijke-kleine-families
  (testing "Alle 15 derde-prefixgrenzen, beide naburige rangen, vier families."
    (doseq [[lengten verwacht-aantal verwacht-wissels]
            [[[4 4] 20N 3]
             [[4 4 4] 1301N 4]
             [[4 5 4] 3499N 4]
             [[5 4 4] 3101N 4]]
            :let [familie (orakel/weaving-family lengten)
                  totaal ((:count familie))
                  woorden (mapv #((:unrank1 familie) %)
                                (range 1 (inc totaal)))
                  tweede-grens (count (take-while #(= 1 (second %)) woorden))
                  wissels (for [i (range 1 (count woorden))
                                :when (not= (subvec (nth woorden (dec i)) 0 3)
                                            (subvec (nth woorden i) 0 3))]
                            (bigint (inc i)))
                  rangen (distinct
                          (filter #(<= 1N % totaal)
                            (concat [1N 2N (bigint tweede-grens)
                                     (inc (bigint tweede-grens))
                                     (quot (inc totaal) 2N) totaal]
                                    (mapcat (fn [r] [(dec r) r]) wissels))))]]
      (is (= verwacht-aantal totaal))
      (is (= verwacht-wissels (count wissels)))
      (doseq [r rangen]
        (let [bewijs (rang/derde-maand-op-rang-groot lengten r 5000000N)
              woord (nth woorden (dec (int r)))
              prefix (mapv bigint (take 3 woord))
              maand (peek prefix)]
          (is (= prefix (:month-prefix bewijs)))
          (is (= maand (:month-id bewijs)))
          (is (= (bigint (count (filter #(= maand %) prefix)))
                 (:day-in-month bewijs)))
          (is (<= 0N (:prefix-cell-upper-bound bewijs) 5000000N))
          (is (= :third-day-prefix-only (:date-proof-scope bewijs)))
          (is (false? (:month-weaving-computed? bewijs))))))))

(deftest derde-dag-prefix-budget-en-rang-weigeringen
  (let [fout (fn [lengten r budget]
               (try
                 (rang/derde-maand-op-rang-groot lengten r budget)
                 nil
                 (catch clojure.lang.ExceptionInfo e
                   (:code (ex-data e)))))]
    (is (= :third-day-prefix-budget-unproven (fout [4 4 4] 1N 1N)))
    (is (= :invalid-weaving-rank (fout [4 4 4] 0N 5000000N)))
    (is (= :invalid-weaving-budget (fout [4 4 4] 1N 5000001N)))))

(deftest echte-derde-jaardag-met-onafhankelijke-prefix-oracle
  (testing "Drie echte rekendagen: onafhankelijke maand-ID, rang, vijf velden en geen volledige weving."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            derde (+' (:open-gate-day jaar) 3N)
            uitkomst (projectie/kies-derde-dag-zonder-weving
                      @lijn berekening derde 128N 5000000N)
            vijf (:date-components uitkomst)
            prefix (:month-prefix uitkomst)
            maand (peek prefix)
            staat (orakel/new-gate-state)
            normjaar (orakel/find-target-year staat berekening derde)
            saus (orakel/sauce berekening (inc (:open-gate-day normjaar)))
            kotelet-aantal (orakel/choose-cutlet-count saus normjaar)
            partitie (orakel/choose-cutlet-partition
                      staat berekening saus normjaar kotelet-aantal)
            kotelet-namen (orakel/choose-cutlet-names saus kotelet-aantal)
            koteletten (orakel/materialize-cutlets
                       staat normjaar partitie kotelet-namen)
            norm-kotelet (some #(when (<= (:first-day %) derde (:last-day %)) %)
                               koteletten)
            norm-maand-aantal (orakel/choose-month-count saus normjaar)
            norm-lengten (orakel/choose-month-lengths
                          saus normjaar norm-maand-aantal)
            norm-namen (orakel/choose-month-names saus norm-maand-aantal)
            prefix-aantallen
            (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                  derde-prefix-opties)
            norm-totaal (reduce +' 0N prefix-aantallen)
            norm-rang (orakel/choose-rank
                       (orakel/ask-bowl saus 4 orakel/seal-month-weaving)
                       norm-totaal)
            norm-prefix
            (loop [r norm-rang keuzes derde-prefix-opties
                   aantallen prefix-aantallen]
              (if (empty? keuzes)
                (throw (ex-info "Geen normatieve derde-prefix bij rang."
                                {:code :oracle-third-prefix-not-found}))
                (let [blok (first aantallen)]
                  (if (> r blok)
                    (recur (-' r blok) (rest keuzes) (rest aantallen))
                    (first keuzes)))))
            norm-maand (peek norm-prefix)
            verwacht [(:number normjaar)
                      (:name-index norm-kotelet)
                      (inc (-' derde (:first-day norm-kotelet)))
                      (nth norm-namen (dec (int norm-maand)))
                      (bigint (count (filter #(= norm-maand %) norm-prefix)))]]
        (is (= norm-prefix prefix))
        (is (= norm-totaal (weving/aantal-wevingen-groot norm-lengten)))
        (is (<= 1N norm-rang norm-totaal))
        (is (= verwacht vijf))
        (is (= 3 (count prefix)))
        (is (= 1N (first prefix)))
        (is (every? #(<= 1N % 3N) prefix))
        (is (= :third-day-prefix-only (:date-proof-scope uitkomst)))
        (is (false? (:month-weaving-computed? uitkomst)))
        (is (not (contains? uitkomst :month-weaving)))
        (is (<= 0N (:month-prefix-cell-upper-bound uitkomst) 5000000N))
        (println "DISCOVERY24 DIAG06 echte derde jaardag:"
                 {:berekening berekening :doel derde
                  :prefix prefix :kosten (:month-prefix-cell-upper-bound uitkomst)
                  :gelijke-deelvelden? (= verwacht vijf)})
        (let [code (try
                     (projectie/kies-derde-dag-zonder-weving
                      @lijn berekening (inc derde) 128N 5000000N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-third-day-of-year code)))))))

;; DIAG08: onafhankelijke insertion-oracle voor de vierde jaardag.
;; Het geval [1,1,1,1] sluit de eerste maand exact af: de al bestaande
;; histogram-oracle ondersteunt nul resterende dagen in een actieve maand.
(def ^:private vierde-prefix-opties
  [[1N 1N 1N 1N] [1N 1N 1N 2N]
   [1N 1N 2N 1N] [1N 1N 2N 2N] [1N 1N 2N 3N]
   [1N 2N 1N 1N] [1N 2N 1N 2N] [1N 2N 1N 3N]
   [1N 2N 2N 1N] [1N 2N 2N 2N] [1N 2N 2N 3N]
   [1N 2N 3N 1N] [1N 2N 3N 2N] [1N 2N 3N 3N]
   [1N 2N 3N 4N]])

(defn- kies-onafhankelijk-prefixblok [opties aantallen rang]
  (loop [keuzes (seq opties) blokken (seq aantallen) r rang]
    (if (empty? keuzes)
      (throw (ex-info "Geen onafhankelijk vierde-prefixblok."
                      {:code :oracle-fourth-prefix-not-found}))
      (if (> r (first blokken))
        (recur (next keuzes) (next blokken) (-' r (first blokken)))
        {:prefix (first keuzes) :rest-rank r}))))

(deftest vierde-prefix-insertion-oracle-tegen-brute
  (testing "15 vierletterklassen; vaste ankers uit 185181 onafhankelijke brute-woorden."
    (doseq [[lengten totaal ankers]
            [[[4 4] 20N
              [1 3 3 3 0 3 3 0 3 1 0 0 0 0 0]]
             [[4 4 4] 1301N
              [20 105 105 105 126 105 105 126 105 35 84 126 84 70 0]]
             [[4 5 4] 3499N
              [35 224 224 336 280 224 336 280 336 224 280 280 280 160 0]]
             [[5 4 4] 3101N
              [125 336 336 224 280 336 224 280 224 56 140 280 140 120 0]]
             [[4 4 4 4] 177260N
              [1301 9303 9303 9303 20790 9303 9303 20790
               9303 3101 13860 20790 13860 11550 15400]]]]
      (let [aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                            vierde-prefix-opties)]
        (is (= (mapv bigint ankers) aantallen)
            (str "Insertion 4-prefix " lengten))
        (is (= totaal (reduce +' 0N aantallen)))
        (when (< totaal 10000N)
          (let [familie (orakel/weaving-family lengten)
                woorden (mapv #((:unrank1 familie) %)
                              (range 1 (inc totaal)))]
            (is (= totaal ((:count familie))))
            (doseq [[prefix aantal] (map vector vierde-prefix-opties aantallen)]
              (is (= aantal
                     (bigint (count
                              (filter #(= prefix (mapv bigint (take 4 %)))
                                      woorden))))
                  (str "Brute vierletterprefix " lengten " " prefix)))))))))

(deftest vierde-positie-grensrangen
  (testing "Elk begin/einde van een niet-lege prefixklasse; ook maand-1-afsluiting."
    (doseq [lengten [[4 4] [4 4 4] [4 5 4] [5 4 4] [4 4 4 4]]]
      (let [familie (orakel/weaving-family lengten)
            totaal ((:count familie))
            aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                            vierde-prefix-opties)
            grenzen (vec (reductions +' 0N aantallen))
            rangen (distinct
                    (filter #(<= 1N % totaal)
                            (mapcat (fn [[laag hoog]] [(inc laag) hoog])
                                    (partition 2 1 grenzen))))]
        (doseq [r rangen]
          (let [bewijs (rang/vierde-maand-op-rang-groot
                        lengten r 5000000N)
                verwacht (mapv bigint (take 4 ((:unrank1 familie) r)))
                maand (peek verwacht)]
            (is (= verwacht (:month-prefix bewijs))
                (str "4-prefix " lengten " rang " r))
            (is (= maand (:month-id bewijs)))
            (is (= (bigint (count (filter #(= maand %) verwacht)))
                   (:day-in-month bewijs)))
            (is (<= 0N (:prefix-cell-upper-bound bewijs) 5000000N))
            (is (= :fourth-day-prefix-only (:date-proof-scope bewijs)))
            (is (false? (:month-weaving-computed? bewijs)))))))))

(deftest vierde-prefix-budget-en-rang-weigeringen
  (let [fout (fn [l r b]
               (try
                 (rang/vierde-maand-op-rang-groot l r b)
                 nil
                 (catch clojure.lang.ExceptionInfo e
                   (:code (ex-data e)))))]
    (is (= :fourth-day-prefix-budget-unproven
           (fout [4 4 4] 1N 1N)))
    (is (= :invalid-weaving-rank (fout [4 4 4] 0N 5000000N)))
    (is (= :invalid-weaving-budget (fout [4 4 4] 1N 5000001N)))))

(deftest echte-vierde-jaardag-met-onafhankelijke-prefix-oracle
  (testing "Drie echte vierde jaardagen en zelfstandige vijfveldige berekening."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            vierde (+' (:open-gate-day jaar) 4N)
            uitkomst (projectie/kies-vierde-dag-zonder-weving
                      @lijn berekening vierde 128N 5000000N)
            vijf (:date-components uitkomst)
            prefix (:month-prefix uitkomst)
            staat (orakel/new-gate-state)
            normjaar (orakel/find-target-year staat berekening vierde)
            saus (orakel/sauce berekening (inc (:open-gate-day normjaar)))
            kotelet-aantal (orakel/choose-cutlet-count saus normjaar)
            partitie (orakel/choose-cutlet-partition
                      staat berekening saus normjaar kotelet-aantal)
            kotelet-namen (orakel/choose-cutlet-names saus kotelet-aantal)
            koteletten (orakel/materialize-cutlets
                       staat normjaar partitie kotelet-namen)
            norm-kotelet (some #(when (<= (:first-day %) vierde (:last-day %)) %)
                               koteletten)
            norm-maand-aantal (orakel/choose-month-count saus normjaar)
            norm-lengten (orakel/choose-month-lengths
                          saus normjaar norm-maand-aantal)
            norm-namen (orakel/choose-month-names saus norm-maand-aantal)
            derde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                 derde-prefix-opties)
            norm-totaal (reduce +' 0N derde-aantallen)
            norm-rang (orakel/choose-rank
                       (orakel/ask-bowl saus 4 orakel/seal-month-weaving)
                       norm-totaal)
            derde-keuze (kies-onafhankelijk-prefixblok
                         derde-prefix-opties derde-aantallen norm-rang)
            kinderen (filterv #(= (:prefix derde-keuze) (subvec % 0 3))
                              vierde-prefix-opties)
            kind-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                 kinderen)
            vierde-keuze (kies-onafhankelijk-prefixblok
                          kinderen kind-aantallen (:rest-rank derde-keuze))
            norm-prefix (:prefix vierde-keuze)
            norm-maand (peek norm-prefix)
            verwacht [(:number normjaar)
                      (:name-index norm-kotelet)
                      (inc (-' vierde (:first-day norm-kotelet)))
                      (nth norm-namen (dec (int norm-maand)))
                      (bigint (count (filter #(= norm-maand %) norm-prefix)))]]
        (is (= (get (zipmap derde-prefix-opties derde-aantallen)
                    (:prefix derde-keuze))
               (reduce +' 0N kind-aantallen)))
        (is (= norm-totaal (weving/aantal-wevingen-groot norm-lengten)))
        (is (<= 1N norm-rang norm-totaal))
        (is (= norm-prefix prefix))
        (is (= verwacht vijf))
        (is (= 4 (count prefix)))
        (is (= 1N (first prefix)))
        (is (= :fourth-day-prefix-only (:date-proof-scope uitkomst)))
        (is (false? (:month-weaving-computed? uitkomst)))
        (is (not (contains? uitkomst :month-weaving)))
        (is (<= 0N (:month-prefix-cell-upper-bound uitkomst) 5000000N))
        (println "DISCOVERY24 DIAG08 echte vierde jaardag:"
                 {:berekening berekening :doel vierde
                  :prefix prefix
                  :kosten (:month-prefix-cell-upper-bound uitkomst)
                  :onafhankelijk-gelijk? (= verwacht vijf)})
        (let [code (try
                     (projectie/kies-vierde-dag-zonder-weving
                      @lijn berekening (inc vierde) 128N 5000000N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-fourth-day-of-year code)))))))


;; DIAG09: fifth-day opt-in. The test oracle uses month insertion, not
;; production's remaining-state rank counter. Closing order matters now.
(def ^:private vijfde-prefix-opties
  (vec (mapcat (fn [prefix]
                 (mapv #(conj prefix (bigint %))
                       (range 1 (+ 2 (apply max prefix)))))
               vierde-prefix-opties)))

(deftest vijfde-prefix-oracle-kleine-woorden
  (testing "52 RGS-prefixklassen; vier volledige kleine woordenfamilies."
    (is (= 52 (count vijfde-prefix-opties)))
    (doseq [[lengten totaal] [[[4 4] 20N] [[4 4 4] 1301N]
                             [[4 5 4] 3499N] [[5 4 4] 3101N]]]
      (let [familie (orakel/weaving-family lengten)
            woorden (mapv #((:unrank1 familie) %)
                          (range 1 (inc totaal)))
            aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                            vijfde-prefix-opties)]
        (is (= totaal ((:count familie))))
        (is (= totaal (reduce +' 0N aantallen)))
        (doseq [[prefix aantal] (map vector vijfde-prefix-opties aantallen)]
          (is (= aantal
                 (bigint (count (filter
                                 #(= prefix (mapv bigint (take 5 %)))
                                 woorden))))
              (str "Independent fifth-prefix " lengten " " prefix))))))
  (testing "Grotere familie: vijf onafhankelijk brute-geankerde gevallen."
    (let [lengten [4 4 4 4]
          aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                          vijfde-prefix-opties)
          per-prefix (zipmap vijfde-prefix-opties aantallen)]
      (is (= 177260N (reduce +' 0N aantallen)))
      (doseq [[prefix verwacht]
              [[[1N 1N 1N 1N 1N] 0N]
               [[1N 1N 1N 1N 2N] 1301N]
               [[1N 2N 2N 2N 2N] 0N]
               [[1N 2N 3N 4N 5N] 0N]
               [[1N 1N 2N 3N 4N] 5670N]]]
        (is (= verwacht (get per-prefix prefix)))))))

(deftest vijfde-prefix-grenzen-kleine-families
  (testing "Alle beide kanten van niet-lege klassengrenzen voor kleine families."
    (doseq [lengten [[4 4] [4 4 4] [4 5 4] [5 4 4]]]
      (let [familie (orakel/weaving-family lengten)
            totaal ((:count familie))
            aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                            vijfde-prefix-opties)
            grenzen (vec (reductions +' 0N aantallen))
            rangen (distinct
                    (filter #(<= 1N % totaal)
                            (mapcat (fn [[laag hoog]] [(inc laag) hoog])
                                    (partition 2 1 grenzen))))]
        (doseq [r rangen]
          (let [bewijs (rang/vijfde-maand-op-rang-groot
                        lengten r 5000000N)
                verwacht (mapv bigint (take 5 ((:unrank1 familie) r)))
                maand (peek verwacht)]
            (is (= verwacht (:month-prefix bewijs))
                (str "5-prefix " lengten " rank " r))
            (is (= maand (:month-id bewijs)))
            (is (= (bigint (count (filter #(= maand %) verwacht)))
                   (:day-in-month bewijs)))
            (is (<= 0N (:prefix-cell-upper-bound bewijs) 5000000N))
            (is (= :fifth-day-prefix-only (:date-proof-scope bewijs)))
            (is (false? (:month-weaving-computed? bewijs)))))))))

(deftest vijfde-prefix-sloten-en-budgetpoort
  (let [code (fn [l r b]
               (try
                 (rang/vijfde-maand-op-rang-groot l r b)
                 nil
                 (catch clojure.lang.ExceptionInfo e
                   (:code (ex-data e)))))]
    (is (= :fifth-day-prefix-budget-unproven (code [4 4 4] 1N 1N)))
    (is (= :invalid-weaving-rank (code [4 4 4] 0N 5000000N)))
    (is (= :invalid-weaving-budget (code [4 4 4] 1N 5000001N)))
    (is (zero? (onafhankelijke-prefix-telling [4 4 4]
                                              [1N 2N 2N 2N 2N])))
    (is (= 35N (onafhankelijke-prefix-telling [4 5 4]
                                            [1N 2N 2N 2N 2N])))
    (is (= 20N (onafhankelijke-prefix-telling [5 4 4]
                                            [1N 1N 1N 1N 1N])))))

(deftest echte-vijfde-jaardag-met-onafhankelijke-prefix-oracle
  (testing "Drie echte vijfde jaardagen en zelfstandige vijfveldige berekening."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            vijfde (+' (:open-gate-day jaar) 5N)
            uitkomst (projectie/kies-vijfde-dag-zonder-weving
                      @lijn berekening vijfde 128N 5000000N)
            vijf (:date-components uitkomst)
            prefix (:month-prefix uitkomst)
            staat (orakel/new-gate-state)
            normjaar (orakel/find-target-year staat berekening vijfde)
            saus (orakel/sauce berekening (inc (:open-gate-day normjaar)))
            kotelet-aantal (orakel/choose-cutlet-count saus normjaar)
            partitie (orakel/choose-cutlet-partition
                      staat berekening saus normjaar kotelet-aantal)
            kotelet-namen (orakel/choose-cutlet-names saus kotelet-aantal)
            koteletten (orakel/materialize-cutlets
                       staat normjaar partitie kotelet-namen)
            norm-kotelet (some #(when (<= (:first-day %) vijfde (:last-day %)) %)
                               koteletten)
            norm-maand-aantal (orakel/choose-month-count saus normjaar)
            norm-lengten (orakel/choose-month-lengths
                          saus normjaar norm-maand-aantal)
            norm-namen (orakel/choose-month-names saus norm-maand-aantal)
            derde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                 derde-prefix-opties)
            norm-totaal (reduce +' 0N derde-aantallen)
            norm-rang (orakel/choose-rank
                       (orakel/ask-bowl saus 4 orakel/seal-month-weaving)
                       norm-totaal)
            derde-keuze (kies-onafhankelijk-prefixblok
                         derde-prefix-opties derde-aantallen norm-rang)
            kinderen (filterv #(= (:prefix derde-keuze) (subvec % 0 3))
                              vierde-prefix-opties)
            kind-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                 kinderen)
            vierde-keuze (kies-onafhankelijk-prefixblok
                          kinderen kind-aantallen (:rest-rank derde-keuze))
            vijfde-kinderen (filterv #(= (:prefix vierde-keuze) (subvec % 0 4))
                                    vijfde-prefix-opties)
            vijfde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                   vijfde-kinderen)
            vijfde-keuze (kies-onafhankelijk-prefixblok
                          vijfde-kinderen vijfde-aantallen
                          (:rest-rank vierde-keuze))
            norm-prefix (:prefix vijfde-keuze)
            norm-maand (peek norm-prefix)
            verwacht [(:number normjaar)
                      (:name-index norm-kotelet)
                      (inc (-' vijfde (:first-day norm-kotelet)))
                      (nth norm-namen (dec (int norm-maand)))
                      (bigint (count (filter #(= norm-maand %) norm-prefix)))]]
        (is (= (get (zipmap derde-prefix-opties derde-aantallen)
                    (:prefix derde-keuze))
               (reduce +' 0N kind-aantallen)))
        (is (= (get (zipmap kinderen kind-aantallen) (:prefix vierde-keuze))
               (reduce +' 0N vijfde-aantallen)))
        (is (= norm-totaal (weving/aantal-wevingen-groot norm-lengten)))
        (is (<= 1N norm-rang norm-totaal))
        (is (= norm-prefix prefix))
        (is (= verwacht vijf))
        (is (= 5 (count prefix)))
        (is (= 1N (first prefix)))
        (is (= :fifth-day-prefix-only (:date-proof-scope uitkomst)))
        (is (false? (:month-weaving-computed? uitkomst)))
        (is (not (contains? uitkomst :month-weaving)))
        (is (<= 0N (:month-prefix-cell-upper-bound uitkomst) 5000000N))
        (println "DISCOVERY24 DIAG09 echte vijfde jaardag:"
                 {:berekening berekening :doel vijfde
                  :prefix prefix
                  :kosten (:month-prefix-cell-upper-bound uitkomst)
                  :onafhankelijk-gelijk? (= verwacht vijf)})
        (let [code (try
                     (projectie/kies-vijfde-dag-zonder-weving
                      @lijn berekening (inc vijfde) 128N 5000000N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-fifth-day-of-year code)))))))
;; DISCOVERY24 DIAG10: zesde dag met onafhankelijke insertion-oracle.
(def ^:private zesde-prefix-opties
  (vec (mapcat (fn [prefix]
                 (mapv #(conj prefix (bigint %))
                       (range 1 (+ 2 (apply max prefix)))))
               vijfde-prefix-opties)))

(deftest zesde-prefix-oracle-kleine-woorden
  (testing "203 restricted-growth-klassen tegen volledige kleine normatieve woorden."
    (is (= 203 (count zesde-prefix-opties)))
    (doseq [[lengten totaal] [[[4 4] 20N] [[4 4 4] 1301N]
                             [[4 5 4] 3499N] [[5 4 4] 3101N]]]
      (let [familie (orakel/weaving-family lengten)
            woorden (mapv #((:unrank1 familie) %)
                          (range 1 (inc totaal)))
            aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                            zesde-prefix-opties)]
        (is (= totaal ((:count familie))))
        (is (= totaal (reduce +' 0N aantallen)))
        (doseq [[prefix aantal] (map vector zesde-prefix-opties aantallen)]
          (is (= aantal
                 (bigint (count (filter
                                 #(= prefix (mapv bigint (take 6 %)))
                                 woorden))))
              (str "Independent sixth-prefix " lengten " " prefix))))))
  (testing "Vier-maands grote familie, vijf vaste brute-ankers."
    (let [lengten [4 4 4 4]
          aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                          zesde-prefix-opties)
          per-prefix (zipmap zesde-prefix-opties aantallen)]
      (is (= 177260N (reduce +' 0N aantallen)))
      (doseq [[prefix verwacht]
              [[[1N 1N 1N 1N 2N 2N] 461N]
               [[1N 2N 3N 4N 4N 4N] 280N]
               [[1N 1N 2N 3N 4N 4N] 1134N]
               [[1N 2N 2N 3N 3N 4N] 864N]
               [[1N 2N 3N 4N 5N 6N] 0N]]]
        (is (= verwacht (get per-prefix prefix)))))))

(deftest zesde-prefix-alle-grensrangen
  (testing "Elke bereikbare zesletterklasse met beide lexicografische randen."
    (doseq [lengten [[4 4] [4 4 4] [4 5 4] [5 4 4]]]
      (let [familie (orakel/weaving-family lengten)
            totaal ((:count familie))
            aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                            zesde-prefix-opties)
            grenzen (vec (reductions +' 0N aantallen))
            rangen (distinct
                    (filter #(<= 1N % totaal)
                            (mapcat (fn [[laag hoog]] [(inc laag) hoog])
                                    (partition 2 1 grenzen))))]
        (doseq [r rangen]
          (let [bewijs (rang/zesde-maand-op-rang-groot
                        lengten r 5000000N)
                verwacht (mapv bigint (take 6 ((:unrank1 familie) r)))
                maand (peek verwacht)]
            (is (= verwacht (:month-prefix bewijs))
                (str "6-prefix " lengten " rank " r))
            (is (= maand (:month-id bewijs)))
            (is (= (bigint (count (filter #(= maand %) verwacht)))
                   (:day-in-month bewijs)))
            (is (<= 0N (:prefix-cell-upper-bound bewijs) 5000000N))
            (is (= :sixth-day-prefix-only (:date-proof-scope bewijs)))
            (is (false? (:month-weaving-computed? bewijs)))))))))

(deftest zesde-prefix-gesloten-maanden-en-budget
  (let [code (fn [l r b]
               (try
                 (rang/zesde-maand-op-rang-groot l r b)
                 nil
                 (catch clojure.lang.ExceptionInfo e
                   (:code (ex-data e)))))]
    (is (= :sixth-day-prefix-budget-unproven (code [4 4 4] 1N 1N)))
    (is (= :invalid-weaving-rank (code [4 4 4] 0N 5000000N)))
    (is (= :invalid-weaving-budget (code [4 4 4] 1N 5000001N)))
    (is (zero? (onafhankelijke-prefix-telling [4 4 4]
                                              [1N 2N 2N 2N 2N 2N])))
    (is (= 461N (onafhankelijke-prefix-telling [4 4 4 4]
                                            [1N 1N 1N 1N 2N 2N])))))

(deftest echte-zesde-jaardag-met-onafhankelijke-prefix-oracle
  (testing "Drie echte zesde jaardagen: vijf onafhankelijke datumvelden."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            zesde (+' (:open-gate-day jaar) 6N)
            uitkomst (projectie/kies-zesde-dag-zonder-weving
                      @lijn berekening zesde 128N 5000000N)
            velden (:date-components uitkomst)
            prefix (:month-prefix uitkomst)
            staat (orakel/new-gate-state)
            normjaar (orakel/find-target-year staat berekening zesde)
            saus (orakel/sauce berekening (inc (:open-gate-day normjaar)))
            kotelet-aantal (orakel/choose-cutlet-count saus normjaar)
            partitie (orakel/choose-cutlet-partition
                      staat berekening saus normjaar kotelet-aantal)
            kotelet-namen (orakel/choose-cutlet-names saus kotelet-aantal)
            koteletten (orakel/materialize-cutlets
                       staat normjaar partitie kotelet-namen)
            norm-kotelet (some #(when (<= (:first-day %) zesde (:last-day %)) %)
                               koteletten)
            norm-maand-aantal (orakel/choose-month-count saus normjaar)
            norm-lengten (orakel/choose-month-lengths
                          saus normjaar norm-maand-aantal)
            norm-namen (orakel/choose-month-names saus norm-maand-aantal)
            derde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                 derde-prefix-opties)
            norm-totaal (reduce +' 0N derde-aantallen)
            norm-rang (orakel/choose-rank
                       (orakel/ask-bowl saus 4 orakel/seal-month-weaving)
                       norm-totaal)
            derde-keuze (kies-onafhankelijk-prefixblok
                         derde-prefix-opties derde-aantallen norm-rang)
            vierde-kinderen (filterv #(= (:prefix derde-keuze) (subvec % 0 3))
                                    vierde-prefix-opties)
            vierde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                  vierde-kinderen)
            vierde-keuze (kies-onafhankelijk-prefixblok
                          vierde-kinderen vierde-aantallen (:rest-rank derde-keuze))
            vijfde-kinderen (filterv #(= (:prefix vierde-keuze) (subvec % 0 4))
                                   vijfde-prefix-opties)
            vijfde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                  vijfde-kinderen)
            vijfde-keuze (kies-onafhankelijk-prefixblok
                          vijfde-kinderen vijfde-aantallen (:rest-rank vierde-keuze))
            zesde-kinderen (filterv #(= (:prefix vijfde-keuze) (subvec % 0 5))
                                   zesde-prefix-opties)
            zesde-aantallen (mapv #(onafhankelijke-prefix-telling norm-lengten %)
                                 zesde-kinderen)
            zesde-keuze (kies-onafhankelijk-prefixblok
                         zesde-kinderen zesde-aantallen (:rest-rank vijfde-keuze))
            norm-prefix (:prefix zesde-keuze)
            norm-maand (peek norm-prefix)
            verwacht [(:number normjaar)
                      (:name-index norm-kotelet)
                      (inc (-' zesde (:first-day norm-kotelet)))
                      (nth norm-namen (dec (int norm-maand)))
                      (bigint (count (filter #(= norm-maand %) norm-prefix)))]]
        (is (= norm-totaal (weving/aantal-wevingen-groot norm-lengten)))
        (is (= (get (zipmap vierde-kinderen vierde-aantallen)
                    (:prefix vierde-keuze))
               (reduce +' 0N vijfde-aantallen)))
        (is (= (get (zipmap vijfde-kinderen vijfde-aantallen)
                    (:prefix vijfde-keuze))
               (reduce +' 0N zesde-aantallen)))
        (is (= norm-prefix prefix))
        (is (= verwacht velden))
        (is (= 5 (count velden)))
        (is (= 6 (count prefix)))
        (is (= :sixth-day-prefix-only (:date-proof-scope uitkomst)))
        (is (false? (:month-weaving-computed? uitkomst)))
        (is (not (contains? uitkomst :month-weaving)))
        (is (<= 0N (:month-prefix-cell-upper-bound uitkomst) 5000000N))
        (println "DISCOVERY24 DIAG10 echte zesde jaardag:"
                 {:berekening berekening :doel zesde
                  :prefix prefix :kosten (:month-prefix-cell-upper-bound uitkomst)
                  :onafhankelijk-gelijk? (= verwacht velden)})
        (let [code (try
                     (projectie/kies-zesde-dag-zonder-weving
                      @lijn berekening (inc zesde) 128N 5000000N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-sixth-day-of-year code)))))))

;; DISCOVERY24 DIAG11: zevende positie, zonder hoger productiecelbudget.
(def ^:private zevende-prefix-opties
  (vec (mapcat (fn [prefix]
                 (mapv #(conj prefix (bigint %))
                       (range 1 (+ 2 (apply max prefix)))))
               zesde-prefix-opties)))

(deftest zevende-prefix-alle-normatieve-overgangen
  (testing "Alle overgangen van de zevende prefix voor vier kleine families."
    (doseq [[lengten totaal] [[[4 4] 20N] [[4 4 4] 1301N]
                             [[4 5 4] 3499N] [[5 4 4] 3101N]]]
      (let [familie (orakel/weaving-family lengten)
            woorden (mapv #((:unrank1 familie) %)
                          (range 1 (inc totaal)))
            prefixes (mapv #(mapv bigint (take 7 %)) woorden)
            overgangen (->> (range 1 (count prefixes))
                            (mapcat (fn [i]
                                      (if (not= (nth prefixes (dec i))
                                                (nth prefixes i))
                                        [i (inc i)] []))))
            rangen (distinct (concat [1 (count prefixes)] overgangen))]
        (is (= totaal ((:count familie))))
        (doseq [r rangen]
          (let [bewijs (rang/zevende-maand-op-rang-groot
                        lengten r 5000000N)
                verwacht (nth prefixes (dec r))
                maand (peek verwacht)]
            (is (= verwacht (:month-prefix bewijs))
                (str "DIAG11 seventh prefix " lengten " rank " r))
            (is (= maand (:month-id bewijs)))
            (is (= (bigint (count (filter #(= maand %) verwacht)))
                   (:day-in-month bewijs)))
            (is (<= 0N (:prefix-cell-upper-bound bewijs) 5000000N))
            (is (= :seventh-day-prefix-only (:date-proof-scope bewijs)))
            (is (false? (:month-weaving-computed? bewijs)))))))))

(deftest zevende-prefix-grote-familie-en-budget
  (let [familie (orakel/weaving-family [4 4 4 4])
        totaal ((:count familie))
        fout (fn [lengten r b]
               (try
                 (rang/zevende-maand-op-rang-groot lengten r b)
                 nil
                 (catch clojure.lang.ExceptionInfo e
                   (:code (ex-data e)))))]
    (is (= 177260N totaal))
    (doseq [r [1N 2N 88630N 177259N 177260N]]
      (let [bewijs (rang/zevende-maand-op-rang-groot [4 4 4 4] r)
            verwacht (mapv bigint (take 7 ((:unrank1 familie) r)))]
        (is (= verwacht (:month-prefix bewijs)))
        (is (<= (:prefix-cell-upper-bound bewijs) 5000000N))))
    (is (= :seventh-day-prefix-budget-unproven
           (fout [4 4 4] 1N 1N)))
    (is (= :invalid-weaving-rank
           (fout [4 4 4] 0N 5000000N)))
    (is (= :invalid-weaving-budget
           (fout [4 4 4] 1N 5000001N)))))

(deftest echte-zevende-jaardag-met-onafhankelijke-insertion-oracle
  (testing "Drie echte zevende dagen: bewijs OF begrensde expliciete weigering."
    (doseq [berekening [dagen/stichtingsdag
                       (+' dagen/stichtingsdag 17N)
                       (-' dagen/stichtingsdag 23N)]]
      (let [jaar (zoeken/vind-doeljaar @lijn berekening berekening)
            doel (+' (:open-gate-day jaar) 7N)
            staat (orakel/new-gate-state)
            normjaar (orakel/find-target-year staat berekening doel)
            saus (orakel/sauce berekening (inc (:open-gate-day normjaar)))
            aantal-koteletten (orakel/choose-cutlet-count saus normjaar)
            partitie (orakel/choose-cutlet-partition
                      staat berekening saus normjaar aantal-koteletten)
            kotelet-namen (orakel/choose-cutlet-names saus aantal-koteletten)
            koteletten (orakel/materialize-cutlets
                        staat normjaar partitie kotelet-namen)
            kotelet (some #(when (<= (:first-day %) doel (:last-day %)) %)
                         koteletten)
            aantal-maanden (orakel/choose-month-count saus normjaar)
            lengten (orakel/choose-month-lengths saus normjaar aantal-maanden)
            maandnamen (orakel/choose-month-names saus aantal-maanden)
            derde-aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                                 derde-prefix-opties)
            totaal (reduce +' 0N derde-aantallen)
            rang (orakel/choose-rank
                  (orakel/ask-bowl saus 4 orakel/seal-month-weaving)
                  totaal)
            normprefix
            (loop [diepte 3 huidige nil lokale-rang rang]
              (let [alle (case diepte
                           3 derde-prefix-opties
                           4 vierde-prefix-opties
                           5 vijfde-prefix-opties
                           6 zesde-prefix-opties
                           7 zevende-prefix-opties)
                    kinderen (if huidige
                               (filterv #(= (:prefix huidige)
                                            (subvec % 0 (dec diepte))) alle)
                               alle)
                    aantallen (mapv #(onafhankelijke-prefix-telling lengten %)
                                   kinderen)
                    keuze (kies-onafhankelijk-prefixblok
                           kinderen aantallen lokale-rang)]
                (if (= diepte 7)
                  (:prefix keuze)
                  (recur (inc diepte) keuze (:rest-rank keuze)))))
            maand (peek normprefix)
            verwacht [(:number normjaar)
                      (:name-index kotelet)
                      (inc (-' doel (:first-day kotelet)))
                      (nth maandnamen (dec (int maand)))
                      (bigint (count (filter #(= maand %) normprefix)))]
            poging (try
                     {:status :bewezen
                      :uitkomst (projectie/kies-zevende-dag-zonder-weving
                                 @lijn berekening doel 128N 5000000N)}
                     (catch clojure.lang.ExceptionInfo e
                       {:status :geweigerd :code (:code (ex-data e))}))]
        (is (= totaal (weving/aantal-wevingen-groot lengten)))
        (is (= 7 (count normprefix)))
        (if (= :bewezen (:status poging))
          (let [uitkomst (:uitkomst poging)]
            (is (= verwacht (:date-components uitkomst)))
            (is (= normprefix (:month-prefix uitkomst)))
            (is (= 5 (count (:date-components uitkomst))))
            (is (= :seventh-day-prefix-only (:date-proof-scope uitkomst)))
            (is (false? (:month-weaving-computed? uitkomst)))
            (is (not (contains? uitkomst :month-weaving)))
            (is (<= 0N (:month-prefix-cell-upper-bound uitkomst) 5000000N))
            (println "DISCOVERY24 DIAG11 echte zevende jaardag:"
                     {:berekening berekening :doel doel
                      :prefix normprefix
                      :kosten (:month-prefix-cell-upper-bound uitkomst)
                      :onafhankelijk-gelijk? (= verwacht (:date-components uitkomst))}))
          (do
            (is (= :seventh-day-prefix-budget-unproven (:code poging)))
            (println "DISCOVERY24 DIAG11 echte zevende jaardag geweigerd:"
                     {:berekening berekening :doel doel :code (:code poging)})))
        (let [code (try
                     (projectie/kies-zevende-dag-zonder-weving
                      @lijn berekening (inc doel) 128N 5000000N)
                     nil
                     (catch clojure.lang.ExceptionInfo e
                       (:code (ex-data e))))]
          (is (= :target-not-seventh-day-of-year code)))))))
