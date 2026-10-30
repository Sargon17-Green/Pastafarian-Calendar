(ns pastafari.stenen)

;; Exacte residuen van 1 tot en met 2^127 - 1, nooit floating point.
;; Dit is een zelfstandige productielaag; het testorakel is geen dependency.
(def modulus (dec (reduce *' 1N (repeat 127 2N))))

(defn save [waarde]
  (when-not (integer? waarde)
    (throw (ex-info "SAVE verwacht een exact geheel getal."
                    {:code :invalid-save-input :value waarde})))
  (+' 1N (mod (-' waarde 1N) modulus)))

(defn- volgende-steen [vorige nummer]
  (let [[tarwe gerst zout bitter rood] vorige]
    [(save (+' (*' tarwe tarwe) (*' 3N gerst) nummer))
     (save (+' (*' gerst gerst) (*' 5N zout) tarwe))
     (save (+' (*' zout zout) (*' 7N bitter) gerst))
     (save (+' (*' bitter bitter) (*' 11N rood) zout))
     (save (+' (*' rood rood) (*' 13N tarwe) bitter))]))

(defn- bouw-tabel []
  (loop [nummer 2
         tabel [[17N 29N 43N 71N 101N]]]
    (if (> nummer 46)
      tabel
      (recur (inc nummer)
             (conj tabel (volgende-steen (peek tabel) nummer))))))

(def stenen (bouw-tabel))

(defn steen [nummer]
  (when-not (and (integer? nummer) (<= 1 nummer 46))
    (throw (ex-info "Steenindex moet van 1 tot en met 46 lopen."
                    {:code :invalid-stone-index :index nummer})))
  (nth stenen (dec nummer)))
