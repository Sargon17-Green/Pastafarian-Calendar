(ns pastafari.stage02-end-to-end-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.doeljaar :as zoeken]
            [pastafari.datumprojectie :as projectie]
            [pastafari.maandrang :as rang]
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
