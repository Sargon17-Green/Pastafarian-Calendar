(ns pastafari.discovery24-dp-feasibility-test
  (:require [clojure.string :as string]
            [pastafari.dagfundament :as dagen]
            [pastafari.poortposities :as poorten]
            [pastafari.maandlengtes :as production-lengths]
            [pastafari.maandweving :as weving]
            [pastafari.normative-oracle :as oracle]))

(def ^:private project-id "PC-BRANCH-CLOJURE-DUTCH")
(def ^:private calculation-day -15055654N)
(def ^:private search-budget 128N)

(defn- eis! [condition code details]
  (when-not condition
    (throw (ex-info "DISCOVERY24 canonical DP input invariant"
                    (assoc details :code code)))))

(defn- json-array [values]
  (str "[" (string/join "," (map str values)) "]"))

(defn write-canonical-input! []
  (let [source-sha (System/getenv "GITHUB_SHA")
        _ (eis! (and source-sha
                     (re-matches #"[0-9a-f]{40}" source-sha))
                :missing-source-sha {:source-sha source-sha})
        _ (eis! (= calculation-day (+' dagen/stichtingsdag 17N))
                :calculation-anchor-drift
                {:calculation-day calculation-day
                 :foundation-day dagen/stichtingsdag})
        production-line (poorten/bouw-poortlijn search-budget)
        production-selection
        (production-lengths/kies-maandlengtes
         production-line calculation-day calculation-day search-budget)
        production-year (:year production-selection)
        norm-state (oracle/new-gate-state)
        norm-year (oracle/find-target-year
                   norm-state calculation-day calculation-day)
        first-day (inc (:open-gate-day norm-year))
        structure-sauce (oracle/sauce calculation-day first-day)
        month-count (oracle/choose-month-count structure-sauce norm-year)
        profile (mapv bigint
                      (oracle/choose-month-lengths
                       structure-sauce norm-year month-count))
        production-profile (mapv bigint (:month-lengths production-selection))
        total (weving/aantal-wevingen-groot profile)
        weaving-stream (oracle/ask-bowl
                        structure-sauce 4N oracle/seal-month-weaving)
        rank (oracle/choose-rank weaving-stream total)
        year-matches?
        (and (= (:number production-year) (:number norm-year))
             (= (:open-gate-index production-year)
                (:open-gate-index norm-year))
             (= (:close-gate-index production-year)
                (:close-gate-index norm-year))
             (= (:open-gate-day production-year)
                (:open-gate-day norm-year))
             (= (:close-gate-day production-year)
                (:close-gate-day norm-year)))
        profile-matches? (= production-profile profile)
        duration (-' (:close-gate-day norm-year)
                     (:open-gate-day norm-year))
        _ (eis! (and year-matches?
                     (= 5000N (:number norm-year))
                     (= month-count (:month-count production-selection))
                     profile-matches?
                     (= month-count (count profile))
                     (<= 3 (count profile) 47)
                     (every? #(<= 4N % 123N) profile)
                     (= duration (reduce +' 0N profile))
                     (pos? total)
                     (<= 1N rank total))
                :canonical-input-cross-check-failed
                {:normative-year norm-year
                 :production-year production-year
                 :normative-month-count month-count
                 :production-month-count (:month-count production-selection)
                 :normative-profile profile
                 :production-profile production-profile
                 :total total :rank rank})
        payload
        (str "{"
             "\"project_id\":\"" project-id "\","
             "\"source_sha\":\"" source-sha "\","
             "\"calculation_day\":\"" calculation-day "\","
             "\"target_day\":\"" calculation-day "\","
             "\"target_year\":\"" (:number norm-year) "\","
             "\"year_open_gate_index\":\"" (:open-gate-index norm-year) "\","
             "\"year_close_gate_index\":\"" (:close-gate-index norm-year) "\","
             "\"year_open_gate_day\":\"" (:open-gate-day norm-year) "\","
             "\"year_close_gate_day\":\"" (:close-gate-day norm-year) "\","
             "\"first_day\":\"" first-day "\","
             "\"search_budget\":" search-budget ","
             "\"month_count\":" month-count ","
             "\"profile\":" (json-array profile) ","
             "\"weaving_total\":\"" total "\","
             "\"weaving_rank\":\"" rank "\","
             "\"profile_source\":\"normative-oracle/choose-month-lengths\","
             "\"rank_source\":\"normative-oracle/choose-rank over exact production family count\","
             "\"normative_oracle_blob_sha\":\"5b2f486a12aeb8ff3cea0d762ba26882d67fb4cc\","
             "\"production_month_lengths_blob_sha\":\"7f87252e1bf17425e2bad73b3c56531f309e059e\","
             "\"production_month_count_blob_sha\":\"166b87a11124f0be4594a4b537c1e87d336ba659\","
             "\"production_month_weaving_blob_sha\":\"e3954a4742414435f85c95955f0d319d136877d2\","
             "\"production_year_matches_normative\":true,"
             "\"production_profile_matches_normative\":true"
             "}")
        output-path "qa/clojure-dutch/discovery24_canonical_dp_input.json"]
    (spit output-path payload)
    (println "DISCOVERY24_CANONICAL_DP_INPUT" payload)
    {:path output-path
     :source-sha source-sha
     :year (:number norm-year)
     :profile profile
     :total total
     :rank rank
     :production-cross-check? true}))
