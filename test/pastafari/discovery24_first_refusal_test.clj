(ns pastafari.discovery24-first-refusal-test
  "TEST-ONLY bounded first-refusal accounting. No replacement of production functions."
  (:require [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.doeljaar :as zoeken]
            [pastafari.maandlengtes :as lengtes]
            [pastafari.maandrang :as rang]
            [pastafari.maandweving :as weving]
            [pastafari.normative-oracle :as orakel]))

(def ^:private project-id "PC-BRANCH-CLOJURE-DUTCH")
(def ^:private plafond 5000000N)

(defn- eis! [v code details]
  (when-not v
    (throw (ex-info "DISCOVERY24 first-refusal diagnostic invariant" (assoc details :code code)))))

;; Independent insertion-cell oracle: one base cell plus one histogram
;; coefficient opportunity per unopened month / remaining suffix slot.
;; Deliberately enumerates the Cartesian product instead of using the
;; production prefix-gedeelde-raming arithmetic expression.
(defn- invoeg-cellen [restvector geopend]
  (let [slots (int (reduce +' 0N restvector))]
    (reduce (fn [n _] (inc n))
            1N
            (for [maand (range geopend (count restvector))
                  slot (range slots)]
              [maand slot]))))

(defn- beginstaat [profiel]
  {:rest (update (mapv bigint profiel) 0 dec)
   :geopend 1
   :gesloten 0
   :kosten 0N
   :positie 1N
   :prefix [1N]})

(defn- actieve-opties [staat]
  (let [{:keys [rest geopend gesloten]} staat]
    (vec (for [id (range 1 (inc geopend))
               :let [aantal (nth rest (dec id))]
               :when (and (pos? aantal)
                          (or (> aantal 1) (= id (inc gesloten))))]
           id))))

(defn- volgende-rekening [staat]
  (let [{:keys [rest geopend kosten]} staat
        actief (actieve-opties staat)
        actieve-kosten (if (seq actief)
                         (+' kosten (invoeg-cellen rest geopend))
                         kosten)
        nieuw? (and (< geopend (count rest))
                    (pos? (nth rest geopend))
                    (or (> (nth rest geopend) 1)
                        (= (inc geopend) (inc (:gesloten staat)))))
        nieuwe-kosten (when nieuw?
                        (+' actieve-kosten
                            (invoeg-cellen rest (inc geopend))))]
    {:actief actief
     :nieuwe-kandidaat? (boolean nieuw?)
     :kosten-voor-actief kosten
     :actieve-bovengrens actieve-kosten
     :nieuwe-bovengrens nieuwe-kosten}))

(defn- simuleer-letter [staat id]
  (let [{:keys [rest geopend gesloten positie prefix]} staat
        {:keys [actief nieuwe-kandidaat?
                actieve-bovengrens nieuwe-bovengrens]}
        (volgende-rekening staat)
        nieuw? (= (bigint id) (bigint (inc geopend)))
        vorig (nth rest (dec (int id)))]
    (eis! (and (pos? vorig)
               (or (some #(= id %) actief)
                   (and nieuw? nieuwe-kandidaat?)))
          :illegal-oracle-word {:position (inc positie) :prefix prefix :letter id})
    (assoc staat
           :rest (update rest (dec (int id)) dec)
           :geopend (if nieuw? (inc geopend) geopend)
           :gesloten (if (= 1N vorig) (inc gesloten) gesloten)
           :kosten (if nieuw? nieuwe-bovengrens actieve-bovengrens)
           :positie (inc positie)
           :prefix (conj prefix (bigint id)))))

(defn- kleine-families! []
  ;; All ranks, and EVERY interior position, for three tiny legal families.
  ;; The word oracle constructs complete legal words independently of maandrang.
  (reduce
   (fn [a profiel]
     (let [familie (orakel/weaving-family profiel)
           totaal ((:count familie))
           n (reduce + profiel)]
       (eis! (= totaal (weving/aantal-wevingen-groot profiel))
             :small-total-disagreement {:profile profiel :total totaal})
       (reduce
        (fn [a r]
          (let [woord (mapv bigint ((:unrank1 familie) r))]
            (loop [p 2 toestand (beginstaat profiel) a a]
              (if (= p n)
                a
                (let [volgende (simuleer-letter toestand (nth woord (dec p)))
                      bewijs (rang/prefix-op-rang-begrensd
                              profiel (bigint r) p plafond)]
                  (eis! (and (= (:prefix volgende) (:month-prefix bewijs))
                             (= (:kosten volgende)
                                (:prefix-cell-upper-bound bewijs))
                             (<= 0N (:kosten volgende) plafond))
                        :small-independent-cost-disagreement
                        {:profile profiel :rank r :position p
                         :expected-cost (:kosten volgende)
                         :actual-cost (:prefix-cell-upper-bound bewijs)})
                  (recur (inc p) volgende (inc a)))))))
        a (range 1 (inc (int totaal))))))
   0
   [[4 4] [4 5] [5 4]]))

(defn- meet-prefix [profiel weefrang p]
  (try
    {:status :bewezen
     :waarde (rang/prefix-op-rang-begrensd
              profiel weefrang p plafond)}
    (catch clojure.lang.ExceptionInfo e
      {:status :geweigerd :code (:code (ex-data e))})))

(defn- eerste-weigering [profiel weefrang]
  ;; The already audited artifact at faa37816 establishes refusal at 520,
  ;; with unchanged production blobs. No new call at position 520.
  ;; Bisection probes only STRICTLY SMALLER positions.
  (loop [laatste-goed 1 eerste-slecht 520 pogingen 0]
    (if (= eerste-slecht (inc laatste-goed))
      {:positie eerste-slecht :laatste-goed laatste-goed :probes pogingen}
      (let [p (quot (+ laatste-goed eerste-slecht) 2)
            antwoord (meet-prefix profiel weefrang p)]
        (cond
          (= :bewezen (:status antwoord))
          (recur p eerste-slecht (inc pogingen))

          (= :bounded-prefix-budget-unproven (:code antwoord))
          (recur laatste-goed p (inc pogingen))

          :else (throw (ex-info "Unexpected prefix diagnostic outcome"
                                {:code :unexpected-probe :position p
                                 :outcome antwoord})))))))

(defn- onafhankelijke-staat [profiel prefix]
  (reduce simuleer-letter (beginstaat profiel) (rest prefix)))

(defn- diagnosticeer! []
  (let [berekening (+' dagen/stichtingsdag 17N)
        poortlijn (poorten/bouw-poortlijn 128N)
        selectie (lengtes/kies-maandlengtes
                  poortlijn berekening berekening 128N)
        jaar (:year selectie)
        positie (-' berekening (:open-gate-day jaar))
        profiel (:month-lengths selectie)
        staat (orakel/new-gate-state)
        normjaar (orakel/find-target-year staat berekening berekening)
        saus (orakel/sauce
              berekening (inc (:open-gate-day normjaar)))
        m (orakel/choose-month-count saus normjaar)
        normlengten (orakel/choose-month-lengths saus normjaar m)
        totaal (weving/aantal-wevingen-groot profiel)
        weefrang (orakel/choose-rank
                  (orakel/ask-bowl saus 4 orakel/seal-month-weaving)
                  totaal)]
    (eis! (and (= 5000N (:number jaar) (:number normjaar))
               (= -15055654N berekening)
               (= 520N positie)
               (= m (:month-count selectie) (count profiel))
               (= (mapv bigint profiel) (mapv bigint normlengten))
               (<= 1N weefrang totaal))
          :canonical-input-drift
          {:year (:number jaar) :position positie
           :calculation-day berekening :month-count m})
    (let [kleine-controles (kleine-families!)
          {:keys [positie laatste-goed probes]}
          (eerste-weigering profiel weefrang)
          _ (eis! (< 1 positie 520) :no-earlier-refusal
                  {:first-refusal-position positie})
          voor (meet-prefix profiel weefrang laatste-goed)
          op (meet-prefix profiel weefrang positie)
          _ (eis! (and (= :bewezen (:status voor))
                       (= :bounded-prefix-budget-unproven (:code op)))
                  :first-refusal-not-confirmed
                  {:position positie :before (:status voor) :on op})
          bewijs (:waarde voor)
          prefix (:month-prefix bewijs)
          model (onafhankelijke-staat profiel prefix)
          rekening (volgende-rekening model)
          actief-boven (:actieve-bovengrens rekening)
          nieuw-boven (:nieuwe-bovengrens rekening)
          actief-onveilig? (and (seq (:actief rekening))
                               (> actief-boven plafond))
          nieuw-onveilig? (and (not actief-onveilig?)
                              (:nieuwe-kandidaat? rekening)
                              (some? nieuw-boven)
                              (> nieuw-boven plafond))
          tak (cond actief-onveilig? :shared-active-candidates
                    nieuw-onveilig? :new-month-candidate
                    :else :unexplained-refusal)
          veilig (if actief-onveilig?
                   (:kosten model)
                   actief-boven)
          voorgesteld (if actief-onveilig?
                        actief-boven nieuw-boven)]
      (eis! (and (= (bigint laatste-goed) (:prefix-position bewijs))
                 (= (bigint laatste-goed) (:positie model))
                 (= (mapv bigint prefix) (:prefix model))
                 (= (:kosten model) (:prefix-cell-upper-bound bewijs))
                 (= :bounded-prefix-only (:date-proof-scope bewijs))
                 (false? (:month-weaving-computed? bewijs))
                 (not= tak :unexplained-refusal)
                 (integer? veilig) (integer? voorgesteld)
                 (<= 0N veilig plafond)
                 (< plafond voorgesteld))
            :accounting-oracle-mismatch
            {:position positie :model-cost (:kosten model)
             :production-cost (:prefix-cell-upper-bound bewijs)
             :branch tak :safe veilig :proposed voorgesteld
             :active-options (:actief rekening)})
      {:probe-status :accounting-proven
       :first-refusal-position (bigint positie)
       :last-completed-position (bigint laatste-goed)
       :safe-cost-before-candidate veilig
       :last-completed-prefix-cost (:kosten model)
       :proposed-upper-cost voorgesteld
       :accounting-condition tak
       :active-candidate-count (count (:actief rekening))
       :new-candidate-exists? (:nieuwe-kandidaat? rekening)
       :independent-small-family-comparisons kleine-controles
       :bounded-search-probes probes
       :refusal-code (:code op)
       :five-fields-proven? false
       :full-weaving-computed? false
       :stage2-accepted? false})))

(defn run-discovery24-first-refusal-accounting! []
  (let [pad "qa/discovery24_p520_first_refusal_accounting.edn"
        bron (or (System/getenv "GITHUB_SHA") "UNSET")
        basis {:project-id project-id
               :source-sha bron
               :calculation-day -15055654N
               :target-day -15055654N
               :target-year 5000N
               :target-position 520N
               :search-budget 128N
               :prefix-budget plafond
               :source-reference-sha "faa37816ae4e1384e019d406c62415af7ab028b6"
               :production-unchanged-required? true}]
    (spit pad (pr-str (assoc basis :probe-status :begonnen)))
    (try
      (eis! (and (not= bron "UNSET")
                 (re-matches #"[0-9a-f]{40}" bron))
            :missing-source-sha {:source-sha bron})
      (let [uitkomst (merge basis (diagnosticeer!))]
        (spit pad (pr-str uitkomst))
        (println "DISCOVERY24 P520 FIRST REFUSAL ACCOUNTING" (pr-str uitkomst))
        uitkomst)
      (catch Throwable e
        (let [gegevens (when (instance? clojure.lang.ExceptionInfo e)
                         (ex-data e))]
          (spit pad (pr-str (assoc basis :probe-status :error
                                 :error-code (or (:code gegevens) :unexpected)
                                 :error-data gegevens)))
          (throw e))))))
