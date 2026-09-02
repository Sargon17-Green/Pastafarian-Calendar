# Pastafari kalendārs — Common Lisp + latviešu valoda

Šī ir neatkarīga ieviešanas līnija, kas sākta no tukša projekta koka. Pirmajā posmā ir izveidots avotvalodas katalogs, tīrs normatīvais etalons testiem un neitrāls ražošanas skelets, kurā vēl nav neviena no turpmāko posmu vēsturiskajiem defektiem vai ielāpiem.

## Valodas līgums

Izpildāmais kods ir tikai Common Lisp. Cilvēkiem paredzētais kanoniskais teksts ir tikai latviešu valodā. Normatīvā vārdu secība nekad netiek iegūta no latviešu alfabētiskās kārtības; to nosaka tikai nemainīgs `canonicalIndex`.

## Palaišana

Ar SBCL no projekta saknes:

```text
sbcl --script run-tests.lisp
```

Testu etalons atrodas `test/normative-oracle.lisp`; ražošanas kods nedrīkst to ielādēt vai izsaukt.

## Pirmā posma robeža

Šajā posmā ir atļauta tikai vispārīga, semantiski neitrāla infrastruktūra: izsaukuma konteksts, bāzes dispečers, validācijas un kļūdu apvalks, kā arī metriku un žurnāla karkass. Vēsturiskie `legacy` ceļi un ielāpi 01–26 vēl nepastāv.
