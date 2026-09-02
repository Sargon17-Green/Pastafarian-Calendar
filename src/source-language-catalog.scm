;; Kildesprogskatalogen er normativt indeksfast og må ikke sorteres efter tekst.
;; Kendte stednavne bruger almindelige danske former. De to opdigtede navne
;; transskriberes deterministisk: hebraisk shin gengives som "sh", og de
;; skrevne vokaler bevares i rækkefølge uden at tillægge navnet en betydning.

(define SOURCE-LANGUAGE-CATALOG-VERSION "da-1.0.0")

(define CUTLET-SOURCE-NAMES
  (vector
   "bronze"
   "ræv"
   "nyre"
   "Lagash"
   "tanke"
   "fire niendedele"
   "Palgurash"
   "papyrus"
   "klase"
   "skorpion"
   "aske"
   "hvede"
   "flod"
   "latter"
   "Akkad"
   "horn"
   "den tomme krukke"))

(define MONTH-SOURCE-NAMES
  (vector
   "ler"
   "granatæble"
   "albue"
   "misundelse"
   "Eridu"
   "tandpasta"
   "tre femtedele"
   "Karshumab"
   "leopard"
   "tin"
   "tåge"
   "virak"
   "ten"
   "ribben"
   "johannesbrød"
   "Uruk"
   "skam"
   "kamel"
   "kobber"
   "brønd"
   "æggeblomme"
   "stjerne"
   "honning"
   "milt"
   "kalksten"
   "glæde"
   "figen"
   "Nineve"
   "frø"
   "tjære"
   "lys"
   "den lukkede dør"
   "sesam"
   "nakke"
   "sølv"
   "lilje"
   "storm"
   "æsel"
   "mel"
   "fortrydelse"
   "Babylon"
   "tunge"
   "hør"
   "salt"
   "pære"
   "bue"
   "sand"))

(define (catalog-ref names canonical-index)
  (if (and (integer? canonical-index)
           (>= canonical-index 1)
           (<= canonical-index (vector-length names)))
      (vector-ref names (- canonical-index 1))
      (error "Ugyldigt kanonisk indeks" canonical-index)))

(define (cutlet-name-by-index canonical-index)
  (catalog-ref CUTLET-SOURCE-NAMES canonical-index))

(define (month-name-by-index canonical-index)
  (catalog-ref MONTH-SOURCE-NAMES canonical-index))

(define (catalog-indices names)
  (let loop ((i 1) (out '()))
    (if (> i (vector-length names))
        (reverse out)
        (loop (+ i 1) (cons i out)))))

(define (cutlet-canonical-indices)
  (catalog-indices CUTLET-SOURCE-NAMES))

(define (month-canonical-indices)
  (catalog-indices MONTH-SOURCE-NAMES))
