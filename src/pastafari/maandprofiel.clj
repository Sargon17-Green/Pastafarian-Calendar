(ns pastafari.maandprofiel)

;; DISCOVERY20: een conservatieve budgetgarantie, geen CPU-tijdgarantie.
;; In maandrang kost iedere onderzochte kandidaat ten hoogste
;; 1+(m+1)*(N+1) geraamde cellen. Per van de N posities zijn er
;; ten hoogste m onderzochte kandidaten.
(def ^:private standaardbegroting 5000000N)

(defn- fout [code]
  (throw (ex-info "Maandprofiel buiten bewezen domein." {:code code})))

(defn veilige-celgrens
  "Geeft een voldoende (niet noodzakelijke) budgetvoorwaarde voor ELKE
   geldige rang. Bewijst niets over looptijd, geheugen of de vijfdelige datum."
  ([lengtes]
   (veilige-celgrens lengtes standaardbegroting))
  ([lengtes begroting]
   (when-not (and (sequential? lengtes)
                  (seq lengtes)
                  (every? #(and (integer? %) (<= 4N % 123N)) lengtes))
     (fout :invalid-weaving-family))
   (let [m (count lengtes)
         n (reduce +' 0N lengtes)]
     (when (or (> m 47) (> n 5778N))
       (fout :weaving-bound-exceeded))
     (when-not (and (integer? begroting) (<= 1N begroting 5000000N))
       (fout :invalid-weaving-budget))
     (let [grens (*' n m (+' 1N (*' (inc m) (inc n))))]
       {:maanden m
        :dagen n
        :celbovengrens grens
        :begroting begroting
        :budgetveilig? (<= grens begroting)
        :looptijd-bewezen? false}))))
