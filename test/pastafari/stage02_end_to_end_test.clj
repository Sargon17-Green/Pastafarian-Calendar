(ns pastafari.stage02-end-to-end-test
  (:require [clojure.test :refer [deftest is testing]]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.doeljaar :as zoeken]
            [pastafari.datumprojectie :as projectie]
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
