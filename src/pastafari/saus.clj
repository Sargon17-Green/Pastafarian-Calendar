(ns pastafari.saus
  (:require [pastafari.stenen :as stenen]))

;; Zelfstandige productiecode: het normatieve orakel blijft uitsluitend in tests.
(def ^:private priemen [17N 19N 23N 29N 31N 37N])
(def ^:private roersoorten [0 1 2 3 4 0])
(def ^:private factoren [120N 24N 6N 2N 1N 1N])

(defn- controleer [tellingen druppels]
  (when-not (and (map? tellingen)
                 (every? (fn [sleutel]
                           (let [v (get tellingen sleutel)]
                             (and (integer? v) (pos? v))))
                         [:action :target :distance :connection :direction])
                 (<= 1N (:direction tellingen) 3N)
                 (vector? druppels)
                 (= 46 (count druppels))
                 (every? (fn [x]
                           (and (integer? x) (<= 1N x stenen/modulus)))
                         druppels))
    (throw (ex-info "Ongeldige saus-invoer." {:code :invalid-sauce-input}))))

(defn- kwadraat [x] (*' x x))
(defn- kom [kommen id] (nth kommen (dec id)))

(defn- komvolgorde [waarde]
  (let [rang (dec (inc (mod (dec waarde) 720N)))]
    (loop [over [1 2 3 4 5 6]
           blokken factoren
           rest-rang rang
           uitkomst []]
      (if (empty? blokken)
        uitkomst
        (let [blok (first blokken)
              index (int (quot rest-rang blok))
              id (nth over index)]
          (recur (vec (concat (subvec over 0 index)
                              (subvec over (inc index))))
                 (rest blokken)
                 (mod rest-rang blok)
                 (conj uitkomst id)))))))

(defn- begin-kommen [tellingen]
  (mapv (fn [id]
          (let [p (nth priemen (dec id))
                som (+' (:action tellingen)
                        (*' (:target tellingen) id)
                        (:distance tellingen)
                        (:connection tellingen)
                        (:direction tellingen)
                        (kwadraat p))]
            (stenen/save (+' (kwadraat som) id))))
        (range 1 7)))

(defn- roer-druppel [oude druppel beurt]
  (let [volgorde (komvolgorde druppel)
        steen (stenen/steen beurt)
        schenken (vec (concat
                       (mapv (fn [i]
                               (stenen/save
                                (+' (kwadraat druppel)
                                    (*' (nth steen i)
                                        (kom oude (nth volgorde i)))
                                    (*' (+' 3N (*' 2N i)) beurt))))
                             (range 3))
                       [0N 0N 0N]))
        nieuw (reduce
               (fn [resultaat pos]
                 (let [index (dec pos)
                       id (nth volgorde index)
                       vorig (nth volgorde (mod (- pos 2) 6))
                       volgend (nth volgorde (mod pos 6))
                       som (+' (kom oude id)
                               (*' 2N (kom oude vorig))
                               (*' 3N (kom oude volgend))
                               (nth schenken index)
                               druppel
                               (nth steen (nth roersoorten index)))
                       waarde (stenen/save
                               (+' (kwadraat som)
                                   (*' 5N (kom oude vorig) (kom oude volgend))
                                   (*' beurt pos)))]
                   (assoc resultaat (dec id) waarde)))
               (vec (repeat 6 0N))
               (range 1 7))]
    {:kommen nieuw :volgorde volgorde}))

(defn- meng-46 [tellingen druppels]
  (loop [beurt 1
         kommen (begin-kommen tellingen)
         laatste nil]
    (if (> beurt 46)
      {:kommen kommen :order-at-drop46 laatste}
      (let [resultaat (roer-druppel kommen (nth druppels (dec beurt)) beurt)]
        (recur (inc beurt) (:kommen resultaat) (:volgorde resultaat))))))

(defn- roer-12 [eerste]
  (loop [beurt 1
         kommen eerste]
    (if (> beurt 12)
      kommen
      (let [oude kommen
            som (stenen/save
                 (+' (reduce +' 0N oude) (*' 149N beurt)))
            volgorde (komvolgorde som)
            nieuw (reduce
                   (fn [resultaat pos]
                     (let [index (dec pos)
                           id (nth volgorde index)
                           vorig (nth volgorde (mod (- pos 2) 6))
                           volgend (nth volgorde (mod pos 6))
                           mengsom (+' (kom oude id)
                                      (*' 3N (kom oude vorig))
                                      (*' 5N (kom oude volgend))
                                      som beurt (kwadraat pos))
                           waarde (stenen/save
                                   (+' (kwadraat mengsom)
                                       (*' 7N (kom oude vorig)
                                           (kom oude volgend))))]
                       (assoc resultaat (dec id) waarde)))
                   (vec (repeat 6 0N))
                   (range 1 7))]
        (recur (inc beurt) nieuw)))))

(defn saus [tellingen druppels]
  (controleer tellingen druppels)
  (let [resultaat (meng-46 tellingen druppels)]
    {:bowls (roer-12 (:kommen resultaat))
     :order-at-drop46 (:order-at-drop46 resultaat)}))
